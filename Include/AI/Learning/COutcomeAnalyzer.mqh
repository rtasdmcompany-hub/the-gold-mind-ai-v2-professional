//+------------------------------------------------------------------+
//|                                         COutcomeAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_COUTCOME_ANALYZER_MQH
#define GM_COUTCOME_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmLearningAnalysisResult.mqh"
#include "../Confidence/SGmConfidenceAnalysisResult.mqh"

/// @brief Compares AI predictions vs actual trade outcomes (analytical).
class CGmOutcomeAnalyzer
  {
public:
   void Analyze(const int wins, const int losses,
                const double analytics_win_rate,
                const SGmConfidenceAnalysisResult &conf,
                const int patterns_hit,
                const int patterns_total,
                SGmLearningAnalysisResult &r)
     {
      const int total = wins + losses;
      r.trades_studied = total;
      r.wins_studied = wins;
      r.losses_studied = losses;

      if(total > 0)
         r.historical_success_rate = 100.0 * (double)wins / (double)total;
      else if(analytics_win_rate > 0.0)
         r.historical_success_rate = GmLearnClamp(analytics_win_rate);
      else
         r.historical_success_rate = 50.0;

      // Confidence accuracy: high conf should correlate with wins (soft proxy)
      if(conf.valid && total > 0)
        {
         const double expected = conf.overall_confidence;
         const double actual = r.historical_success_rate;
         r.confidence_accuracy = GmLearnClamp(100.0 - MathAbs(expected - actual));
         r.prediction_accuracy = r.confidence_accuracy;
         // Recommendation success: good/excellent env vs win rate
         if(conf.environment == GM_CONF_ENV_EXCELLENT ||
            conf.environment == GM_CONF_ENV_VERY_GOOD ||
            conf.environment == GM_CONF_ENV_GOOD)
            r.recommendation_accuracy = GmLearnClamp(r.historical_success_rate);
         else if(conf.environment == GM_CONF_ENV_HIGH_RISK ||
                 conf.environment == GM_CONF_ENV_EXTREME_RISK)
            r.recommendation_accuracy = GmLearnClamp(100.0 - r.historical_success_rate + 40.0);
         else
            r.recommendation_accuracy = GmLearnClamp(50.0 + (r.historical_success_rate - 50.0) * 0.5);
        }
      else
        {
         r.confidence_accuracy = 50.0;
         r.prediction_accuracy = 50.0;
         r.recommendation_accuracy = 50.0;
        }

      if(patterns_total > 0)
         r.pattern_accuracy = GmLearnClamp(100.0 * (double)patterns_hit / (double)patterns_total);
      else
         r.pattern_accuracy = 55.0;

      // Soft correlation between confidence and outcomes
      r.historical_correlation = GmLearnClamp(
         50.0 + (r.confidence_accuracy - 50.0) * 0.6 +
         (r.historical_success_rate - 50.0) * 0.2);
     }
  };

#endif // GM_COUTCOME_ANALYZER_MQH
//+------------------------------------------------------------------+
