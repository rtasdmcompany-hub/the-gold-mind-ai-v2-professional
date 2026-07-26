//+------------------------------------------------------------------+
//|                                     EnterpriseAIConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 4 Sprint 6 — Multi-Account & Cloud Monitoring         |
//|     MONITOR / COMPARE / REPORT / ADVISE — NEVER executes        |
//+------------------------------------------------------------------+
#ifndef GM_ENTERPRISE_AI_CONSTANTS_MQH
#define GM_ENTERPRISE_AI_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_ENT_VERSION            "1.0.0-enterprise"
#define GM_ENT_DB_PREFIX          "GM_AI_ENT_"
#define GM_ENT_THROTTLE_MS        3500
#define GM_ENT_HIST_MAX           64
#define GM_ENT_ACCT_MAX           16
#define GM_ENT_CACHE_TTL_MS       7000
#define GM_ENT_ANALYSIS_ONLY      "ENTERPRISE MONITORING ONLY"
#define GM_ENT_ADVISORY           "ADVISORY ONLY — NO REMOTE EXECUTION"

enum ENUM_GM_ENT_STATUS
  {
   GM_ENT_STATUS_IDLE = 0,
   GM_ENT_STATUS_RUNNING,
   GM_ENT_STATUS_READY,
   GM_ENT_STATUS_CACHED,
   GM_ENT_STATUS_ERROR
  };

enum ENUM_GM_ENT_ACCT_HEALTH
  {
   GM_ENT_ACCT_UNKNOWN = 0,
   GM_ENT_ACCT_HEALTHY,
   GM_ENT_ACCT_WARNING,
   GM_ENT_ACCT_CRITICAL
  };

enum ENUM_GM_ENT_RANK
  {
   GM_ENT_RANK_UNKNOWN = 0,
   GM_ENT_RANK_EXCELLENT,
   GM_ENT_RANK_STABLE,
   GM_ENT_RANK_MODERATE,
   GM_ENT_RANK_MONITOR
  };

string GmEntStatusName(const ENUM_GM_ENT_STATUS s)
  {
   switch(s)
     {
      case GM_ENT_STATUS_RUNNING: return "Running";
      case GM_ENT_STATUS_READY:   return "Ready";
      case GM_ENT_STATUS_CACHED:  return "Cached";
      case GM_ENT_STATUS_ERROR:   return "Error";
     }
   return "Idle";
  }

string GmEntAcctHealthName(const ENUM_GM_ENT_ACCT_HEALTH h)
  {
   switch(h)
     {
      case GM_ENT_ACCT_HEALTHY:  return "Healthy";
      case GM_ENT_ACCT_WARNING:  return "Warning";
      case GM_ENT_ACCT_CRITICAL: return "Critical";
     }
   return "Unknown";
  }

string GmEntRankName(const ENUM_GM_ENT_RANK r)
  {
   switch(r)
     {
      case GM_ENT_RANK_EXCELLENT: return "Excellent Stability";
      case GM_ENT_RANK_STABLE:    return "Stable";
      case GM_ENT_RANK_MODERATE:  return "Moderate Risk";
      case GM_ENT_RANK_MONITOR:   return "Requires Monitoring";
     }
   return "Unknown";
  }

double GmEntClamp(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

#endif // GM_ENTERPRISE_AI_CONSTANTS_MQH
//+------------------------------------------------------------------+
