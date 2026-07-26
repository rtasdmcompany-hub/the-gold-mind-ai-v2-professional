//+------------------------------------------------------------------+
//|                                     SGmRemoteMonitorResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_REMOTE_MONITOR_RESULT_MQH
#define GM_SGM_REMOTE_MONITOR_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "RemoteMonitorConstants.mqh"

struct SGmRemoteMonitorResult
  {
   datetime           stamped_at;
   ENUM_GM_RM_STATUS  status;

   // Observed component status (strings only)
   string             ea_status;
   string             chart_status;
   string             trading_engine_status;
   string             ai_status;
   string             cloud_status;
   string             database_status;
   string             connection_status;
   string             license_status;
   string             heartbeat_status;

   // Health metrics
   double             cpu_usage_pct;
   double             ram_usage_pct;
   double             terminal_performance;
   double             chart_refresh_score;
   double             tick_processing_score;
   double             order_processing_score;
   double             database_health;
   double             cloud_latency_ms;
   double             ai_processing_score;
   double             network_quality;
   double             system_stability;
   double             overall_health_score;

   // Telemetry
   string             telemetry_status;
   string             sync_status;
   int                telemetry_samples;
   string             encrypted_telemetry_hash;

   // Events / recovery
   string             latest_event;
   int                event_count;
   int                recovery_actions;
   string             recovery_log;

   string             center_status;
   string             enterprise_status;
   string             insight;
   bool               may_execute;
   bool               may_modify_risk;
   bool               valid;

   void Reset(void)
     {
      stamped_at = 0;
      status = GM_RM_STATUS_IDLE;
      ea_status = chart_status = trading_engine_status = "—";
      ai_status = cloud_status = database_status = "—";
      connection_status = license_status = heartbeat_status = "—";
      cpu_usage_pct = ram_usage_pct = 0.0;
      terminal_performance = chart_refresh_score = 0.0;
      tick_processing_score = order_processing_score = 0.0;
      database_health = cloud_latency_ms = ai_processing_score = 0.0;
      network_quality = system_stability = overall_health_score = 0.0;
      telemetry_status = "Idle";
      sync_status = "—";
      telemetry_samples = 0;
      encrypted_telemetry_hash = "";
      latest_event = "";
      event_count = recovery_actions = 0;
      recovery_log = "";
      center_status = "Idle";
      enterprise_status = "Monitor Only";
      insight = "";
      may_execute = false;
      may_modify_risk = false;
      valid = false;
     }
  };

#endif // GM_SGM_REMOTE_MONITOR_RESULT_MQH
//+------------------------------------------------------------------+
