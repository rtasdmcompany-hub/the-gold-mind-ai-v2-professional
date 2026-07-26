//+------------------------------------------------------------------+
//|                                       CMarketEnergyEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CMARKET_ENERGY_ENGINE_MQH
#define GM_CMARKET_ENERGY_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmVolatilityAnalysisResult.mqh"

/// @brief Market energy model from ATR / relative volatility (ANALYSIS ONLY).
class CGmMarketEnergyEngine
  {
public:
   void Analyze(SGmVolatilityAnalysisResult &r)
     {
      double score = 0.0;
      score += r.atr_strength * 0.35;
      score += r.relative_vol * 0.35;
      score += MathMin(100.0, MathAbs(r.atr_change_rate) * 2.5) * 0.15;
      score += r.atr_momentum * 0.15;
      if(r.atr_expansion)
         score += 8.0;
      if(r.atr_acceleration > 5.0)
         score += 6.0;
      r.energy_score = GmClamp01(score);

      if(r.energy_score < 20.0)
         r.energy = GM_ENERGY_LOW;
      else if(r.energy_score < 35.0)
         r.energy = GM_ENERGY_BUILDING;
      else if(r.energy_score < 55.0)
         r.energy = GM_ENERGY_NORMAL;
      else if(r.energy_score < 72.0)
         r.energy = GM_ENERGY_STRONG;
      else if(r.energy_score < 88.0)
         r.energy = GM_ENERGY_EXTREME;
      else
         r.energy = GM_ENERGY_EXPLOSIVE;
     }
  };

#endif // GM_CMARKET_ENERGY_ENGINE_MQH
//+------------------------------------------------------------------+
