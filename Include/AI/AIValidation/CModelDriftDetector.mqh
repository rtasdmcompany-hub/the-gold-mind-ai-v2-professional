//+------------------------------------------------------------------+
//|                                    CModelDriftDetector.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CMODEL_DRIFT_DETECTOR_MQH
#define GM_CMODEL_DRIFT_DETECTOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmAIValidationResult.mqh"

class CGmModelDriftDetector
  {
private:
   double m_ring[GM_AIVAL_ACC_RING];
   int    m_n;
   int    m_idx;
   double m_baseline;
   double m_prev_conf_acc;
   double m_prev_reco_acc;
   double m_prev_pred_acc;

public:
                     CGmModelDriftDetector(void)
                       : m_n(0), m_idx(0), m_baseline(-1.0),
                         m_prev_conf_acc(-1.0), m_prev_reco_acc(-1.0),
                         m_prev_pred_acc(-1.0)
     {
      for(int i = 0; i < GM_AIVAL_ACC_RING; i++)
         m_ring[i] = 0.0;
     }

   void Detect(SGmAIValidationResult &r)
     {
      // Push accuracy sample
      m_ring[m_idx] = r.ai_accuracy;
      m_idx = (m_idx + 1) % GM_AIVAL_ACC_RING;
      if(m_n < GM_AIVAL_ACC_RING)
         m_n++;

      double sum = 0.0;
      for(int i = 0; i < m_n; i++)
         sum += m_ring[i];
      const double avg = (m_n > 0) ? sum / (double)m_n : r.ai_accuracy;

      if(m_baseline < 0.0 && m_n >= 5)
         m_baseline = avg;

      r.model_stability = GmAiValClamp(100.0 - MathAbs(r.ai_accuracy - avg) * 2.0);
      r.drift_type = GM_AIVAL_DRIFT_NONE;
      r.drift_alert = false;
      r.drift_magnitude = 0.0;
      r.drift_message = "Stable";

      if(m_baseline >= 0.0)
        {
         const double deg = m_baseline - r.ai_accuracy;
         if(deg >= GM_AIVAL_DRIFT_THRESH)
           {
            r.drift_type = GM_AIVAL_DRIFT_DEGRADATION;
            r.drift_magnitude = deg;
            r.drift_alert = true;
            r.drift_message = StringFormat("Performance Degradation | Δ=%.1f", deg);
           }
        }

      if(m_prev_conf_acc >= 0.0 &&
         MathAbs(r.confidence_accuracy - m_prev_conf_acc) >= GM_AIVAL_DRIFT_THRESH)
        {
         r.drift_type = GM_AIVAL_DRIFT_CONFIDENCE;
         r.drift_magnitude = MathAbs(r.confidence_accuracy - m_prev_conf_acc);
         r.drift_alert = true;
         r.drift_message = "Confidence Drift detected";
        }
      if(m_prev_pred_acc >= 0.0 &&
         MathAbs(r.prediction_accuracy - m_prev_pred_acc) >= GM_AIVAL_DRIFT_THRESH)
        {
         r.drift_type = GM_AIVAL_DRIFT_PREDICTION;
         r.drift_magnitude = MathAbs(r.prediction_accuracy - m_prev_pred_acc);
         r.drift_alert = true;
         r.drift_message = "Prediction Drift detected";
        }
      if(m_prev_reco_acc >= 0.0 &&
         MathAbs(r.recommendation_accuracy - m_prev_reco_acc) >= GM_AIVAL_DRIFT_THRESH)
        {
         r.drift_type = GM_AIVAL_DRIFT_RECOMMENDATION;
         r.drift_magnitude = MathAbs(r.recommendation_accuracy - m_prev_reco_acc);
         r.drift_alert = true;
         r.drift_message = "Recommendation Drift detected";
        }

      // Regime soft: large simultaneous vol+trend accuracy swing
      if(m_prev_pred_acc >= 0.0 &&
         MathAbs(r.trend_accuracy - r.volatility_accuracy) >= 35.0 &&
         MathAbs(r.ai_accuracy - avg) >= 10.0)
        {
         r.drift_type = GM_AIVAL_DRIFT_REGIME;
         r.drift_alert = true;
         r.drift_message = "Market Regime Change suspected";
         r.drift_magnitude = MathAbs(r.trend_accuracy - r.volatility_accuracy);
        }

      m_prev_conf_acc = r.confidence_accuracy;
      m_prev_pred_acc = r.prediction_accuracy;
      m_prev_reco_acc = r.recommendation_accuracy;

      if(r.drift_alert)
         r.status = GM_AIVAL_STATUS_DRIFT;
     }
  };

#endif // GM_CMODEL_DRIFT_DETECTOR_MQH
//+------------------------------------------------------------------+
