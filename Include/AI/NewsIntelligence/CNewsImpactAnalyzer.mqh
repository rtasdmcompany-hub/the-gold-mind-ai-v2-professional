//+------------------------------------------------------------------+
//|                                      CNewsImpactAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CNEWS_IMPACT_ANALYZER_MQH
#define GM_CNEWS_IMPACT_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmNewsIntelligenceResult.mqh"
#include "../News/SGmNewsAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"

class CGmNewsImpactAnalyzer
  {
public:
   void Analyze(const SGmNewsAnalysisResult &news,
                const SGmVolatilityAnalysisResult &vol,
                const SGmNewsIntelligenceResult &partial,
                SGmNewsIntelligenceResult &r)
     {
      const double base = partial.news_impact_score;

      r.expected_price_expansion = GmNiClamp(
                                      30.0 + base * 0.50 +
                                      (vol.valid && vol.atr_expansion ? 10.0 : 0.0));
      r.expected_atr_expansion = GmNiClamp(
                                    28.0 + base * 0.48 +
                                    (vol.valid ? MathMax(0.0, vol.atr_change_rate) * 1.2 : 0.0));
      r.expected_spread_expansion = GmNiClamp(
                                       25.0 + base * 0.40 +
                                       (news.valid && news.reaction.spread_expansion ? 15.0 : 0.0));
      r.expected_liquidity = GmNiClamp(
                                70.0 - base * 0.25 +
                                (news.valid && news.reaction.liquidity_expansion ? 12.0 : 0.0));

      if(partial.impact_class == GM_NI_IMPACT_EXTREME)
         r.historical_behavior = "Historically extreme releases drive wide H4 ranges and ATR spikes — opportunity zone for Gold Mind.";
      else if(partial.impact_class == GM_NI_IMPACT_HIGH)
         r.historical_behavior = "High-impact releases often expand ATR and spreads; Gold Mind H4 levels remain active.";
      else if(partial.impact_class == GM_NI_IMPACT_MEDIUM)
         r.historical_behavior = "Medium impact: moderate expansion expected; typical session continuation bias.";
      else if(partial.impact_class == GM_NI_IMPACT_LOW)
         r.historical_behavior = "Low impact: limited expansion; baseline liquidity and ATR behavior.";
      else
         r.historical_behavior = "No scheduled high-priority event: baseline Gold Mind environment.";

      r.impact_report = StringFormat(
                           "News Impact Analyzer:\r\nClass=%s | ImpactScore=%.0f\r\nPriceExp=%.0f ATRExp=%.0f SpreadExp=%.0f Liq=%.0f\r\nHistory:\r\n%s\r\n%s\r\n",
                           GmNiImpactName(partial.impact_class), base,
                           r.expected_price_expansion, r.expected_atr_expansion,
                           r.expected_spread_expansion, r.expected_liquidity,
                           r.historical_behavior, GM_NI_ADVISORY);
     }
  };

#endif // GM_CNEWS_IMPACT_ANALYZER_MQH
//+------------------------------------------------------------------+
