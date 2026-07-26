//+------------------------------------------------------------------+
//|                           CAIPortfolioIntelligenceCore.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_PORTFOLIO_INTELLIGENCE_CORE_MQH
#define GM_CAI_PORTFOLIO_INTELLIGENCE_CORE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmPortfolioIntelligenceResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../RecoveryIntelligence/SGmRecoveryIntelligenceResult.mqh"
#include "../Enterprise/SGmEnterpriseResult.mqh"
#include "../../Analytics/SGmAnalyticsSnapshot.mqh"

class CGmAIPortfolioIntelligenceCore
  {
public:
   void Analyze(const SGmAssistantResult &sup,
                const SGmAnalyticsSnapshot &a,
                const SGmRecoveryIntelligenceResult &ri,
                const SGmEnterpriseResult &ent,
                SGmPortfolioIntelligenceResult &r)
     {
      r.open_positions = a.running_trades;
      r.pending_orders = a.pending_orders;
      r.recovery_active = (sup.valid && sup.recovery_active) || (a.recovery_trades > 0) ||
                          (ri.valid && ri.recovery_health_index < 45.0 && ri.recovery_attempts > 0);
      r.recovery_status = (sup.valid && StringLen(sup.recovery_status) > 0)
                          ? sup.recovery_status
                          : (r.recovery_active ? "Observed" : "Idle");

      r.portfolio_exposure = GmPiClamp(
                                MathMin(100.0, (double)r.open_positions * 12.0 +
                                        (double)r.pending_orders * 4.0 +
                                        (sup.valid ? sup.risk_exposure_pct * 0.5 : 0.0)));

      const double equity = (a.equity > 0.0) ? a.equity : AccountInfoDouble(ACCOUNT_EQUITY);
      const double balance = (a.balance > 0.0) ? a.balance : AccountInfoDouble(ACCOUNT_BALANCE);
      r.capital_allocation_pct = (equity > 0.0 && balance > 0.0)
                                 ? GmPiClamp(MathAbs(equity - balance) / MathMax(1.0, balance) * 100.0 +
                                             (double)r.open_positions * 5.0)
                                 : GmPiClamp((double)r.open_positions * 8.0);

      r.risk_distribution = GmPiClamp(
                               0.40 * (sup.valid ? MathAbs(sup.current_dd_pct) * 2.0 : a.current_dd_pct * 2.0) +
                               0.30 * r.portfolio_exposure +
                               0.30 * (sup.valid ? sup.margin_usage_pct : 30.0));

      r.performance_distribution = GmPiClamp(
                                      50.0 + a.overall_win_rate * 0.35 +
                                      MathMax(-20.0, MathMin(20.0, a.today_profit * 0.05)) -
                                      MathAbs(a.today_loss) * 0.03);

      r.portfolio_health = GmPiClamp(
                              0.30 * (100.0 - r.risk_distribution * 0.6) +
                              0.25 * r.performance_distribution +
                              0.20 * (ent.valid ? ent.fleet_health_score : 70.0) +
                              0.15 * (ri.valid ? ri.recovery_health_index : 60.0) +
                              0.10 * (r.recovery_active ? 45.0 : 75.0));

      r.portfolio_health_index = r.portfolio_health;
      r.portfolio_stability_score = GmPiClamp(
                                       0.40 * r.portfolio_health +
                                       0.30 * (sup.valid ? sup.equity_stability : 55.0) +
                                       0.30 * (100.0 - MathAbs(a.current_dd_pct) * 1.5));

      r.portfolio_intelligence_score = GmPiClamp(
                                          0.35 * r.portfolio_health_index +
                                          0.25 * r.portfolio_stability_score +
                                          0.20 * r.performance_distribution +
                                          0.20 * (100.0 - r.portfolio_exposure * 0.4));

      if(r.portfolio_health_index >= 85.0)
         r.health_class = GM_PI_HEALTH_EXCELLENT;
      else if(r.portfolio_health_index >= 70.0)
         r.health_class = GM_PI_HEALTH_STRONG;
      else if(r.portfolio_health_index >= 55.0)
         r.health_class = GM_PI_HEALTH_STABLE;
      else if(r.portfolio_health_index >= 40.0)
         r.health_class = GM_PI_HEALTH_WEAK;
      else
         r.health_class = GM_PI_HEALTH_CRITICAL;

      r.portfolio_report = StringFormat(
                              "AI Portfolio Intelligence:\r\nScore=%.0f Health=%.0f (%s) Stab=%.0f\r\nExposure=%.0f CapAlloc=%.0f Open=%d Pend=%d\r\nRecovery=%s | RiskDist=%.0f PerfDist=%.0f\r\n%s | %s\r\n",
                              r.portfolio_intelligence_score, r.portfolio_health_index,
                              GmPiHealthName(r.health_class), r.portfolio_stability_score,
                              r.portfolio_exposure, r.capital_allocation_pct,
                              r.open_positions, r.pending_orders,
                              r.recovery_status, r.risk_distribution, r.performance_distribution,
                              GM_PI_CONTEXT, GM_PI_ANALYSIS_ONLY);
     }
  };

#endif // GM_CAI_PORTFOLIO_INTELLIGENCE_CORE_MQH
//+------------------------------------------------------------------+
