//+------------------------------------------------------------------+
//|                              CStrategyPerformanceAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Strategy KPIs from Analytics — NEVER mutates strategy       |
//+------------------------------------------------------------------+
#ifndef GM_CSTRATEGY_PERFORMANCE_ANALYZER_MQH
#define GM_CSTRATEGY_PERFORMANCE_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmIntelligenceResult.mqh"
#include "../../Analytics/CAnalyticsEngine.mqh"
#include "../Assistant/SGmAssistantResult.mqh"

class CGmStrategyPerformanceAnalyzer
  {
public:
   void Analyze(CGmAnalyticsEngine *analytics,
                const SGmAssistantResult &sup,
                SGmIntelligenceResult &r)
     {
      r.total_sessions = 0;
      r.winning_sessions = 0;
      r.losing_sessions = 0;
      r.recovery_success_rate = 50.0;
      r.average_drawdown = 0.0;
      r.monthly_stability = "Developing";
      r.recovery_efficiency_label = "—";
      r.risk_behavior_label = "Observed";
      r.best_conditions = "Trending + Healthy Liquidity";
      r.worst_conditions = "Extreme Volatility + Thin Liquidity";

      if(analytics != NULL)
        {
         const SGmAnalyticsSnapshot a = analytics.Snapshot();
         r.total_sessions = a.completed_sessions;
         r.winning_sessions = a.winning_sessions;
         r.losing_sessions = a.losing_sessions;
         r.average_drawdown = a.maximum_dd_pct > 0.0
                              ? 0.6 * a.current_dd_pct + 0.4 * a.maximum_dd_pct
                              : a.current_dd_pct;

         // Recovery efficiency proxy from recovery_factor / session win rate
         double rec = 50.0;
         if(a.recovery_factor > 0.0)
            rec = GmIntelClamp(40.0 + a.recovery_factor * 25.0);
         if(a.session_win_rate > 0.0)
            rec = 0.55 * rec + 0.45 * GmIntelClamp(a.session_win_rate);
         r.recovery_success_rate = GmIntelClamp(rec);

         if(a.session_win_rate >= 70.0 && a.maximum_dd_pct < 8.0)
            r.monthly_stability = "Excellent";
         else if(a.session_win_rate >= 55.0)
            r.monthly_stability = "Stable";
         else if(a.completed_sessions < 3)
            r.monthly_stability = "Insufficient Data";
         else
            r.monthly_stability = "Mixed";

         if(a.average_risk_pct <= 3.5 && a.current_dd_pct < 6.0)
            r.risk_behavior_label = "Controlled";
         else if(a.current_dd_pct >= 10.0)
            r.risk_behavior_label = "Stressed";
         else
            r.risk_behavior_label = "Moderate";
        }

      // Soft blend with Supervisor capital protection
      if(sup.valid)
        {
         r.average_drawdown = (r.average_drawdown > 0.0)
                              ? 0.7 * r.average_drawdown + 0.3 * MathMax(sup.current_dd_pct, sup.daily_dd_pct)
                              : MathMax(sup.current_dd_pct, sup.daily_dd_pct);
         if(sup.recovery_active)
            r.recovery_status = sup.recovery_status;
        }

      r.recovery_efficiency_label = StringFormat("%.0f%%", r.recovery_success_rate);

      // Strategy performance composite
      double score = 0.35 * r.recovery_success_rate;
      if(analytics != NULL)
        {
         const SGmAnalyticsSnapshot a = analytics.Snapshot();
         score += 0.30 * GmIntelClamp(a.session_win_rate);
         score += 0.20 * GmIntelClamp(100.0 - a.maximum_dd_pct * 6.0);
         score += 0.15 * GmIntelClamp(a.profit_factor > 0.0 ? 40.0 + a.profit_factor * 20.0 : 50.0);
        }
      else
         score += 0.65 * 50.0;
      r.strategy_performance_score = GmIntelClamp(score);

      r.performance_report = StringFormat(
                                "Stability=%s | Recovery=%s | Risk=%s | Sessions=%d W/L=%d/%d",
                                r.monthly_stability,
                                r.recovery_efficiency_label,
                                r.risk_behavior_label,
                                r.total_sessions,
                                r.winning_sessions,
                                r.losing_sessions);
     }
  };

#endif // GM_CSTRATEGY_PERFORMANCE_ANALYZER_MQH
//+------------------------------------------------------------------+
