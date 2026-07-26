//+------------------------------------------------------------------+
//|                               CInstitutionalMarketAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CINSTITUTIONAL_MARKET_ANALYZER_MQH
#define GM_CINSTITUTIONAL_MARKET_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMarketIntelligenceResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"

class CGmInstitutionalMarketAnalyzer
  {
public:
   void Analyze(const SGmTrendAnalysisResult &trend,
                const SGmVolatilityAnalysisResult &vol,
                const SGmMarketIntelligenceResult &partial,
                SGmMarketIntelligenceResult &r)
     {
      r.accumulation_score = 40.0;
      r.distribution_score = 40.0;
      if(vol.valid && vol.atr_compression && trend.valid && MathAbs(trend.directional_bias) < 20.0)
         r.accumulation_score = GmMiClamp(55.0 + (100.0 - vol.energy_score) * 0.25);
      if(vol.valid && vol.atr_expansion && trend.valid && trend.directional_bias < -10.0)
         r.distribution_score = GmMiClamp(55.0 + vol.energy_score * 0.25);
      if(trend.valid && trend.directional_bias > 20.0 && vol.valid && vol.atr_compression)
         r.accumulation_score = GmMiClamp(r.accumulation_score + 12.0);

      if(vol.valid && vol.atr_expansion && partial.momentum_index >= 65.0)
         r.institutional_phase = GM_MI_INST_EXPANSION;
      else if(vol.valid && vol.atr_compression)
         r.institutional_phase = GM_MI_INST_CONSOLIDATION;
      else if(partial.trend_continuation && partial.momentum_index >= 60.0)
         r.institutional_phase = GM_MI_INST_IMPULSE;
      else if(partial.trend_weakness || partial.momentum_exhaustion >= 55.0)
         r.institutional_phase = GM_MI_INST_CORRECTION;
      else if(r.accumulation_score >= r.distribution_score + 8.0)
         r.institutional_phase = GM_MI_INST_ACCUMULATION;
      else if(r.distribution_score >= r.accumulation_score + 8.0)
         r.institutional_phase = GM_MI_INST_DISTRIBUTION;
      else
         r.institutional_phase = GM_MI_INST_CONSOLIDATION;

      r.stop_hunt_probability = GmMiClamp(
                                   (partial.liquidity_sweep ? 55.0 : 18.0) +
                                   (vol.valid && vol.atr_expansion ? 15.0 : 0.0) +
                                   partial.momentum_exhaustion * 0.15);
      r.liquidity_grab_probability = GmMiClamp(
                                        0.55 * r.stop_hunt_probability +
                                        0.45 * partial.liquidity_void_score * 0.5);
      r.false_breakout_probability = GmMiClamp(
                                        (vol.valid ? vol.prob_breakout * 0.35 : 20.0) +
                                        (partial.trend_weakness ? 20.0 : 5.0) +
                                        (partial.change_of_character ? 15.0 : 0.0) +
                                        (100.0 - partial.structure_quality) * 0.15);

      r.institutional_momentum = GmMiClamp(
                                    0.45 * partial.momentum_index +
                                    0.30 * (50.0 + (trend.valid ? trend.directional_bias * 0.5 : 0.0)) +
                                    0.25 * (vol.valid ? vol.energy_score : 50.0));

      r.institutional_bias = trend.valid
                             ? MathMax(-100.0, MathMin(100.0, trend.directional_bias))
                             : 0.0;

      r.institutional_activity = StringFormat("%s | Mom=%.0f Bias=%.0f",
                                              GmMiInstPhaseName(r.institutional_phase),
                                              r.institutional_momentum,
                                              r.institutional_bias);

      r.institutional_report = StringFormat(
                                  "Institutional Market Analyzer:\r\nPhase=%s | Bias=%.0f\r\nAccum=%.0f Dist=%.0f InstMom=%.0f\r\nStopHunt=%.0f%% LiqGrab=%.0f%% FalseBO=%.0f%%\r\n%s\r\n",
                                  GmMiInstPhaseName(r.institutional_phase), r.institutional_bias,
                                  r.accumulation_score, r.distribution_score, r.institutional_momentum,
                                  r.stop_hunt_probability, r.liquidity_grab_probability,
                                  r.false_breakout_probability, GM_MI_ANALYSIS_ONLY);
     }
  };

#endif // GM_CINSTITUTIONAL_MARKET_ANALYZER_MQH
//+------------------------------------------------------------------+
