//+------------------------------------------------------------------+
//|                                InfrastructureConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 6 Sprint 4 — VPS / Multi-Terminal / Control Center    |
//|     MONITOR ONLY — NEVER executes trades remotely               |
//+------------------------------------------------------------------+
#ifndef GM_INFRASTRUCTURE_CONSTANTS_MQH
#define GM_INFRASTRUCTURE_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_EIF_VERSION              "1.0.0-enterprise-infrastructure"
#define GM_EIF_DB_PREFIX            "GM_CLOUD_EIF_"
#define GM_EIF_THROTTLE_MS          12000
#define GM_EIF_DEVICE_MAX           16
#define GM_EIF_HIST_MAX             48
#define GM_EIF_POLICY               "INFRASTRUCTURE MONITOR ONLY — NO REMOTE TRADING AUTHORITY"
#define GM_EIF_SAFE                 "ASYNC BACKGROUND — TRADING NEVER INTERRUPTED"

enum ENUM_GM_EIF_DEVICE_GROUP
  {
   GM_EIF_GROUP_PERSONAL = 0,
   GM_EIF_GROUP_OFFICE,
   GM_EIF_GROUP_VPS,
   GM_EIF_GROUP_TESTING,
   GM_EIF_GROUP_PRODUCTION,
   GM_EIF_GROUP_CUSTOM
  };

enum ENUM_GM_EIF_DEVICE_STATE
  {
   GM_EIF_DEV_UNKNOWN = 0,
   GM_EIF_DEV_ONLINE,
   GM_EIF_DEV_OFFLINE,
   GM_EIF_DEV_DEGRADED,
   GM_EIF_DEV_UNAUTHORIZED
  };

enum ENUM_GM_EIF_SYNC_STATE
  {
   GM_EIF_SYNC_IDLE = 0,
   GM_EIF_SYNC_RUNNING,
   GM_EIF_SYNC_OK,
   GM_EIF_SYNC_DEGRADED,
   GM_EIF_SYNC_FAILED
  };

string GmEifGroupName(const ENUM_GM_EIF_DEVICE_GROUP g)
  {
   switch(g)
     {
      case GM_EIF_GROUP_PERSONAL:    return "Personal";
      case GM_EIF_GROUP_OFFICE:      return "Office";
      case GM_EIF_GROUP_VPS:         return "VPS";
      case GM_EIF_GROUP_TESTING:     return "Testing";
      case GM_EIF_GROUP_PRODUCTION:  return "Production";
      case GM_EIF_GROUP_CUSTOM:      return "Custom";
     }
   return "Custom";
  }

string GmEifDeviceStateName(const ENUM_GM_EIF_DEVICE_STATE s)
  {
   switch(s)
     {
      case GM_EIF_DEV_ONLINE:        return "Online";
      case GM_EIF_DEV_OFFLINE:       return "Offline";
      case GM_EIF_DEV_DEGRADED:      return "Degraded";
      case GM_EIF_DEV_UNAUTHORIZED:  return "Unauthorized";
     }
   return "Unknown";
  }

string GmEifSyncStateName(const ENUM_GM_EIF_SYNC_STATE s)
  {
   switch(s)
     {
      case GM_EIF_SYNC_RUNNING:  return "Running";
      case GM_EIF_SYNC_OK:       return "OK";
      case GM_EIF_SYNC_DEGRADED: return "Degraded";
      case GM_EIF_SYNC_FAILED:   return "Failed";
     }
   return "Idle";
  }

#endif // GM_INFRASTRUCTURE_CONSTANTS_MQH
//+------------------------------------------------------------------+
