//+------------------------------------------------------------------+
//|                                  SGmCommandCenterResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_COMMAND_CENTER_RESULT_MQH
#define GM_SGM_COMMAND_CENTER_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CommandCenterConstants.mqh"

struct SGmCommandCenterResult
  {
   datetime          stamped_at;
   ENUM_GM_EOC_QUEUE queue_status;

   double            enterprise_health;
   double            overall_performance;
   double            system_availability;
   double            infrastructure_health;

   int               connected_terminals;
   int               running_ai_instances;
   int               open_ai_trades;
   int               pending_orders;
   int               recovery_trades;
   int               breakeven_trades;
   int               trailing_trades;
   int               alert_count;
   int               critical_alerts;
   int               warning_alerts;

   string            enterprise_status;
   string            trading_engine_status;
   string            ai_engine_status;
   string            cloud_status;
   string            api_status;
   string            license_status;
   string            database_status;
   string            notify_status;
   string            backup_status;
   string            ops_room_summary;
   string            performance_wall;
   string            alert_center;
   string            executive_summary;
   string            daily_ops_summary;
   string            weekly_ops_summary;
   string            monthly_ops_summary;
   string            availability_report;
   string            security_status;
   string            audit_trail;
   string            export_status;
   string            center_status;
   string            insight;

   bool              may_execute;
   bool              may_modify_risk;
   bool              may_interrupt_trading;
   bool              may_remote_command;
   bool              valid;

   void Reset(void)
     {
      stamped_at = 0;
      queue_status = GM_EOC_Q_IDLE;
      enterprise_health = overall_performance = system_availability = infrastructure_health = 0.0;
      connected_terminals = running_ai_instances = open_ai_trades = pending_orders = 0;
      recovery_trades = breakeven_trades = trailing_trades = 0;
      alert_count = critical_alerts = warning_alerts = 0;
      enterprise_status = trading_engine_status = ai_engine_status = "";
      cloud_status = api_status = license_status = database_status = "";
      notify_status = backup_status = "";
      ops_room_summary = performance_wall = alert_center = "";
      executive_summary = daily_ops_summary = weekly_ops_summary = monthly_ops_summary = "";
      availability_report = security_status = audit_trail = "";
      export_status = "Architecture Ready";
      center_status = insight = "";
      may_execute = false;
      may_modify_risk = false;
      may_interrupt_trading = false;
      may_remote_command = false;
      valid = false;
     }
  };

#endif // GM_SGM_COMMAND_CENTER_RESULT_MQH
//+------------------------------------------------------------------+
