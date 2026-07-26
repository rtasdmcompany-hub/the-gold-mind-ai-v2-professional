//+------------------------------------------------------------------+
//|                               MultiAccountCenterConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 7 Sprint 8 — Multi-Account / Clusters / Capital       |
//|     MONITORING ONLY — NEVER places or modifies trades           |
//+------------------------------------------------------------------+
#ifndef GM_MULTI_ACCOUNT_CENTER_CONSTANTS_MQH
#define GM_MULTI_ACCOUNT_CENTER_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_MAC_VERSION              "1.0.0-enterprise-multi-account-center"
#define GM_MAC_DB_PREFIX            "GM_MAC_"
#define GM_MAC_THROTTLE_MS          30000
#define GM_MAC_POLICY               "MULTI-ACCOUNT MONITORING ONLY — NO TRADING AUTHORITY"
#define GM_MAC_SAFE                 "LICENSED GOLD MIND AI ACCOUNTS ONLY — UNLICENSED EXCLUDED"
#define GM_MAC_LICENSE_MIN_HEALTH   50.0
#define GM_MAC_MAX_REGISTRY         64

enum ENUM_GM_MAC_QUEUE
  {
   GM_MAC_Q_IDLE = 0,
   GM_MAC_Q_PENDING,
   GM_MAC_Q_RUNNING,
   GM_MAC_Q_CACHED,
   GM_MAC_Q_EXPORTED
  };

enum ENUM_GM_MAC_CLUSTER
  {
   GM_MAC_CL_PERSONAL = 0,
   GM_MAC_CL_FUNDED,
   GM_MAC_CL_INVESTOR,
   GM_MAC_CL_CLIENT,
   GM_MAC_CL_TESTING,
   GM_MAC_CL_PRODUCTION,
   GM_MAC_CL_CUSTOM
  };

enum ENUM_GM_MAC_CONN
  {
   GM_MAC_CONN_OFFLINE = 0,
   GM_MAC_CONN_DISCONNECTED,
   GM_MAC_CONN_CONNECTED,
   GM_MAC_CONN_WARNING
  };

enum ENUM_GM_MAC_ACCT_TYPE
  {
   GM_MAC_AT_DEMO = 0,
   GM_MAC_AT_LIVE
  };

string GmMacQueueName(const ENUM_GM_MAC_QUEUE q)
  {
   switch(q)
     {
      case GM_MAC_Q_PENDING:  return "Pending";
      case GM_MAC_Q_RUNNING:  return "Running";
      case GM_MAC_Q_CACHED:   return "Cached";
      case GM_MAC_Q_EXPORTED: return "Exported";
     }
   return "Idle";
  }

string GmMacClusterName(const ENUM_GM_MAC_CLUSTER c)
  {
   switch(c)
     {
      case GM_MAC_CL_PERSONAL:   return "Personal";
      case GM_MAC_CL_FUNDED:     return "Funded";
      case GM_MAC_CL_INVESTOR:   return "Investor";
      case GM_MAC_CL_CLIENT:     return "Client";
      case GM_MAC_CL_TESTING:    return "Testing";
      case GM_MAC_CL_PRODUCTION: return "Production";
      case GM_MAC_CL_CUSTOM:     return "Custom";
     }
   return "Group";
  }

string GmMacConnName(const ENUM_GM_MAC_CONN c)
  {
   switch(c)
     {
      case GM_MAC_CONN_CONNECTED:    return "Connected";
      case GM_MAC_CONN_DISCONNECTED: return "Disconnected";
      case GM_MAC_CONN_WARNING:      return "Warning";
     }
   return "Offline";
  }

#endif // GM_MULTI_ACCOUNT_CENTER_CONSTANTS_MQH
//+------------------------------------------------------------------+
