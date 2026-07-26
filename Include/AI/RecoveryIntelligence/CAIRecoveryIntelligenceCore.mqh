//+------------------------------------------------------------------+
//|                            CAIRecoveryIntelligenceCore.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_RECOVERY_INTELLIGENCE_CORE_MQH
#define GM_CAI_RECOVERY_INTELLIGENCE_CORE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmRecoveryIntelligenceResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../../Analytics/SGmAnalyticsSnapshot.mqh"
#include "../../Recovery/CRecoveryBase.mqh"

class CGmAIRecoveryIntelligenceCore
  {
public:
   void Analyze(const SGmAssistantResult &sup,
                const SGmAnalyticsSnapshot &a,
                CGmRecoveryBase *recovery,
                SGmRecoveryIntelligenceResult &r)
     {
      const bool active = (sup.valid && sup.recovery_active) || (a.recovery_trades > 0);
      int own_pos = a.recovery_trades;
      int own_pend = a.pending_orders;
      if(recovery != NULL)
        {
         SGmRecoverySnapshot rs = recovery.LastSnapshot();
         if(rs.own_positions > own_pos) own_pos = rs.own_positions;
         if(rs.own_pendings > own_pend) own_pend = rs.own_pendings;
        }

      r.recovery_attempts = (double)MathMax(own_pos + (active ? 1 : 0),
                                            a.losing_trades > 0 ? 1 : 0);
      if(a.total_trades > 0)
         r.recovery_attempts = MathMax(r.recovery_attempts,
                                       (double)a.losing_trades);

      // Success from second-attempt / recovery factor proxies
      r.recovery_success_rate = GmRiClamp(
                                   0.55 * a.second_attempt_win_rate +
                                   0.25 * a.overall_win_rate +
                                   0.20 * GmRiClamp(a.recovery_factor * 25.0));

      r.recovery_duration = (a.avg_loss_duration_sec > 0.0)
                            ? a.avg_loss_duration_sec
                            : a.avg_trade_duration_sec;
      r.recovery_drawdown = GmRiClamp(MathMax(a.current_dd_pct, a.maximum_dd_pct));
      r.recovery_cost = GmRiClamp(MathAbs(a.avg_loss_per_trade) * 2.0 +
                                  MathAbs(a.today_loss) * 0.05);
      r.recovery_efficiency = GmRiClamp(
                                 100.0 - r.recovery_cost * 0.35 -
                                 r.recovery_drawdown * 0.40 +
                                 r.recovery_success_rate * 0.25);
      r.recovery_probability = GmRiClamp(
                                  0.50 * r.recovery_success_rate +
                                  0.30 * (100.0 - r.recovery_drawdown) +
                                  0.20 * r.recovery_efficiency);

      r.recovery_intelligence_score = GmRiClamp(
                                         0.30 * r.recovery_success_rate +
                                         0.25 * r.recovery_efficiency +
                                         0.20 * r.recovery_probability +
                                         0.15 * (100.0 - r.recovery_drawdown) +
                                         0.10 * (active ? 55.0 : 70.0));

      r.recovery_confidence = GmRiClamp(
                                 0.40 * r.recovery_intelligence_score +
                                 0.30 * (a.total_trades >= 5 ? 75.0 : 45.0) +
                                 0.30 * (sup.valid ? 60.0 + (sup.capital_protection_score * 0.3) : 50.0));

      r.recovery_health_index = GmRiClamp(
                                   0.35 * r.recovery_intelligence_score +
                                   0.25 * r.recovery_success_rate +
                                   0.20 * (100.0 - r.recovery_drawdown) +
                                   0.20 * r.recovery_efficiency);

      if(r.recovery_health_index >= 80.0)
         r.recovery_health = GM_RI_HEALTH_EXCELLENT;
      else if(r.recovery_health_index >= 65.0)
         r.recovery_health = GM_RI_HEALTH_STRONG;
      else if(r.recovery_health_index >= 50.0)
         r.recovery_health = GM_RI_HEALTH_STABLE;
      else if(r.recovery_health_index >= 35.0)
         r.recovery_health = GM_RI_HEALTH_WEAK;
      else
         r.recovery_health = GM_RI_HEALTH_CRITICAL;

      string status = (sup.valid && StringLen(sup.recovery_status) > 0)
                      ? sup.recovery_status : (active ? "Active" : "Idle");

      r.recovery_report = StringFormat(
                             "AI Recovery Intelligence:\r\nScore=%.0f Conf=%.0f Health=%.0f (%s)\r\nAttempts=%.0f Success=%.0f%% Eff=%.0f Prob=%.0f\r\nDD=%.1f Cost=%.0f Dur=%.0fs Status=%s\r\n%s\r\n%s\r\n",
                             r.recovery_intelligence_score, r.recovery_confidence,
                             r.recovery_health_index, GmRiHealthName(r.recovery_health),
                             r.recovery_attempts, r.recovery_success_rate,
                             r.recovery_efficiency, r.recovery_probability,
                             r.recovery_drawdown, r.recovery_cost, r.recovery_duration,
                             status, GM_RI_GOLDMIND_CONTEXT, GM_RI_ANALYSIS_ONLY);
     }
  };

#endif // GM_CAI_RECOVERY_INTELLIGENCE_CORE_MQH
//+------------------------------------------------------------------+
