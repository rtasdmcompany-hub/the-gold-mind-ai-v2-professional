//+------------------------------------------------------------------+
//|                                         CAILiquidityEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_LIQUIDITY_ENGINE_MQH
#define GM_CAI_LIQUIDITY_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMarketIntelligenceResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"

class CGmAILiquidityEngine
  {
public:
   void Analyze(const SGmTrendAnalysisResult &trend,
                const SGmVolatilityAnalysisResult &vol,
                const SGmAssistantResult &sup,
                SGmMarketIntelligenceResult &r)
     {
      r.liquidity_sweep = (trend.valid && (trend.liq_sweep_high || trend.liq_sweep_low));
      const double spread_pts = (sup.valid ? MathMax(sup.spread_points, 0.0) : 20.0);

      r.spread_stability = GmMiClamp(100.0 - MathMin(60.0, spread_pts * 1.5));
      r.session_liquidity = (sup.valid ? GmMiClamp(sup.liquidity_score) : 60.0);
      if(vol.valid)
         r.session_liquidity = GmMiClamp(0.5 * r.session_liquidity + 0.5 * vol.vol_stability);

      r.high_liquidity_score = GmMiClamp(0.55 * r.session_liquidity + 0.45 * r.spread_stability);
      r.low_liquidity_score = GmMiClamp(100.0 - r.high_liquidity_score);
      r.liquidity_void_score = (vol.valid && vol.atr_compression)
                               ? GmMiClamp(40.0 + (100.0 - vol.energy_score) * 0.35)
                               : GmMiClamp(20.0 + r.low_liquidity_score * 0.25);
      r.market_participation = GmMiClamp(
                                  0.4 * r.high_liquidity_score +
                                  0.3 * (vol.valid ? vol.energy_score : 55.0) +
                                  0.3 * (sup.valid ? MathMax(sup.market_energy, 0.0) : 55.0));

      r.liquidity_score = GmMiClamp(
                             0.35 * r.high_liquidity_score +
                             0.25 * r.spread_stability +
                             0.20 * r.session_liquidity +
                             0.20 * r.market_participation -
                             (r.liquidity_sweep ? 8.0 : 0.0));

      r.liquidity_report = StringFormat(
                              "AI Liquidity Engine:\r\nLiquidity Quality Score=%.0f/100\r\nHigh=%.0f Low=%.0f Sweep=%s Void=%.0f Session=%.0f SpreadStab=%.0f Part=%.0f\r\n%s\r\n",
                              r.liquidity_score, r.high_liquidity_score, r.low_liquidity_score,
                              (r.liquidity_sweep ? "Y" : "N"), r.liquidity_void_score,
                              r.session_liquidity, r.spread_stability, r.market_participation,
                              GM_MI_ANALYSIS_ONLY);
     }
  };

#endif // GM_CAI_LIQUIDITY_ENGINE_MQH
//+------------------------------------------------------------------+
