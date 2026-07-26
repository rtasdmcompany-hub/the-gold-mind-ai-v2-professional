//+------------------------------------------------------------------+
//|                                 CLossMinimizationAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CLOSS_MINIMIZATION_ANALYZER_MQH
#define GM_CLOSS_MINIMIZATION_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmRecoveryIntelligenceResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../../Analytics/SGmAnalyticsSnapshot.mqh"

class CGmLossMinimizationAnalyzer
  {
public:
   void Analyze(const SGmAssistantResult &sup,
                const SGmAnalyticsSnapshot &a,
                const SGmRecoveryIntelligenceResult &partial,
                SGmRecoveryIntelligenceResult &r)
     {
      r.average_loss = MathAbs(a.avg_loss_per_trade);
      r.maximum_loss = MathAbs(a.largest_loss);
      r.average_recovery = GmRiClamp(
                              MathMax(0.0, a.avg_profit_per_trade) * 0.5 +
                              partial.recovery_success_rate * 0.4);
      r.recovery_speed = GmRiClamp(
                            100.0 - MathMin(80.0, a.avg_loss_duration_sec / 60.0) +
                            (a.avg_loss_duration_sec <= 0.0 ? 40.0 : 0.0));
      r.drawdown_stability = GmRiClamp(
                                100.0 - MathMax(a.current_dd_pct, a.daily_dd_pct) * 1.2);
      r.capital_preservation = GmRiClamp(
                                  0.40 * (sup.valid ? sup.capital_protection_score : 55.0) +
                                  0.30 * r.drawdown_stability +
                                  0.30 * (100.0 - MathMin(50.0, r.average_loss)));

      r.loss_control_score = GmRiClamp(
                                0.30 * (100.0 - MathMin(80.0, r.average_loss * 2.0)) +
                                0.25 * (100.0 - MathMin(80.0, r.maximum_loss * 1.5)) +
                                0.25 * r.recovery_speed +
                                0.20 * r.drawdown_stability);

      r.capital_protection_rating = GmRiClamp(
                                       0.45 * r.capital_preservation +
                                       0.30 * r.loss_control_score +
                                       0.25 * partial.recovery_health_index);

      r.loss_report = StringFormat(
                         "Loss Minimization Analyzer:\r\nLossControl=%.0f CapProtect=%.0f\r\nAvgLoss=%.2f MaxLoss=%.2f AvgRec=%.0f Speed=%.0f\r\nDDStab=%.0f CapPres=%.0f\r\n%s\r\n",
                         r.loss_control_score, r.capital_protection_rating,
                         r.average_loss, r.maximum_loss, r.average_recovery,
                         r.recovery_speed, r.drawdown_stability, r.capital_preservation,
                         GM_RI_ANALYSIS_ONLY);
     }
  };

#endif // GM_CLOSS_MINIMIZATION_ANALYZER_MQH
//+------------------------------------------------------------------+
