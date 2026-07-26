//+------------------------------------------------------------------+
//|                                 CMarketIntelligenceEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     OBSERVE ONLY — builds Market Intelligence Report            |
//+------------------------------------------------------------------+
#ifndef GM_CMARKET_INTELLIGENCE_ENGINE_MQH
#define GM_CMARKET_INTELLIGENCE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmIntelligenceResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../Confidence/SGmConfidenceAnalysisResult.mqh"
#include "../Volatility/VolatilityAIConstants.mqh"

class CGmMarketIntelligenceEngine
  {
private:
   string StrengthLabel(const double v) const
     {
      if(v >= 70.0) return "Strong";
      if(v >= 45.0) return "Medium";
      return "Weak";
     }

   string VolLabel(const double v) const
     {
      if(v >= 75.0) return "High";
      if(v >= 40.0) return "Medium";
      return "Low";
     }

   string LiqLabel(const double v) const
     {
      if(v >= 70.0) return "Healthy";
      if(v >= 45.0) return "Adequate";
      return "Thin";
     }

public:
   void Analyze(const SGmTrendAnalysisResult &trend,
                const SGmVolatilityAnalysisResult &vol,
                const SGmConfidenceAnalysisResult &conf,
                SGmIntelligenceResult &r)
     {
      r.trend_strength = trend.valid ? GmIntelClamp(trend.strength_score) : 50.0;
      r.momentum = trend.valid ? GmIntelClamp(MathAbs(trend.momentum_strength)) : 50.0;
      r.volatility_state = vol.valid ? GmIntelClamp(vol.current_vol > 0.0
                                                    ? vol.vol_confidence
                                                    : vol.energy_score) : 50.0;
      r.atr_condition = vol.valid ? GmIntelClamp(vol.atr_strength) : 50.0;
      r.expansion_score = vol.valid && vol.atr_expansion
                          ? GmIntelClamp(60.0 + vol.energy_score * 0.35)
                          : (vol.valid && vol.range_expansion ? 65.0 : 40.0);
      r.compression_score = vol.valid && (vol.atr_compression || vol.range_compression)
                            ? GmIntelClamp(60.0 + (100.0 - r.volatility_state) * 0.3)
                            : 35.0;
      r.liquidity_condition = conf.valid
                              ? GmIntelClamp(conf.quality.liquidity_quality)
                              : 55.0;
      r.market_confidence = conf.valid
                            ? GmIntelClamp(conf.overall_confidence)
                            : GmIntelClamp(0.5 * r.trend_strength + 0.5 * r.atr_condition);

      r.trend_strength_label = StrengthLabel(r.trend_strength);
      r.volatility_label = VolLabel(r.volatility_state);
      r.liquidity_label = LiqLabel(r.liquidity_condition);

      // Condition classification (reuses Phase 3 Market ENUM_GM_MKT_CONDITION)
      if(vol.valid && (vol.energy == GM_ENERGY_EXTREME || vol.energy == GM_ENERGY_EXPLOSIVE))
         r.market_condition = GM_MKT_COND_HIGH_VOL;
      else if(vol.valid && vol.atr_compression && r.trend_strength < 45.0)
         r.market_condition = GM_MKT_COND_CONSOLIDATION;
      else if(vol.valid && vol.atr_expansion && r.trend_strength >= 55.0)
         r.market_condition = GM_MKT_COND_BREAKOUT;
      else if(r.trend_strength >= 60.0 && trend.valid &&
              trend.conflict_score < 40.0)
         r.market_condition = GM_MKT_COND_TRENDING;
      else if(r.trend_strength < 40.0)
         r.market_condition = GM_MKT_COND_RANGING;
      else
         r.market_condition = GM_MKT_COND_UNCERTAIN;

      if(r.market_confidence >= 75.0 && r.market_condition != GM_MKT_COND_HIGH_VOL)
         r.market_advisory = "Environment suitable for strategy monitoring";
      else if(r.market_condition == GM_MKT_COND_HIGH_VOL)
         r.market_advisory = "Elevated volatility — closer observation recommended";
      else if(r.market_condition == GM_MKT_COND_CONSOLIDATION)
         r.market_advisory = "Compression phase — wait for expansion clarity";
      else
         r.market_advisory = "Mixed conditions — continue advisory monitoring";
     }
  };

#endif // GM_CMARKET_INTELLIGENCE_ENGINE_MQH
//+------------------------------------------------------------------+
