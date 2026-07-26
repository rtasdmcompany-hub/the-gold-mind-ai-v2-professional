//+------------------------------------------------------------------+
//|                             CTrendSynchronizationEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CTREND_SYNCHRONIZATION_ENGINE_MQH
#define GM_CTREND_SYNCHRONIZATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMultiTimeframeResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../MarketIntelligence/SGmMarketIntelligenceResult.mqh"

class CGmTrendSynchronizationEngine
  {
private:
   double AlignDirs(const ENUM_GM_TREND_DIR a, const ENUM_GM_TREND_DIR b) const
     {
      if(a == GM_TREND_DIR_UNKNOWN || b == GM_TREND_DIR_UNKNOWN) return 50.0;
      if(a == GM_TREND_DIR_FLAT || b == GM_TREND_DIR_FLAT) return 55.0;
      return (a == b) ? 90.0 : 25.0;
     }

public:
   void Analyze(const SGmTrendAnalysisResult &trend,
                const SGmVolatilityAnalysisResult &vol,
                const SGmMarketIntelligenceResult &mi,
                const SGmMultiTimeframeResult &partial,
                SGmMultiTimeframeResult &r)
     {
      r.trend_agreement = GmMtfClamp(
                             0.40 * partial.timeframe_agreement +
                             0.30 * AlignDirs(partial.h4.direction, partial.d1.direction) +
                             0.30 * AlignDirs(partial.d1.direction, partial.w1.direction));
      r.trend_conflict = GmMtfClamp(
                            0.50 * partial.timeframe_conflict +
                            0.50 * (100.0 - AlignDirs(partial.h4.direction, partial.d1.direction)));

      // Momentum: H4 vs H1 vs D1
      const double mom_h4 = MathAbs(partial.h4.momentum);
      const double mom_h1 = MathAbs(partial.h1.momentum);
      const double mom_d1 = MathAbs(partial.d1.momentum);
      const double mom_spread = MathAbs(mom_h4 - mom_h1) + MathAbs(mom_h4 - mom_d1);
      r.momentum_alignment = GmMtfClamp(100.0 - mom_spread * 0.6);

      r.atr_alignment = vol.valid
                        ? GmMtfClamp(55.0 + (vol.atr_expansion ? 15.0 : 0.0) -
                                     (vol.atr_compression ? 10.0 : 0.0) +
                                     vol.atr_strength * 0.15)
                        : 55.0;
      r.volatility_alignment = vol.valid
                               ? GmMtfClamp(0.5 * vol.vol_stability + 0.5 * (100.0 - MathAbs(vol.atr_change_rate)))
                               : 55.0;
      r.structure_alignment = mi.valid
                              ? GmMtfClamp(mi.structure_quality)
                              : (trend.valid ? GmMtfClamp(trend.trend_stability) : 50.0);

      r.synchronization_score = GmMtfClamp(
                                   0.25 * r.trend_agreement +
                                   0.20 * r.momentum_alignment +
                                   0.15 * r.atr_alignment +
                                   0.15 * r.volatility_alignment +
                                   0.15 * r.structure_alignment +
                                   0.10 * (100.0 - r.trend_conflict * 0.5));

      r.alignment_confidence = GmMtfClamp(
                                  0.45 * r.synchronization_score +
                                  0.30 * (trend.valid ? trend.confidence : 50.0) +
                                  0.25 * partial.timeframe_agreement);

      r.trend_stability = trend.valid
                          ? GmMtfClamp(trend.trend_stability)
                          : GmMtfClamp(r.trend_agreement * 0.7);

      r.sync_report = StringFormat(
                         "Trend Synchronization:\r\nSync=%.0f AlignConf=%.0f Stab=%.0f\r\nTrendAgr=%.0f TrendConf=%.0f Mom=%.0f\r\nATR=%.0f Vol=%.0f Struct=%.0f\r\n%s\r\n",
                         r.synchronization_score, r.alignment_confidence, r.trend_stability,
                         r.trend_agreement, r.trend_conflict, r.momentum_alignment,
                         r.atr_alignment, r.volatility_alignment, r.structure_alignment,
                         GM_MTF_ANALYSIS_ONLY);
     }
  };

#endif // GM_CTREND_SYNCHRONIZATION_ENGINE_MQH
//+------------------------------------------------------------------+
