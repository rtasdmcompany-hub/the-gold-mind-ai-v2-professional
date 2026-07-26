//+------------------------------------------------------------------+
//|                                   CommandCenterConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 7 Sprint 9 — Command Center / Ops Room / Executive    |
//|     MONITORING ONLY — NEVER interferes with trading             |
//+------------------------------------------------------------------+
#ifndef GM_COMMAND_CENTER_CONSTANTS_MQH
#define GM_COMMAND_CENTER_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_EOC_VERSION              "1.0.0-enterprise-command-center"
#define GM_EOC_DB_PREFIX            "GM_EOC_"
#define GM_EOC_THROTTLE_MS          15000
#define GM_EOC_POLICY               "COMMAND CENTER MONITORING ONLY — NO TRADING / NO REMOTE COMMANDS"
#define GM_EOC_SAFE                 "LICENSED GOLD MIND AI INSTALLATIONS — READ-ONLY OPS VIEW"

enum ENUM_GM_EOC_QUEUE
  {
   GM_EOC_Q_IDLE = 0,
   GM_EOC_Q_PENDING,
   GM_EOC_Q_RUNNING,
   GM_EOC_Q_CACHED,
   GM_EOC_Q_EXPORTED
  };

enum ENUM_GM_EOC_ALERT
  {
   GM_EOC_ALERT_INFO = 0,
   GM_EOC_ALERT_WARNING,
   GM_EOC_ALERT_CRITICAL,
   GM_EOC_ALERT_LICENSE,
   GM_EOC_ALERT_CLOUD,
   GM_EOC_ALERT_DATABASE,
   GM_EOC_ALERT_INFRA,
   GM_EOC_ALERT_PERF,
   GM_EOC_ALERT_SECURITY
  };

string GmEocQueueName(const ENUM_GM_EOC_QUEUE q)
  {
   switch(q)
     {
      case GM_EOC_Q_PENDING:  return "Pending";
      case GM_EOC_Q_RUNNING:  return "Running";
      case GM_EOC_Q_CACHED:   return "Cached";
      case GM_EOC_Q_EXPORTED: return "Exported";
     }
   return "Idle";
  }

string GmEocAlertName(const ENUM_GM_EOC_ALERT a)
  {
   switch(a)
     {
      case GM_EOC_ALERT_WARNING:  return "Warning";
      case GM_EOC_ALERT_CRITICAL: return "Critical";
      case GM_EOC_ALERT_LICENSE:  return "License";
      case GM_EOC_ALERT_CLOUD:    return "Cloud";
      case GM_EOC_ALERT_DATABASE: return "Database";
      case GM_EOC_ALERT_INFRA:    return "Infrastructure";
      case GM_EOC_ALERT_PERF:     return "Performance";
      case GM_EOC_ALERT_SECURITY: return "Security";
     }
   return "Information";
  }

#endif // GM_COMMAND_CENTER_CONSTANTS_MQH
//+------------------------------------------------------------------+
