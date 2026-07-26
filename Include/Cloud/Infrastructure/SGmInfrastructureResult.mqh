//+------------------------------------------------------------------+
//|                               SGmInfrastructureResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_INFRASTRUCTURE_RESULT_MQH
#define GM_SGM_INFRASTRUCTURE_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "InfrastructureConstants.mqh"

struct SGmEifTerminalRecord
  {
   string                   terminal_name;
   string                   device_name;
   string                   broker;
   long                     account_number;
   string                   account_type;
   string                   server;
   string                   ea_version;
   string                   license_type;
   string                   running_status;
   string                   connection_quality;
   datetime                 last_heartbeat;
   ENUM_GM_EIF_DEVICE_GROUP group;
   ENUM_GM_EIF_DEVICE_STATE state;
   bool                     is_vps;
   bool                     trusted;
   string                   device_token_hash;

   void Reset(void)
     {
      terminal_name = device_name = broker = "";
      account_number = 0;
      account_type = server = ea_version = license_type = "";
      running_status = connection_quality = "";
      last_heartbeat = 0;
      group = GM_EIF_GROUP_PRODUCTION;
      state = GM_EIF_DEV_UNKNOWN;
      is_vps = false;
      trusted = false;
      device_token_hash = "";
     }
  };

struct SGmInfrastructureResult
  {
   datetime              stamped_at;
   ENUM_GM_EIF_SYNC_STATE sync_state;

   int                   connected_devices;
   int                   online_devices;
   int                   offline_devices;
   int                   online_vps;
   int                   offline_vps;
   int                   online_terminals;
   int                   offline_terminals;

   double                vps_cpu_pct;
   double                vps_ram_pct;
   double                vps_disk_pct;
   double                network_latency_ms;
   double                internet_stability;
   double                avg_latency_ms;
   double                avg_cpu_pct;
   double                avg_ram_pct;
   double                cloud_health;
   double                license_health;
   double                sync_health;
   double                infra_health;
   double                enterprise_score;

   int                   sync_queue_depth;
   int                   notification_queue_depth;

   string                vps_online_status;
   string                mt5_terminal_status;
   string                ea_running_status;
   string                cloud_connection;
   string                synchronization_status;
   string                heartbeat_status;
   string                group_filter;
   string                search_query;
   string                device_summary;
   string                enterprise_status;
   string                center_status;
   string                insight;
   bool                  may_execute;
   bool                  may_modify_risk;
   bool                  valid;

   void Reset(void)
     {
      stamped_at = 0;
      sync_state = GM_EIF_SYNC_IDLE;
      connected_devices = online_devices = offline_devices = 0;
      online_vps = offline_vps = online_terminals = offline_terminals = 0;
      vps_cpu_pct = vps_ram_pct = vps_disk_pct = 0.0;
      network_latency_ms = internet_stability = 0.0;
      avg_latency_ms = avg_cpu_pct = avg_ram_pct = 0.0;
      cloud_health = license_health = sync_health = infra_health = enterprise_score = 0.0;
      sync_queue_depth = notification_queue_depth = 0;
      vps_online_status = mt5_terminal_status = ea_running_status = "";
      cloud_connection = synchronization_status = heartbeat_status = "";
      group_filter = "All";
      search_query = "";
      device_summary = "";
      enterprise_status = center_status = insight = "";
      may_execute = false;
      may_modify_risk = false;
      valid = false;
     }
  };

#endif // GM_SGM_INFRASTRUCTURE_RESULT_MQH
//+------------------------------------------------------------------+
