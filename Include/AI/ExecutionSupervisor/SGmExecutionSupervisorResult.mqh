//+------------------------------------------------------------------+
//|                            SGmExecutionSupervisorResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_EXECUTION_SUPERVISOR_RESULT_MQH
#define GM_SGM_EXECUTION_SUPERVISOR_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ExecutionSupervisorConstants.mqh"

struct SGmExecutionSupervisorResult
  {
   datetime           stamped_at;
   string             symbol;
   ulong              session_id;
   ENUM_GM_ES_STATUS  status;

   // Observed counts (read-only)
   int                pending_orders;
   int                active_trades;
   int                buy_open;
   int                sell_open;
   int                total_trades;
   int                recovery_trades;
   double             floating_profit;
   double             floating_loss;
   double             spread_points;
   double             atr14;

   // Lifecycle
   ENUM_GM_ES_STAGE   lifecycle_stage;
   string             lifecycle_status;
   string             execution_timeline;
   string             recovery_timeline;
   string             lifecycle_report;
   double             trade_duration_sec;
   int                lifecycle_events;

   // Supervisor health
   double             execution_health_score;
   double             decision_stability_score;
   double             environment_stability_score;
   string             market_evolution_timeline;

   // Quality
   double             entry_quality;
   double             execution_timing;
   double             break_even_timing;
   double             partial_close_timing;
   double             trailing_performance;
   double             recovery_efficiency;
   double             risk_efficiency;
   double             trade_quality_score;
   ENUM_GM_ES_GRADE   trade_quality_grade;
   double             execution_rating;
   string             quality_report;

   // Alerts
   int                alert_count;
   string             alerts[GM_ES_ALERT_MAX];
   string             alert_center;
   string             latest_alert;

   // Decision / environment detail
   string             decision_report;
   string             environment_report;
   string             supervisor_report;

   // Summary
   string             ai_supervisor_status;
   string             ai_supervisor_summary;
   string             center_status;
   string             advisory_status;
   string             insight;
   bool               may_execute;
   bool               may_modify_risk;
   bool               from_cache;
   bool               valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = "";
      session_id = 0;
      status = GM_ES_STATUS_IDLE;
      pending_orders = active_trades = buy_open = sell_open = 0;
      total_trades = recovery_trades = 0;
      floating_profit = floating_loss = spread_points = atr14 = 0.0;
      lifecycle_stage = GM_ES_STAGE_IDLE;
      lifecycle_status = "Idle";
      execution_timeline = recovery_timeline = lifecycle_report = "";
      trade_duration_sec = 0.0;
      lifecycle_events = 0;
      execution_health_score = decision_stability_score = environment_stability_score = 0.0;
      market_evolution_timeline = "";
      entry_quality = execution_timing = break_even_timing = 0.0;
      partial_close_timing = trailing_performance = recovery_efficiency = 0.0;
      risk_efficiency = trade_quality_score = execution_rating = 0.0;
      trade_quality_grade = GM_ES_GRADE_UNKNOWN;
      quality_report = "";
      alert_count = 0;
      for(int i = 0; i < GM_ES_ALERT_MAX; i++)
         alerts[i] = "";
      alert_center = "None";
      latest_alert = "";
      decision_report = environment_report = supervisor_report = "";
      ai_supervisor_status = "Idle";
      ai_supervisor_summary = "";
      center_status = "Idle";
      advisory_status = GM_ES_ADVISORY;
      insight = "";
      may_execute = false;
      may_modify_risk = false;
      from_cache = false;
      valid = false;
     }
  };

#endif // GM_SGM_EXECUTION_SUPERVISOR_RESULT_MQH
//+------------------------------------------------------------------+
