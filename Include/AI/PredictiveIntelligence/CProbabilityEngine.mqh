//+------------------------------------------------------------------+
//|                                       CProbabilityEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CPROBABILITY_ENGINE_PRED_MQH
#define GM_CPROBABILITY_ENGINE_PRED_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmPredictiveIntelligenceResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../OrderFlow/SGmOrderFlowResult.mqh"
#include "../RecoveryIntelligence/SGmRecoveryIntelligenceResult.mqh"
#include "../Forecasting/SGmForecastResult.mqh"

class CGmProbabilityEnginePred
  {
public:
   void Analyze(const SGmTrendAnalysisResult &trend,
                const SGmVolatilityAnalysisResult &vol,
                const SGmOrderFlowResult &of,
                const SGmRecoveryIntelligenceResult &ri,
                const SGmForecastResult &fcst,
                const SGmPredictiveIntelligenceResult &partial,
                SGmPredictiveIntelligenceResult &r)
     {
      r.bullish_probability = GmPredClamp(
                                 0.45 * partial.scn_bull_cont +
                                 0.25 * (50.0 + (trend.valid ? trend.directional_bias * 0.4 : 0.0)) +
                                 0.15 * partial.scn_breakout +
                                 0.15 * (fcst.valid ? fcst.trend_probability : 50.0));

      r.bearish_probability = GmPredClamp(
                                 0.45 * partial.scn_bear_cont +
                                 0.25 * (50.0 - (trend.valid ? trend.directional_bias * 0.4 : 0.0)) +
                                 0.15 * partial.scn_false_breakout +
                                 0.15 * (100.0 - (fcst.valid ? fcst.trend_probability : 50.0)));

      // Renormalize bull/bear soft
      const double bb = r.bullish_probability + r.bearish_probability;
      if(bb > 0.0)
        {
         r.bullish_probability = r.bullish_probability / bb * 100.0;
         r.bearish_probability = r.bearish_probability / bb * 100.0;
        }

      r.continuation_probability = GmPredClamp(
                                      0.50 * (partial.scn_bull_cont + partial.scn_bear_cont) +
                                      0.30 * (fcst.valid ? fcst.scn_continuation : 50.0) +
                                      0.20 * (trend.valid ? trend.trend_stability : 50.0));

      r.reversal_probability = GmPredClamp(
                                  0.40 * partial.scn_false_breakout +
                                  0.30 * (fcst.valid ? fcst.scn_reversal : 35.0) +
                                  0.30 * (trend.valid ? trend.trend_exhaustion : 35.0));

      r.atr_expansion_probability = GmPredClamp(
                                       0.50 * partial.scn_high_vol +
                                       0.30 * partial.scn_breakout +
                                       0.20 * (vol.valid && vol.atr_expansion ? 75.0 : 40.0));

      r.volatility_probability = GmPredClamp(
                                    0.55 * (vol.valid ? vol.energy_score : 50.0) +
                                    0.45 * partial.scn_high_vol);

      r.liquidity_probability = GmPredClamp(
                                   of.valid ? of.session_liquidity
                                   : (partial.expected_liquidity > 0.0 ? partial.expected_liquidity : 55.0));

      r.recovery_probability = GmPredClamp(
                                  0.55 * partial.scn_recovery +
                                  0.45 * (ri.valid ? ri.recovery_probability : 40.0));

      r.overall_probability_score = GmPredClamp(
                                       0.20 * MathMax(r.bullish_probability, r.bearish_probability) +
                                       0.20 * r.continuation_probability +
                                       0.15 * r.atr_expansion_probability +
                                       0.15 * r.volatility_probability +
                                       0.15 * r.liquidity_probability +
                                       0.15 * partial.prediction_confidence);

      const double spread = 12.0 + (100.0 - partial.forecast_reliability) * 0.18;
      r.confidence_interval_lo = GmPredClamp(r.overall_probability_score - spread);
      r.confidence_interval_hi = GmPredClamp(r.overall_probability_score + spread);

      r.probability_report = StringFormat(
                                "Probability Engine:\r\nOverall=%.0f CI=[%.0f..%.0f]\r\nBull=%.0f Bear=%.0f Cont=%.0f Rev=%.0f\r\nATRExp=%.0f Vol=%.0f Liq=%.0f Rec=%.0f\r\n%s\r\n",
                                r.overall_probability_score, r.confidence_interval_lo, r.confidence_interval_hi,
                                r.bullish_probability, r.bearish_probability,
                                r.continuation_probability, r.reversal_probability,
                                r.atr_expansion_probability, r.volatility_probability,
                                r.liquidity_probability, r.recovery_probability,
                                GM_PRED_ANALYSIS_ONLY);
     }
  };

#endif // GM_CPROBABILITY_ENGINE_PRED_MQH
//+------------------------------------------------------------------+
