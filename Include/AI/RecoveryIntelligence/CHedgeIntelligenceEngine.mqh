//+------------------------------------------------------------------+
//|                                  CHedgeIntelligenceEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CHEDGE_INTELLIGENCE_ENGINE_MQH
#define GM_CHEDGE_INTELLIGENCE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmRecoveryIntelligenceResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../../Analytics/SGmAnalyticsSnapshot.mqh"

class CGmHedgeIntelligenceEngine
  {
public:
   void Analyze(const SGmAssistantResult &sup,
                const SGmAnalyticsSnapshot &a,
                const SGmRecoveryIntelligenceResult &partial,
                SGmRecoveryIntelligenceResult &r)
     {
      // Observational hedge proxies from dual-side book + recovery activity
      const double buy_open = (double)a.buy_open;
      const double sell_open = (double)a.sell_open;
      const bool dual = (buy_open > 0.0 && sell_open > 0.0);

      r.hedge_frequency = GmRiClamp(
                             (dual ? 55.0 : 20.0) +
                             (a.recovery_trades > 0 ? 20.0 : 0.0) +
                             MathMin(25.0, (double)a.running_trades * 5.0));

      r.hedge_success = GmRiClamp(
                           0.45 * partial.recovery_success_rate +
                           0.30 * GmRiClamp(a.recovery_factor * 28.0) +
                           0.25 * (100.0 - MathAbs(a.floating_loss) * 0.1));

      r.hedge_duration = (a.avg_holding_sec > 0.0)
                         ? a.avg_holding_sec
                         : partial.recovery_duration;

      r.gross_recovery = GmRiClamp(
                            MathMax(0.0, a.week_profit) * 0.15 +
                            MathMax(0.0, a.total_net_profit) * 0.05 +
                            partial.recovery_success_rate * 0.4);

      r.net_recovery = GmRiClamp(
                          r.gross_recovery -
                          MathAbs(a.avg_loss_per_trade) * 0.2 -
                          partial.recovery_cost * 0.15);

      r.recovery_stability = GmRiClamp(
                                0.40 * (100.0 - a.current_dd_pct) +
                                0.30 * (sup.valid ? sup.equity_stability : 55.0) +
                                0.30 * partial.recovery_efficiency);

      r.hedge_quality_score = GmRiClamp(
                                 0.30 * r.hedge_success +
                                 0.25 * r.net_recovery +
                                 0.25 * r.recovery_stability +
                                 0.20 * (100.0 - r.hedge_frequency * 0.3));

      r.hedge_effectiveness = GmRiClamp(
                                 0.50 * r.hedge_quality_score +
                                 0.30 * partial.recovery_efficiency +
                                 0.20 * r.net_recovery);

      r.hedge_report = StringFormat(
                          "Hedge Intelligence:\r\nQuality=%.0f Effectiveness=%.0f\r\nFreq=%.0f Success=%.0f Dur=%.0fs\r\nGross=%.0f Net=%.0f Stability=%.0f DualSide=%s\r\n%s\r\n",
                          r.hedge_quality_score, r.hedge_effectiveness,
                          r.hedge_frequency, r.hedge_success, r.hedge_duration,
                          r.gross_recovery, r.net_recovery, r.recovery_stability,
                          (dual ? "Y" : "N"), GM_RI_ADVISORY);
     }
  };

#endif // GM_CHEDGE_INTELLIGENCE_ENGINE_MQH
//+------------------------------------------------------------------+
