//+------------------------------------------------------------------+
//|                                   RemoteMonitorConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 6 Sprint 2 — Remote Management / Telemetry / Health   |
//|     MONITOR ONLY — NEVER controls trades                        |
//+------------------------------------------------------------------+
#ifndef GM_REMOTE_MONITOR_CONSTANTS_MQH
#define GM_REMOTE_MONITOR_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_RM_VERSION              "1.0.0-remote-monitor"
#define GM_RM_DB_PREFIX            "GM_CLOUD_RM_"
#define GM_RM_THROTTLE_MS          12000
#define GM_RM_HIST_MAX             64
#define GM_RM_EVENT_MAX            48
#define GM_RM_POLICY               "REMOTE MONITOR ONLY — NO TRADING AUTHORITY"
#define GM_RM_SAFE                 "BACKGROUND MONITORING — TRADING NEVER INTERRUPTED"

enum ENUM_GM_RM_STATUS
  {
   GM_RM_STATUS_IDLE = 0,
   GM_RM_STATUS_RUNNING,
   GM_RM_STATUS_READY,
   GM_RM_STATUS_DEGRADED,
   GM_RM_STATUS_ERROR
  };

enum ENUM_GM_RM_EVENT
  {
   GM_RM_EVT_NONE = 0,
   GM_RM_EVT_EA_STARTED,
   GM_RM_EVT_EA_STOPPED,
   GM_RM_EVT_TRADING_READY,
   GM_RM_EVT_CLOUD_CONNECTED,
   GM_RM_EVT_CLOUD_DISCONNECTED,
   GM_RM_EVT_LICENSE_UPDATED,
   GM_RM_EVT_HIGH_CPU,
   GM_RM_EVT_HIGH_RAM,
   GM_RM_EVT_DATABASE_ERROR,
   GM_RM_EVT_NETWORK_RECOVERY,
   GM_RM_EVT_HEALTH_UPDATED,
   GM_RM_EVT_TELEMETRY,
   GM_RM_EVT_RECOVERY,
   GM_RM_EVT_HEARTBEAT
  };

string GmRmStatusName(const ENUM_GM_RM_STATUS s)
  {
   switch(s)
     {
      case GM_RM_STATUS_RUNNING:  return "Running";
      case GM_RM_STATUS_READY:    return "Ready";
      case GM_RM_STATUS_DEGRADED: return "Degraded";
      case GM_RM_STATUS_ERROR:    return "Error";
     }
   return "Idle";
  }

string GmRmEventName(const ENUM_GM_RM_EVENT e)
  {
   switch(e)
     {
      case GM_RM_EVT_EA_STARTED:          return "EA Started";
      case GM_RM_EVT_EA_STOPPED:          return "EA Stopped";
      case GM_RM_EVT_TRADING_READY:       return "Trading Engine Ready";
      case GM_RM_EVT_CLOUD_CONNECTED:     return "Cloud Connected";
      case GM_RM_EVT_CLOUD_DISCONNECTED:  return "Cloud Disconnected";
      case GM_RM_EVT_LICENSE_UPDATED:     return "License Updated";
      case GM_RM_EVT_HIGH_CPU:            return "High CPU";
      case GM_RM_EVT_HIGH_RAM:            return "High RAM";
      case GM_RM_EVT_DATABASE_ERROR:      return "Database Error";
      case GM_RM_EVT_NETWORK_RECOVERY:    return "Network Recovery";
      case GM_RM_EVT_HEALTH_UPDATED:      return "Health Updated";
      case GM_RM_EVT_TELEMETRY:           return "Telemetry Uploaded";
      case GM_RM_EVT_RECOVERY:            return "Recovery Completed";
      case GM_RM_EVT_HEARTBEAT:           return "Heartbeat Successful";
     }
   return "None";
  }

double GmRmClamp(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

#endif // GM_REMOTE_MONITOR_CONSTANTS_MQH
//+------------------------------------------------------------------+
