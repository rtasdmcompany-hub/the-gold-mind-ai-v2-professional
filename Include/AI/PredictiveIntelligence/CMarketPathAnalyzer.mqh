//+------------------------------------------------------------------+
//|                                      CMarketPathAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CMARKET_PATH_ANALYZER_MQH
#define GM_CMARKET_PATH_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmPredictiveIntelligenceResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../OrderFlow/SGmOrderFlowResult.mqh"
#include "../RecoveryIntelligence/SGmRecoveryIntelligenceResult.mqh"

class CGmMarketPathAnalyzer
  {
public:
   void Analyze(const SGmTrendAnalysisResult &trend,
                const SGmVolatilityAnalysisResult &vol,
                const SGmOrderFlowResult &of,
                const SGmRecoveryIntelligenceResult &ri,
                const SGmPredictiveIntelligenceResult &partial,
                SGmPredictiveIntelligenceResult &r)
     {
      if(partial.bullish_probability >= partial.bearish_probability + 8.0)
         r.expected_direction = "Bullish Bias";
      else if(partial.bearish_probability >= partial.bullish_probability + 8.0)
         r.expected_direction = "Bearish Bias";
      else
         r.expected_direction = "Neutral / Mixed";

      r.expected_range = GmPredClamp(
                            0.40 * partial.scn_range +
                            0.30 * (vol.valid ? (100.0 - vol.atr_strength * 0.4) : 50.0) +
                            0.30 * partial.continuation_probability * 0.5);

      r.expected_momentum = GmPredClamp(
                               trend.valid ? trend.momentum_strength
                               : (of.valid ? of.session_momentum : 50.0));

      r.expected_atr = GmPredClamp(
                          0.50 * (vol.valid ? vol.atr_strength : 50.0) +
                          0.50 * partial.atr_expansion_probability);

      r.expected_energy = GmPredClamp(
                             vol.valid ? vol.energy_score
                             : (of.valid ? of.energy_score : 50.0));

      r.expected_liquidity = GmPredClamp(
                                of.valid ? of.session_liquidity
                                : partial.liquidity_probability);

      r.expected_session_behaviour = of.valid
                                     ? StringFormat("%s | Str=%.0f Vol=%.0f",
                                                    GmOfSessionName(of.active_session),
                                                    of.session_strength, of.session_volatility)
                                     : "Session context soft";

      r.expected_recovery_conditions = ri.valid
                                       ? StringFormat("Health=%s Success=%.0f Prob=%.0f",
                                                      GmRiHealthName(ri.recovery_health),
                                                      ri.recovery_success_rate,
                                                      ri.recovery_probability)
                                       : "Recovery idle / soft";

      r.path_report = StringFormat(
                         "Market Path Analyzer:\r\nDir=%s Range=%.0f Mom=%.0f ATR=%.0f Energy=%.0f Liq=%.0f\r\nSession: %s\r\nRecovery: %s\r\n%s\r\n",
                         r.expected_direction, r.expected_range, r.expected_momentum,
                         r.expected_atr, r.expected_energy, r.expected_liquidity,
                         r.expected_session_behaviour, r.expected_recovery_conditions,
                         GM_PRED_ANALYSIS_ONLY);
     }
  };

#endif // GM_CMARKET_PATH_ANALYZER_MQH
//+------------------------------------------------------------------+
