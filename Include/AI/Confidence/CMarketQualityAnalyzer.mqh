//+------------------------------------------------------------------+
//|                                   CMarketQualityAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CMARKET_QUALITY_ANALYZER_MQH
#define GM_CMARKET_QUALITY_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmConfidenceAnalysisResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../News/SGmNewsAnalysisResult.mqh"

class CGmMarketQualityAnalyzer
  {
public:
   void Analyze(const string symbol,
                const SGmTrendAnalysisResult &trend,
                const SGmVolatilityAnalysisResult &vol,
                const SGmNewsAnalysisResult &news,
                SGmConfidenceAnalysisResult &r)
     {
      r.quality.Reset();

      if(trend.valid)
        {
         r.quality.trend_quality = GmConfClamp(trend.strength_score * 0.55 +
                                               trend.trend_stability * 0.35 +
                                               (100.0 - trend.trend_exhaustion) * 0.10);
         r.quality.momentum_quality = GmConfClamp(MathAbs(trend.momentum_strength));
         r.quality.price_action_quality = GmConfClamp(
            40.0 + (trend.bos_up || trend.bos_down ? 15.0 : 0.0) +
            trend.agreement_score * 0.35);
         r.structure_score = GmConfClamp(30.0 + trend.agreement_score * 0.5 +
                                         (trend.structure != GM_TREND_STRUCT_NONE ? 15.0 : 0.0));
        }

      if(vol.valid)
        {
         r.quality.volatility_quality = GmConfClamp(vol.vol_stability);
         r.quality.range_quality = GmConfClamp(
            vol.range_efficiency * 0.6 +
            (vol.range_compression ? 25.0 : (vol.range_expansion ? 45.0 : 55.0)));
         r.atr14 = vol.atr14;
         r.volatility_score = GmConfClamp(vol.energy_score);
        }

      // Spread / liquidity from live symbol
      const double spread = (double)SymbolInfoInteger(symbol, SYMBOL_SPREAD);
      r.quality.spread_stability = GmConfClamp(100.0 - MathMax(0.0, spread - 15.0) * 1.8);
      r.quality.liquidity_quality = GmConfClamp(
         r.quality.spread_stability * 0.7 +
         (vol.valid && !vol.atr_expansion ? 20.0 : 10.0));
      r.liquidity_score = r.quality.liquidity_quality;

      if(news.valid && news.news_risk_score >= 70.0)
         r.quality.volatility_quality = GmConfClamp(r.quality.volatility_quality * 0.85);

      r.market_quality = GmConfClamp(r.quality.Average());
     }
  };

#endif // GM_CMARKET_QUALITY_ANALYZER_MQH
//+------------------------------------------------------------------+
