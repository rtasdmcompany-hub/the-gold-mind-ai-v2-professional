//+------------------------------------------------------------------+
//|                                            SGmCloudStatus.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_CLOUD_STATUS_MQH
#define GM_SGM_CLOUD_STATUS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CloudConstants.mqh"

struct SGmCloudStatus
  {
   datetime              stamped_at;
   ENUM_GM_CLOUD_STATUS  cloud_status;
   ENUM_GM_LICENSE_TIER  license_tier;
   string                license_status;
   string                server_endpoint;
   string                server_connection;
   bool                  offline_mode;
   bool                  heartbeat_ok;
   datetime              last_heartbeat_at;
   datetime              last_sync_at;
   int                   sync_queue_depth;
   int                   latency_ms;
   string                ea_version;
   string                cloud_version;
   string                device_id_hash;
   string                session_token_hash;
   string                insight;
   string                center_status;
   bool                  may_execute;       // ALWAYS false
   bool                  may_modify_risk;   // ALWAYS false
   bool                  valid;

   void Reset(void)
     {
      stamped_at = 0;
      cloud_status = GM_CLOUD_STATUS_IDLE;
      license_tier = GM_LICENSE_PROFESSIONAL;
      license_status = "Architecture Only";
      server_endpoint = "";
      server_connection = "Disconnected";
      offline_mode = true;
      heartbeat_ok = false;
      last_heartbeat_at = 0;
      last_sync_at = 0;
      sync_queue_depth = 0;
      latency_ms = 0;
      ea_version = "";
      cloud_version = GM_CLOUD_VERSION;
      device_id_hash = "";
      session_token_hash = "";
      insight = "";
      center_status = "Idle";
      may_execute = false;
      may_modify_risk = false;
      valid = false;
     }
  };

#endif // GM_SGM_CLOUD_STATUS_MQH
//+------------------------------------------------------------------+
