//+------------------------------------------------------------------+
//|                                         CAIMomentumEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_MOMENTUM_ENGINE_MQH
#define GM_CAI_MOMENTUM_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMarketIntelligenceResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"

class CGmAIMomentumEngine
  {
public:
   void Analyze(const SGmTrendAnalysisResult &trend,
                const SGmVolatilityAnalysisResult &vol,
                SGmMarketIntelligenceResult &r)
     {
      r.momentum_strength = trend.valid ? trend.momentum_strength : 50.0;
      r.momentum_direction = trend.valid ? trend.directional_bias : 0.0;
      r.momentum_exhaustion = trend.valid ? trend.trend_exhaustion : 30.0;
      r.momentum_acceleration = 50.0;
      if(vol.valid)
         r.momentum_acceleration = GmMiClamp(50.0 + vol.atr_change_rate * 2.0 +
                                             (vol.atr_expansion ? 12.0 : 0.0) -
                                             (vol.atr_compression ? 10.0 : 0.0));
      r.momentum_stability = trend.valid
                             ? GmMiClamp(trend.trend_stability * 0.7 +
                                         (100.0 - r.momentum_exhaustion) * 0.3)
                             : 50.0;
      r.momentum_confidence = GmMiClamp(
                                 0.35 * r.momentum_strength +
                                 0.25 * r.momentum_stability +
                                 0.20 * (100.0 - r.momentum_exhaustion) +
                                 0.20 * (trend.valid ? trend.confidence : 50.0));

      r.momentum_index = GmMiClamp(
                            0.40 * r.momentum_strength +
                            0.20 * (50.0 + r.momentum_direction * 0.5) +
                            0.15 * r.momentum_acceleration +
                            0.15 * r.momentum_stability +
                            0.10 * r.momentum_confidence);

      r.momentum_report = StringFormat(
                             "AI Momentum Engine:\r\nMomentum Index=%.0f/100\r\nStrength=%.0f Dir=%.0f Accel=%.0f Exhaust=%.0f Stab=%.0f Conf=%.0f\r\n%s\r\n",
                             r.momentum_index, r.momentum_strength, r.momentum_direction,
                             r.momentum_acceleration, r.momentum_exhaustion,
                             r.momentum_stability, r.momentum_confidence,
                             GM_MI_ANALYSIS_ONLY);
     }
  };

#endif // GM_CAI_MOMENTUM_ENGINE_MQH
//+------------------------------------------------------------------+
