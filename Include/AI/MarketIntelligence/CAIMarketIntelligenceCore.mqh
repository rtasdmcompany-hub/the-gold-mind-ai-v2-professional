//+------------------------------------------------------------------+
//|                               CAIMarketIntelligenceCore.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Core market intelligence aggregator (Task 1)                |
//+------------------------------------------------------------------+
#ifndef GM_CAI_MARKET_INTELLIGENCE_CORE_MQH
#define GM_CAI_MARKET_INTELLIGENCE_CORE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMarketIntelligenceResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../News/SGmNewsAnalysisResult.mqh"

class CGmAIMarketIntelligenceCore
  {
public:
   void Analyze(const SGmVolatilityAnalysisResult &vol,
                const SGmNewsAnalysisResult &news,
                SGmMarketIntelligenceResult &r)
     {
      r.volatility_score = vol.valid ? GmMiClamp(vol.relative_vol > 0.0 ? vol.relative_vol : vol.energy_score) : 50.0;
      if(vol.valid)
         r.volatility_score = GmMiClamp(0.5 * vol.energy_score + 0.5 * vol.atr_strength);

      r.atr_expansion_score = 40.0;
      if(vol.valid)
        {
         if(vol.atr_expansion)
            r.atr_expansion_score = GmMiClamp(60.0 + vol.atr_strength * 0.35);
         else if(vol.atr_compression)
            r.atr_expansion_score = GmMiClamp(25.0 + (100.0 - vol.atr_strength) * 0.15);
         else
            r.atr_expansion_score = 50.0;
        }

      r.compression_score = vol.valid
                            ? (vol.atr_compression ? GmMiClamp(55.0 + (100.0 - vol.energy_score) * 0.3)
                                                   : GmMiClamp(30.0 + vol.vol_stability * 0.2))
                            : 40.0;

      r.market_energy = vol.valid ? vol.energy_score : 55.0;
      if(news.valid)
         r.market_energy = GmMiClamp(0.85 * r.market_energy + 0.15 * news.confidence);

      r.breakout_probability = vol.valid
                               ? GmMiClamp(0.55 * vol.prob_breakout + 0.25 * r.atr_expansion_score +
                                           0.20 * r.momentum_index)
                               : GmMiClamp(35.0 + r.atr_expansion_score * 0.25);

      r.reversal_probability = GmMiClamp(
                                  0.35 * r.momentum_exhaustion +
                                  0.25 * r.false_breakout_probability +
                                  0.20 * (r.trend_weakness ? 70.0 : 25.0) +
                                  0.20 * (r.change_of_character ? 75.0 : 20.0));

      r.market_intelligence_report = StringFormat(
                                        "AI Market Intelligence Engine:\r\nStructure=%.0f TrendStr=%.0f Mom=%.0f Liq=%.0f\r\nVol=%.0f ATRExp=%.0f Comp=%.0f Energy=%.0f\r\nBreakout=%.0f%% Reversal=%.0f%%\r\n%s\r\n",
                                        r.market_structure_score, r.trend_strength, r.momentum_index,
                                        r.liquidity_score, r.volatility_score, r.atr_expansion_score,
                                        r.compression_score, r.market_energy,
                                        r.breakout_probability, r.reversal_probability,
                                        GM_MI_ANALYSIS_ONLY);
     }
  };

#endif // GM_CAI_MARKET_INTELLIGENCE_CORE_MQH
//+------------------------------------------------------------------+
