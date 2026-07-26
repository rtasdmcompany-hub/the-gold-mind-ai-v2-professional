//+------------------------------------------------------------------+
//|                                       CMarketEnergyEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CMARKET_ENERGY_ENGINE_OF_MQH
#define GM_CMARKET_ENERGY_ENGINE_OF_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmOrderFlowResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../MarketIntelligence/SGmMarketIntelligenceResult.mqh"
#include "../Trend/TrendAIConstants.mqh"

class CGmMarketEnergyEngineOF
  {
public:
   void Analyze(const SGmTrendAnalysisResult &trend,
                const SGmVolatilityAnalysisResult &vol,
                const SGmMarketIntelligenceResult &mi,
                SGmOrderFlowResult &r)
     {
      r.expansion_energy = vol.valid
                           ? (vol.atr_expansion ? GmOfClamp(60.0 + vol.atr_strength * 0.35) : 35.0)
                           : 45.0;
      r.compression_energy = vol.valid
                             ? (vol.atr_compression ? GmOfClamp(55.0 + (100.0 - vol.energy_score) * 0.3) : 30.0)
                             : 40.0;
      r.momentum_energy = mi.valid ? mi.momentum_index
                          : (trend.valid ? trend.momentum_strength : 50.0);
      r.trend_energy = trend.valid ? trend.strength_score : 50.0;

      const double bias = trend.valid ? trend.directional_bias : 0.0;
      r.buying_energy = GmOfClamp(50.0 + bias * 0.45 + (vol.valid && vol.atr_expansion ? 8.0 : 0.0));
      r.selling_energy = GmOfClamp(50.0 - bias * 0.45 + (trend.valid && trend.primary == GM_TREND_DIR_BEAR ? 10.0 : 0.0));

      r.energy_score = GmOfClamp(
                          0.25 * (vol.valid ? vol.energy_score : 55.0) +
                          0.20 * r.momentum_energy +
                          0.20 * r.trend_energy +
                          0.15 * r.expansion_energy +
                          0.10 * r.buying_energy +
                          0.10 * (100.0 - r.compression_energy * 0.3));

      if(r.buying_energy > r.selling_energy + 8.0)
         r.energy_direction = "Buying";
      else if(r.selling_energy > r.buying_energy + 8.0)
         r.energy_direction = "Selling";
      else
         r.energy_direction = "Balanced";

      r.energy_stability = GmOfClamp(
                              0.5 * (vol.valid ? vol.vol_stability : 55.0) +
                              0.5 * (trend.valid ? trend.trend_stability : 55.0));

      r.energy_report = StringFormat(
                           "Market Energy Engine:\r\nEnergyScore=%.0f | Dir=%s | Stab=%.0f\r\nBuy=%.0f Sell=%.0f Exp=%.0f Comp=%.0f Mom=%.0f Trend=%.0f\r\n%s\r\n",
                           r.energy_score, r.energy_direction, r.energy_stability,
                           r.buying_energy, r.selling_energy, r.expansion_energy,
                           r.compression_energy, r.momentum_energy, r.trend_energy,
                           GM_OF_ANALYSIS_ONLY);
     }
  };

#endif // GM_CMARKET_ENERGY_ENGINE_OF_MQH
//+------------------------------------------------------------------+
