//+------------------------------------------------------------------+
//|                                SGmReportingCenterResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_REPORTING_CENTER_RESULT_MQH
#define GM_SGM_REPORTING_CENTER_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ReportingCenterConstants.mqh"

struct SGmReportingCenterResult
  {
   datetime           stamped_at;
   ENUM_GM_ERC_QUEUE  queue_status;

   int                reports_generated;
   int                trades_reported;

   double             report_quality;
   double             bi_score;
   double             performance_forecast;
   double             investor_rating;

   // Investor dashboard fields
   double             account_growth_pct;
   double             portfolio_value;
   double             net_profit;
   double             gross_profit;
   double             gross_loss;
   double             profit_factor;
   double             max_drawdown_pct;
   double             recovery_factor;
   double             avg_monthly_return;
   double             capital_growth_pct;

   string             daily_report;
   string             weekly_report;
   string             monthly_report;
   string             quarterly_report;
   string             yearly_report;
   string             session_report;
   string             growth_report;
   string             risk_report;
   string             recovery_report;
   string             executive_summary;
   string             investor_summary;
   string             bi_report;
   string             visualization_catalog;
   string             recommendations;
   string             latest_reports;
   string             export_status;
   string             center_status;
   string             insight;

   bool               may_execute;
   bool               may_modify_risk;
   bool               may_interrupt_trading;
   bool               valid;

   void Reset(void)
     {
      stamped_at = 0;
      queue_status = GM_ERC_Q_IDLE;
      reports_generated = trades_reported = 0;
      report_quality = bi_score = performance_forecast = investor_rating = 0.0;
      account_growth_pct = portfolio_value = net_profit = 0.0;
      gross_profit = gross_loss = profit_factor = 0.0;
      max_drawdown_pct = recovery_factor = avg_monthly_return = capital_growth_pct = 0.0;
      daily_report = weekly_report = monthly_report = quarterly_report = yearly_report = "";
      session_report = growth_report = risk_report = recovery_report = "";
      executive_summary = investor_summary = bi_report = visualization_catalog = "";
      recommendations = latest_reports = "";
      export_status = "Architecture Ready";
      center_status = insight = "";
      may_execute = false;
      may_modify_risk = false;
      may_interrupt_trading = false;
      valid = false;
     }
  };

#endif // GM_SGM_REPORTING_CENTER_RESULT_MQH
//+------------------------------------------------------------------+
