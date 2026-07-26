//+------------------------------------------------------------------+
//|                                       SGmReportingResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_REPORTING_RESULT_MQH
#define GM_SGM_REPORTING_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ReportingAIConstants.mqh"

struct SGmReportingResult
  {
   datetime           stamped_at;
   string             symbol;
   ulong              session_id;
   string             report_id;
   ENUM_GM_RPT_STATUS status;
   ENUM_GM_RPT_TYPE   primary_type;

   // Generated report bodies (compressed text)
   string             daily_report;
   string             weekly_report;
   string             monthly_report;
   string             session_report;
   string             risk_report;
   string             performance_report;
   string             learning_report;
   string             latest_report_headline;

   // Executive
   string             executive_brief;
   string             market_condition_label;
   string             risk_level_label;
   string             system_health_label;
   double             exec_confidence;
   string             recommendation;

   // Session analytics
   datetime           session_start;
   datetime           session_end;
   string             session_market;
   string             session_environment;
   double             session_volatility;
   double             session_spread;
   string             session_recovery;
   double             session_drawdown;
   string             session_outcome;

   // Performance scorecard
   double             prediction_accuracy;
   double             warning_accuracy;
   double             pattern_accuracy;
   double             confidence_accuracy;
   double             learning_improvement;
   double             report_quality;
   double             performance_score;
   ENUM_GM_RPT_GRADE  performance_grade;

   // Enterprise analytics
   string             monthly_intelligence;
   string             risk_evolution;
   string             accuracy_trend;
   string             learning_growth;
   string             enterprise_analytics;

   // Audit
   int                audit_events;
   string             audit_history;

   // Dashboard
   string             reporting_status;
   string             advisory_status;
   string             insight;
   bool               may_execute;
   bool               may_modify_strategy;
   bool               from_cache;
   bool               valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = "";
      session_id = 0;
      report_id = "";
      status = GM_RPT_STATUS_IDLE;
      primary_type = GM_RPT_TYPE_DAILY;
      daily_report = weekly_report = monthly_report = "";
      session_report = risk_report = performance_report = learning_report = "";
      latest_report_headline = "";
      executive_brief = "";
      market_condition_label = risk_level_label = system_health_label = "—";
      exec_confidence = 0.0;
      recommendation = "Continue Monitoring";
      session_start = session_end = 0;
      session_market = session_environment = session_recovery = session_outcome = "";
      session_volatility = session_spread = session_drawdown = 0.0;
      prediction_accuracy = warning_accuracy = pattern_accuracy = 0.0;
      confidence_accuracy = learning_improvement = report_quality = 0.0;
      performance_score = 0.0;
      performance_grade = GM_RPT_GRADE_UNKNOWN;
      monthly_intelligence = risk_evolution = accuracy_trend = "";
      learning_growth = enterprise_analytics = "";
      audit_events = 0;
      audit_history = "";
      reporting_status = "Idle";
      advisory_status = GM_RPT_ADVISORY;
      insight = "";
      may_execute = false;
      may_modify_strategy = false;
      from_cache = false;
      valid = false;
     }
  };

#endif // GM_SGM_REPORTING_RESULT_MQH
//+------------------------------------------------------------------+
