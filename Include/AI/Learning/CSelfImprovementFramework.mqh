//+------------------------------------------------------------------+
//|                               CSelfImprovementFramework.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CSELF_IMPROVEMENT_FRAMEWORK_MQH
#define GM_CSELF_IMPROVEMENT_FRAMEWORK_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmLearningAnalysisResult.mqh"

/// @brief Analytical self-improvement — NEVER touches trading rules/risk/orders.
class CGmSelfImprovementFramework
  {
public:
   void Improve(SGmLearningAnalysisResult &r)
     {
      r.may_modify_strategy = false;
      r.calibration.cycles++;

      // Calibrate advisory confidence bias toward observed success
      const double gap = r.historical_success_rate - 50.0;
      r.calibration.confidence_bias = GmLearnClamp(50.0 + gap * 0.15) - 50.0;

      // Environment caution when losses dominate
      if(r.losses_studied > r.wins_studied)
         r.calibration.env_caution_bias = MathMin(15.0, (r.losses_studied - r.wins_studied) * 2.0);
      else
         r.calibration.env_caution_bias = MathMax(-5.0, r.calibration.env_caution_bias * 0.8);

      // Recommendation quality bias from recommendation accuracy
      r.calibration.reco_quality_bias =
         GmLearnClamp(r.recommendation_accuracy) - 50.0;

      // Learning progress compounds with cycles + knowledge + accuracy
      r.learning_progress = GmLearnClamp(
         20.0 + r.learning_cycles * 2.0 +
         r.knowledge_entries * 0.35 +
         r.patterns_detected * 1.5 +
         r.prediction_accuracy * 0.15);
      r.learning_progress_pct = r.learning_progress;
     }
  };

#endif // GM_CSELF_IMPROVEMENT_FRAMEWORK_MQH
//+------------------------------------------------------------------+
