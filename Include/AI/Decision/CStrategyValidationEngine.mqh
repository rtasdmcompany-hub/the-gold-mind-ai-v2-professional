//+------------------------------------------------------------------+
//|                                 CStrategyValidationEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CSTRATEGY_VALIDATION_ENGINE_MQH
#define GM_CSTRATEGY_VALIDATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmDecisionSupportResult.mqh"
#include "../Confidence/SGmConfidenceAnalysisResult.mqh"
#include "../Learning/SGmLearningAnalysisResult.mqh"

/// @brief Validates historical consistency with Gold Mind H4 setups (advisory).
class CGmStrategyValidationEngine
  {
public:
   void Validate(const SGmConfidenceAnalysisResult &conf,
                 const SGmLearningAnalysisResult &learn,
                 SGmDecisionSupportResult &r)
     {
      // Composite match score from similarity + conf quality + learning success
      double match = 0.0;
      match += r.historical_similarity * 0.40;
      match += (conf.valid ? conf.overall_confidence : 50.0) * 0.25;
      match += (conf.valid ? conf.execution_readiness : 50.0) * 0.15;
      match += (learn.valid ? learn.historical_success_rate : 50.0) * 0.20;
      match = GmDecClamp(match);

      if(match >= 80.0)
         r.strategy_match = GM_DEC_MATCH_VERY_STRONG;
      else if(match >= 65.0)
         r.strategy_match = GM_DEC_MATCH_STRONG;
      else if(match >= 45.0)
         r.strategy_match = GM_DEC_MATCH_AVERAGE;
      else if(match >= 25.0)
         r.strategy_match = GM_DEC_MATCH_WEAK;
      else
         r.strategy_match = GM_DEC_MATCH_UNKNOWN;

      r.strategy_stats = StringFormat(
                            "match=%.0f | histSim=%.0f | histWR=%.0f | ready=%.0f | GM: 3B/3S H4, ATR TP, 30pip SL, BE, 80%% PC, trail, 2nd attempt",
                            match,
                            r.historical_similarity,
                            r.historical_success_rate,
                            r.execution_readiness);
     }
  };

#endif // GM_CSTRATEGY_VALIDATION_ENGINE_MQH
//+------------------------------------------------------------------+
