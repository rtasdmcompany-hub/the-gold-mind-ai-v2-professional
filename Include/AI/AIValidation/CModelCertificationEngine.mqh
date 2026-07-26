//+------------------------------------------------------------------+
//|                                CModelCertificationEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CMODEL_CERTIFICATION_ENGINE_MQH
#define GM_CMODEL_CERTIFICATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmAIValidationResult.mqh"

class CGmModelCertificationEngine
  {
public:
   void Certify(SGmAIValidationResult &r)
     {
      r.ai_accuracy = GmAiValClamp(
         r.prediction_accuracy * 0.20 +
         r.confidence_accuracy * 0.15 +
         r.recommendation_accuracy * 0.15 +
         r.pattern_accuracy * 0.10 +
         r.trend_accuracy * 0.10 +
         r.volatility_accuracy * 0.10 +
         r.news_accuracy * 0.10 +
         r.historical_correlation * 0.10);

      r.certification_score = GmAiValClamp(
         r.ai_accuracy * 0.45 +
         r.forward_test_score * 0.25 +
         r.backtest_score * 0.20 +
         r.model_stability * 0.10);

      r.learning_stability = GmAiValClamp(r.model_stability);
      r.ai_health_score = GmAiValClamp(
         r.certification_score * 0.6 +
         r.learning_stability * 0.2 +
         (r.drift_alert ? 30.0 : 80.0) * 0.2);

      if(r.certification_score >= 85.0)
         r.reliability_grade = GM_AIVAL_GRADE_A;
      else if(r.certification_score >= 70.0)
         r.reliability_grade = GM_AIVAL_GRADE_B;
      else if(r.certification_score >= 55.0)
         r.reliability_grade = GM_AIVAL_GRADE_C;
      else if(r.certification_score >= 40.0)
         r.reliability_grade = GM_AIVAL_GRADE_D;
      else
         r.reliability_grade = GM_AIVAL_GRADE_F;

      r.cert_summary = StringFormat("Cert=%.0f Grade=%s | Acc=%.0f Fwd=%.0f Bkt=%.0f | %s",
                                    r.certification_score,
                                    GmAiValGradeName(r.reliability_grade),
                                    r.ai_accuracy,
                                    r.forward_test_score,
                                    r.backtest_score,
                                    GM_AIVAL_ANALYSIS_ONLY);
      r.confidence = r.certification_score;
     }
  };

#endif // GM_CMODEL_CERTIFICATION_ENGINE_MQH
//+------------------------------------------------------------------+
