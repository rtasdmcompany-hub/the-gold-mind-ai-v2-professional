//+------------------------------------------------------------------+
//|                                CLearningValidationEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CLEARNING_VALIDATION_ENGINE_MQH
#define GM_CLEARNING_VALIDATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmSelfLearningResult.mqh"
#include "../Learning/SGmLearningAnalysisResult.mqh"
#include "../Memory/SGmMemoryLearningResult.mqh"
#include "../PredictiveIntelligence/SGmPredictiveIntelligenceResult.mqh"
#include "../AIValidation/SGmAIValidationResult.mqh"
#include "../../Analytics/SGmAnalyticsSnapshot.mqh"

class CGmLearningValidationEngine
  {
public:
   void Analyze(const SGmAnalyticsSnapshot &a,
                const SGmLearningAnalysisResult &learn,
                const SGmMemoryLearningResult &mem,
                const SGmPredictiveIntelligenceResult &pred,
                const SGmAIValidationResult &aival,
                SGmSelfLearningResult &r)
     {
      r.learning_accuracy = GmSlClamp(
         (learn.valid) ? learn.pattern_accuracy
                       : (0.5 * a.overall_win_rate + 0.5 * a.session_win_rate));

      r.pattern_recognition_score = GmSlClamp(
         40.0 + r.patterns_discovered * 7.0 +
         ((learn.valid) ? MathMin(20.0, learn.patterns_detected * 2.5) : 0.0));

      r.historical_matching = (pred.valid) ? GmSlClamp(pred.historical_match)
                              : GmSlClamp(r.learning_accuracy);

      r.prediction_quality = (pred.valid)
         ? GmSlClamp(0.5 * pred.forecast_reliability + 0.5 * pred.prediction_confidence)
         : GmSlClamp(0.5 * r.learning_confidence + 0.5 * r.historical_matching);

      r.knowledge_stability = GmSlClamp(
         0.5 * r.learning_stability +
         0.3 * r.knowledge_quality +
         0.2 * ((mem.valid) ? mem.calibrated_confidence : 55.0));

      r.recommendation_quality = GmSlClamp(
         0.4 * r.learning_confidence +
         0.3 * r.knowledge_index +
         0.3 * (50.0 + r.recommendation_count * 8.0));

      r.knowledge_reliability = GmSlClamp(
         0.25 * r.learning_accuracy +
         0.20 * r.pattern_recognition_score +
         0.20 * r.historical_matching +
         0.15 * r.prediction_quality +
         0.10 * r.knowledge_stability +
         0.10 * r.recommendation_quality);

      if(aival.valid)
         r.knowledge_reliability = GmSlClamp(
            0.7 * r.knowledge_reliability + 0.3 * aival.certification_score);

      // Certification ladder — advisory label only
      if(r.knowledge_reliability >= 80.0 && r.learning_stability >= 70.0)
         r.learning_certification = GM_SL_CERT_CERTIFIED;
      else if(r.knowledge_reliability >= 65.0)
         r.learning_certification = GM_SL_CERT_VALIDATED;
      else if(r.knowledge_reliability >= 45.0)
         r.learning_certification = GM_SL_CERT_PROVISIONAL;
      else if(r.knowledge_reliability > 0.0)
         r.learning_certification = GM_SL_CERT_DEGRADED;
      else
         r.learning_certification = GM_SL_CERT_UNKNOWN;

      r.validation_report = StringFormat(
         "Cert=%s Reliability=%.0f | Acc=%.0f PatRec=%.0f Hist=%.0f PredQ=%.0f Stab=%.0f RecQ=%.0f",
         GmSlCertName(r.learning_certification), r.knowledge_reliability,
         r.learning_accuracy, r.pattern_recognition_score, r.historical_matching,
         r.prediction_quality, r.knowledge_stability, r.recommendation_quality);
     }
  };

#endif // GM_CLEARNING_VALIDATION_ENGINE_MQH
//+------------------------------------------------------------------+
