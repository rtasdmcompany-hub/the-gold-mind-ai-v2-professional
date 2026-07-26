//+------------------------------------------------------------------+
//|                             SGmPortfolioAnalyticsResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_PORTFOLIO_ANALYTICS_RESULT_MQH
#define GM_SGM_PORTFOLIO_ANALYTICS_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "PortfolioAnalyticsConstants.mqh"

struct SGmEpaEquityPoint
  {
   datetime t;
   double   equity;
   double   balance;
   double   drawdown_pct;
   double   growth_pct;
  };

struct SGmPortfolioAnalyticsResult
  {
   datetime          stamped_at;
   ENUM_GM_EPA_GRADE performance_grade;

   int               trades_closed;
   int               equity_points;
   int               winning_streak;
   int               losing_streak;
   int               max_consec_losses;

   double            daily_pnl;
   double            weekly_pnl;
   double            monthly_pnl;
   double            quarterly_pnl;
   double            yearly_pnl;
   double            session_pnl;

   double            capital_growth_pct;
   double            equity_growth_pct;
   double            balance_growth_pct;
   double            recovery_performance;

   double            portfolio_health;
   double            risk_stability;
   double            capital_efficiency;

   double            max_drawdown_pct;
   double            relative_drawdown_pct;
   double            absolute_drawdown;
   double            daily_risk;
   double            weekly_risk;
   double            monthly_risk;
   double            value_at_risk;
   double            recovery_factor;
   double            risk_reward_avg;

   double            profit_factor;
   double            sharpe_ratio;
   double            sortino_ratio;
   double            calmar_ratio;
   double            recovery_ratio;
   double            expectancy;
   double            avg_holding_sec;
   double            trade_frequency;
   double            win_rate;

   string            equity_curve_summary;
   string            balance_curve_summary;
   string            drawdown_curve_summary;
   string            growth_curve_summary;
   string            recovery_curve_summary;
   string            monthly_heatmap;
   string            performance_timeline;
   string            capital_report;
   string            risk_report;
   string            performance_report;
   string            export_status;
   string            center_status;
   string            insight;

   bool              may_execute;
   bool              may_modify_risk;
   bool              may_interrupt_trading;
   bool              valid;

   void Reset(void)
     {
      stamped_at = 0;
      performance_grade = GM_EPA_GRADE_F;
      trades_closed = equity_points = 0;
      winning_streak = losing_streak = max_consec_losses = 0;
      daily_pnl = weekly_pnl = monthly_pnl = quarterly_pnl = yearly_pnl = session_pnl = 0.0;
      capital_growth_pct = equity_growth_pct = balance_growth_pct = recovery_performance = 0.0;
      portfolio_health = risk_stability = capital_efficiency = 0.0;
      max_drawdown_pct = relative_drawdown_pct = absolute_drawdown = 0.0;
      daily_risk = weekly_risk = monthly_risk = value_at_risk = 0.0;
      recovery_factor = risk_reward_avg = 0.0;
      profit_factor = sharpe_ratio = sortino_ratio = calmar_ratio = 0.0;
      recovery_ratio = expectancy = avg_holding_sec = trade_frequency = win_rate = 0.0;
      equity_curve_summary = balance_curve_summary = drawdown_curve_summary = "";
      growth_curve_summary = recovery_curve_summary = monthly_heatmap = "";
      performance_timeline = capital_report = risk_report = performance_report = "";
      export_status = "Architecture Ready";
      center_status = insight = "";
      may_execute = false;
      may_modify_risk = false;
      may_interrupt_trading = false;
      valid = false;
     }
  };

#endif // GM_SGM_PORTFOLIO_ANALYTICS_RESULT_MQH
//+------------------------------------------------------------------+
