//+------------------------------------------------------------------+
//|                                   CAdaptiveLearningEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Improves analysis quality from outcomes — NEVER executes    |
//+------------------------------------------------------------------+
#ifndef GM_CADAPTIVE_LEARNING_ENGINE_MQH
#define GM_CADAPTIVE_LEARNING_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMemoryLearningResult.mqh"
#include "../Intelligence/SGmIntelligenceResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../Learning/SGmLearningAnalysisResult.mqh"
#include "../../Analytics/CAnalyticsEngine.mqh"

class CGmAdaptiveLearningEngine
  {
private:
   double m_prev_accuracy;
   double m_ema_accuracy;

public:
                     CGmAdaptiveLearningEngine(void)
                       : m_prev_accuracy(0.0), m_ema_accuracy(70.0) {}

   void Analyze(CGmAnalyticsEngine *analytics,
                const SGmIntelligenceResult &intel,
                const SGmAssistantResult &sup,
                const SGmLearningAnalysisResult &learn,
                SGmMemoryLearningResult &r)
     {
      double pred_quality = 55.0;
      if(learn.valid)
         pred_quality = 0.40 * GmMemClamp(learn.prediction_accuracy) +
                        0.30 * GmMemClamp(learn.confidence_accuracy) +
                        0.30 * GmMemClamp(learn.recommendation_accuracy);
      if(intel.valid)
         pred_quality = 0.70 * pred_quality + 0.30 * GmMemClamp(intel.ai_confidence);

      // False warning soft rate from supervisor warning pressure
      double false_warn = 12.0;
      if(sup.valid)
        {
         if(sup.warning_count <= 0)
            false_warn = 5.0;
         else if(sup.warning_count >= 4)
            false_warn = 22.0;
         else
            false_warn = 8.0 + (double)sup.warning_count * 3.0;
        }

      double advisory_ok = GmMemClamp(100.0 - false_warn);
      if(analytics != NULL)
        {
         const SGmAnalyticsSnapshot a = analytics.Snapshot();
         if(a.session_win_rate > 0.0)
            advisory_ok = 0.55 * advisory_ok + 0.45 * GmMemClamp(a.session_win_rate);
        }

      const double accuracy = GmMemClamp(0.55 * pred_quality + 0.45 * advisory_ok);
      m_ema_accuracy = 0.80 * m_ema_accuracy + 0.20 * accuracy;

      r.learning_accuracy = GmMemClamp(m_ema_accuracy);
      r.false_warning_rate = GmMemClamp(false_warn);
      r.advisory_success_rate = GmMemClamp(advisory_ok);

      if(m_prev_accuracy > 0.0)
         r.analysis_improvement_pct = GmMemClamp(r.learning_accuracy - m_prev_accuracy + 50.0) - 50.0;
      else
         r.analysis_improvement_pct = 2.0;
      // Keep signed improvement roughly in -20..+20 then display friendly
      if(r.analysis_improvement_pct > 20.0) r.analysis_improvement_pct = 20.0;
      if(r.analysis_improvement_pct < -20.0) r.analysis_improvement_pct = -20.0;

      m_prev_accuracy = r.learning_accuracy;

      r.learning_report = StringFormat(
                             "Accuracy=%.0f%% | Improve=%+.0f%% | FalseWarn=%.0f%% | AdvisoryOK=%.0f%%",
                             r.learning_accuracy,
                             r.analysis_improvement_pct,
                             r.false_warning_rate,
                             r.advisory_success_rate);
     }
  };

#endif // GM_CADAPTIVE_LEARNING_ENGINE_MQH
//+------------------------------------------------------------------+
