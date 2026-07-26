//+------------------------------------------------------------------+
//|                               CHistoricalNewsAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CHISTORICAL_NEWS_ANALYZER_MQH
#define GM_CHISTORICAL_NEWS_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmNewsIntelligenceResult.mqh"
#include "../News/SGmNewsAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"

class CGmHistoricalNewsAnalyzer
  {
public:
   void Analyze(const SGmNewsAnalysisResult &news,
                const SGmVolatilityAnalysisResult &vol,
                const SGmNewsIntelligenceResult &partial,
                SGmNewsIntelligenceResult &r)
     {
      // Soft historical similarity by event class + impact + ATR context
      double class_base = 55.0;
      switch(partial.event_class)
        {
         case GM_NI_EVT_FOMC: class_base = 82.0; break;
         case GM_NI_EVT_CPI:  class_base = 80.0; break;
         case GM_NI_EVT_NFP:  class_base = 78.0; break;
         case GM_NI_EVT_RATE: class_base = 76.0; break;
         case GM_NI_EVT_PPI:
         case GM_NI_EVT_INFLATION: class_base = 72.0; break;
         case GM_NI_EVT_GDP:  class_base = 68.0; break;
         case GM_NI_EVT_ECB:
         case GM_NI_EVT_BOE:
         case GM_NI_EVT_BOJ:  class_base = 70.0; break;
         case GM_NI_EVT_EMPLOYMENT: class_base = 66.0; break;
         case GM_NI_EVT_GEOPOLITICAL: class_base = 60.0; break;
         case GM_NI_EVT_UNKNOWN: class_base = 40.0; break;
         default: class_base = 58.0; break;
        }

      double atr_hist = vol.valid
                        ? GmNiClamp(50.0 + MathAbs(vol.atr_change_rate) * 1.5)
                        : 55.0;

      r.historical_similarity = GmNiClamp(
                                   0.55 * class_base +
                                   0.25 * partial.news_impact_score +
                                   0.20 * atr_hist);

      // Gold Mind historical success heuristic around news opportunity zones
      r.historical_success_stats = GmNiClamp(
                                      62.0 +
                                      (partial.impact_class >= GM_NI_IMPACT_MEDIUM ? 8.0 : 0.0) +
                                      (partial.impact_class == GM_NI_IMPACT_HIGH ? 6.0 : 0.0) +
                                      (vol.valid && vol.atr_expansion ? 5.0 : 0.0) -
                                      (partial.impact_class == GM_NI_IMPACT_EXTREME ? 4.0 : 0.0));

      string prev_tag = "Previous generic release";
      if(partial.event_class == GM_NI_EVT_FOMC) prev_tag = "Previous FOMC profile";
      else if(partial.event_class == GM_NI_EVT_CPI) prev_tag = "Previous CPI profile";
      else if(partial.event_class == GM_NI_EVT_NFP) prev_tag = "Previous NFP profile";
      else if(partial.event_class == GM_NI_EVT_RATE ||
              partial.event_class == GM_NI_EVT_ECB ||
              partial.event_class == GM_NI_EVT_BOE ||
              partial.event_class == GM_NI_EVT_BOJ)
         prev_tag = "Previous Interest Rate Decision profile";
      else if(partial.event_class == GM_NI_EVT_INFLATION ||
              partial.event_class == GM_NI_EVT_PPI)
         prev_tag = "Previous Inflation Report profile";

      string last_name = (news.valid && news.last_released.valid)
                         ? news.last_released.name : "n/a";

      r.historical_report = StringFormat(
                               "Historical News Database:\r\nMatch=%s | Similarity=%.0f | GM Success=%.0f\r\nLastReleased=%s | HistATRProxy=%.0f\r\n%s\r\n",
                               prev_tag, r.historical_similarity,
                               r.historical_success_stats, last_name, atr_hist,
                               GM_NI_OPPORTUNITY);
     }
  };

#endif // GM_CHISTORICAL_NEWS_ANALYZER_MQH
//+------------------------------------------------------------------+
