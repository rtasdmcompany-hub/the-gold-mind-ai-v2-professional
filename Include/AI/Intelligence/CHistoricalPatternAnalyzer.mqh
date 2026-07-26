//+------------------------------------------------------------------+
//|                                CHistoricalPatternAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Session similarity — ADVISORY ONLY                          |
//+------------------------------------------------------------------+
#ifndef GM_CHISTORICAL_PATTERN_ANALYZER_MQH
#define GM_CHISTORICAL_PATTERN_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmIntelligenceResult.mqh"
#include "../Learning/SGmLearningAnalysisResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../../Analytics/CAnalyticsEngine.mqh"

class CGmHistoricalPatternAnalyzer
  {
public:
   void Analyze(const SGmLearningAnalysisResult &learn,
                const SGmTrendAnalysisResult &trend,
                const SGmVolatilityAnalysisResult &vol,
                CGmAnalyticsEngine *analytics,
                SGmIntelligenceResult &r)
     {
      // Base similarity from Learning Engine historical correlation / pattern accuracy
      double sim = 50.0;
      if(learn.valid)
        {
         sim = 0.55 * GmIntelClamp(learn.historical_correlation) +
               0.25 * GmIntelClamp(learn.pattern_accuracy) +
               0.20 * GmIntelClamp(learn.historical_success_rate);
        }

      // Soft blend with current regime fingerprints
      if(trend.valid)
         sim = 0.85 * sim + 0.15 * GmIntelClamp(trend.trend_stability);
      if(vol.valid)
         sim = 0.90 * sim + 0.10 * GmIntelClamp(vol.vol_stability);

      r.historical_similarity = GmIntelClamp(sim);

      // Synthetic nearest-date label from session / learning context
      if(learn.valid && learn.h4_sessions_studied > 0)
        {
         // Approximate "pattern date" from session study count (observational tag)
         const datetime ref = TimeCurrent() - (datetime)(learn.h4_sessions_studied * 4 * 3600);
         r.similar_pattern_date = TimeToString(ref, TIME_DATE);
        }
      else if(analytics != NULL)
        {
         const SGmAnalyticsSnapshot a = analytics.Snapshot();
         if(a.completed_sessions > 0)
            r.similar_pattern_date = TimeToString(TimeCurrent() - (datetime)(a.completed_sessions * 14400), TIME_DATE);
         else
            r.similar_pattern_date = "Insufficient history";
        }
      else
         r.similar_pattern_date = "Insufficient history";

      // Outcome classification (informational)
      if(learn.valid && learn.historical_success_rate >= 65.0)
         r.historical_outcome = "Successful Recovery Bias";
      else if(analytics != NULL)
        {
         const SGmAnalyticsSnapshot a = analytics.Snapshot();
         if(a.session_win_rate >= 60.0)
            r.historical_outcome = "Historically Favorable Sessions";
         else if(a.session_win_rate > 0.0 && a.session_win_rate < 40.0)
            r.historical_outcome = "Historically Challenging Sessions";
         else
            r.historical_outcome = "Neutral / Mixed History";
        }
      else
         r.historical_outcome = "Neutral / Mixed History";

      r.pattern_insight = StringFormat("Similarity %.0f%% vs %s | Outcome: %s",
                                       r.historical_similarity,
                                       r.similar_pattern_date,
                                       r.historical_outcome);
     }
  };

#endif // GM_CHISTORICAL_PATTERN_ANALYZER_MQH
//+------------------------------------------------------------------+
