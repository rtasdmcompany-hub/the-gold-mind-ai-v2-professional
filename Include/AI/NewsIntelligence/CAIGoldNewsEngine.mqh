//+------------------------------------------------------------------+
//|                                        CAIGoldNewsEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_GOLD_NEWS_ENGINE_MQH
#define GM_CAI_GOLD_NEWS_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmNewsIntelligenceResult.mqh"
#include "../News/SGmNewsAnalysisResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../OrderFlow/SGmOrderFlowResult.mqh"

class CGmAIGoldNewsEngine
  {
public:
   void Analyze(const SGmNewsAnalysisResult &news,
                const SGmTrendAnalysisResult &trend,
                const SGmVolatilityAnalysisResult &vol,
                const SGmOrderFlowResult &of,
                const SGmNewsIntelligenceResult &partial,
                SGmNewsIntelligenceResult &r)
     {
      // Proxies: USD strength ↔ bearish gold pressure; risk-off / vol ↔ safe haven
      double usd_proxy = 50.0;
      if(trend.valid)
         usd_proxy = GmNiClamp(50.0 - trend.directional_bias * 0.35);

      double inflation_proxy = 50.0;
      if(partial.event_class == GM_NI_EVT_CPI ||
         partial.event_class == GM_NI_EVT_PPI ||
         partial.event_class == GM_NI_EVT_INFLATION)
         inflation_proxy = GmNiClamp(55.0 + partial.news_impact_score * 0.25);

      double rate_proxy = 50.0;
      if(partial.event_class == GM_NI_EVT_FOMC ||
         partial.event_class == GM_NI_EVT_RATE ||
         partial.event_class == GM_NI_EVT_ECB ||
         partial.event_class == GM_NI_EVT_BOE ||
         partial.event_class == GM_NI_EVT_BOJ)
         rate_proxy = GmNiClamp(50.0 + partial.expected_direction_bias * 0.5);

      double safe_haven = GmNiClamp(
                             40.0 +
                             (vol.valid ? vol.energy_score * 0.25 : 12.0) +
                             (partial.impact_class >= GM_NI_IMPACT_HIGH ? 15.0 : 0.0) +
                             (partial.event_class == GM_NI_EVT_GEOPOLITICAL ? 18.0 : 0.0));

      double risk_sentiment = GmNiClamp(100.0 - safe_haven * 0.6 +
                                        (of.valid ? of.participation_score * 0.15 : 8.0));

      double commodity = of.valid
                         ? GmNiClamp(0.5 * of.directional_strength + 0.5 * of.energy_score)
                         : (trend.valid ? trend.strength_score : 50.0);

      double dxy_trend = usd_proxy; // soft dollar-index proxy from bias

      r.bullish_bias = GmNiClamp(
                          0.30 * safe_haven +
                          0.25 * inflation_proxy +
                          0.20 * (100.0 - usd_proxy) +
                          0.15 * commodity +
                          0.10 * (100.0 - rate_proxy * 0.5));

      r.bearish_bias = GmNiClamp(
                          0.35 * usd_proxy +
                          0.25 * rate_proxy +
                          0.20 * risk_sentiment +
                          0.20 * dxy_trend * 0.5);

      r.neutral_bias = GmNiClamp(100.0 - MathAbs(r.bullish_bias - r.bearish_bias));

      r.gold_sentiment_score = GmNiClamp(
                                  50.0 + (r.bullish_bias - r.bearish_bias) * 0.45);

      if(r.gold_sentiment_score >= 58.0)
         r.gold_bias = GM_NI_GOLD_BULLISH;
      else if(r.gold_sentiment_score <= 42.0)
         r.gold_bias = GM_NI_GOLD_BEARISH;
      else
         r.gold_bias = GM_NI_GOLD_NEUTRAL;

      string gold_note = news.valid ? news.gold_monitor_summary : "Gold monitor soft";
      r.gold_report = StringFormat(
                         "AI Gold News Engine:\r\nSentiment=%.0f | %s\r\nBull=%.0f Bear=%.0f Neutral=%.0f\r\nUSD~%.0f SafeHaven=%.0f Infl~%.0f Rates~%.0f\r\n%s\r\n%s\r\n",
                         r.gold_sentiment_score, GmNiGoldBiasName(r.gold_bias),
                         r.bullish_bias, r.bearish_bias, r.neutral_bias,
                         usd_proxy, safe_haven, inflation_proxy, rate_proxy,
                         gold_note, GM_NI_ANALYSIS_ONLY);
     }
  };

#endif // GM_CAI_GOLD_NEWS_ENGINE_MQH
//+------------------------------------------------------------------+
