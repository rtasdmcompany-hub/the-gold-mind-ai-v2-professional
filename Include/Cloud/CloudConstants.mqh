//+------------------------------------------------------------------+
//|                                          CloudConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 6 Sprint 1 — Enterprise Cloud Foundation              |
//|     INDEPENDENT of Trading Engine — NEVER executes trades       |
//+------------------------------------------------------------------+
#ifndef GM_CLOUD_CONSTANTS_MQH
#define GM_CLOUD_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_CLOUD_VERSION              "1.0.0-cloud-foundation"
#define GM_CLOUD_DB_PREFIX            "GM_CLOUD_"
#define GM_CLOUD_THROTTLE_MS          15000
#define GM_CLOUD_HEARTBEAT_MS         30000
#define GM_CLOUD_RETRY_MS             45000
#define GM_CLOUD_HIST_MAX             48
#define GM_CLOUD_SYNC_QUEUE_MAX       32
#define GM_CLOUD_POLICY               "CLOUD SERVICE ONLY — NO TRADING AUTHORITY"
#define GM_CLOUD_OFFLINE_SAFE         "OFFLINE SAFE — TRADING CONTINUES WITHOUT CLOUD"

enum ENUM_GM_CLOUD_STATUS
  {
   GM_CLOUD_STATUS_IDLE = 0,
   GM_CLOUD_STATUS_DISCOVERING,
   GM_CLOUD_STATUS_CONNECTING,
   GM_CLOUD_STATUS_ONLINE,
   GM_CLOUD_STATUS_OFFLINE,
   GM_CLOUD_STATUS_DEGRADED,
   GM_CLOUD_STATUS_ERROR
  };

enum ENUM_GM_LICENSE_TIER
  {
   GM_LICENSE_TRIAL = 0,
   GM_LICENSE_PROFESSIONAL,
   GM_LICENSE_ENTERPRISE,
   GM_LICENSE_INSTITUTIONAL,
   GM_LICENSE_DEVELOPER,
   GM_LICENSE_DEMO,
   GM_LICENSE_EXPIRED,
   GM_LICENSE_DISABLED,
   GM_LICENSE_GRACE
  };

string GmCloudStatusName(const ENUM_GM_CLOUD_STATUS s)
  {
   switch(s)
     {
      case GM_CLOUD_STATUS_DISCOVERING: return "Discovering";
      case GM_CLOUD_STATUS_CONNECTING:  return "Connecting";
      case GM_CLOUD_STATUS_ONLINE:      return "Online";
      case GM_CLOUD_STATUS_OFFLINE:     return "Offline";
      case GM_CLOUD_STATUS_DEGRADED:    return "Degraded";
      case GM_CLOUD_STATUS_ERROR:       return "Error";
     }
   return "Idle";
  }

string GmLicenseTierName(const ENUM_GM_LICENSE_TIER t)
  {
   switch(t)
     {
      case GM_LICENSE_TRIAL:          return "Trial";
      case GM_LICENSE_PROFESSIONAL:   return "Professional";
      case GM_LICENSE_ENTERPRISE:     return "Enterprise";
      case GM_LICENSE_INSTITUTIONAL:  return "Institutional";
      case GM_LICENSE_DEVELOPER:      return "Developer";
      case GM_LICENSE_DEMO:           return "Demo";
      case GM_LICENSE_EXPIRED:        return "Expired";
      case GM_LICENSE_DISABLED:       return "Disabled";
      case GM_LICENSE_GRACE:          return "Grace Period";
     }
   return "Unknown";
  }

#endif // GM_CLOUD_CONSTANTS_MQH
//+------------------------------------------------------------------+
