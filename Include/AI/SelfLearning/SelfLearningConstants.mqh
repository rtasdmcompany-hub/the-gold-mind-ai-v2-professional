//+------------------------------------------------------------------+
//|                              SelfLearningConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 5 Sprint 9 — Self-Learning / Knowledge Evolution      |
//|     LEARN / ANALYZE / RECOMMEND ONLY — NEVER mutates strategy   |
//+------------------------------------------------------------------+
#ifndef GM_SELF_LEARNING_CONSTANTS_MQH
#define GM_SELF_LEARNING_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_SL_VERSION              "1.0.0-self-learning"
#define GM_SL_DB_PREFIX            "GM_AI_SL_"
#define GM_SL_THROTTLE_MS          4500
#define GM_SL_HIST_MAX             64
#define GM_SL_CACHE_TTL_MS         9000
#define GM_SL_REC_MAX              6
#define GM_SL_PATTERN_MAX          8
#define GM_SL_ANALYSIS_ONLY        "SELF-LEARNING INTELLIGENCE ANALYSIS ONLY"
#define GM_SL_ADVISORY             "ADVISORY ONLY — NO STRATEGY / RISK / EXECUTION MUTATION"
#define GM_SL_CONTEXT              "H4 | 3Buy/3Sell | ATR-14 | 30pip SL | BE | 80% Partial | 20% Trail | Second Attempt | Recovery | News | Institutional"

enum ENUM_GM_SL_STATUS
  {
   GM_SL_STATUS_IDLE = 0,
   GM_SL_STATUS_RUNNING,
   GM_SL_STATUS_READY,
   GM_SL_STATUS_CACHED,
   GM_SL_STATUS_ERROR
  };

enum ENUM_GM_SL_CERT
  {
   GM_SL_CERT_UNKNOWN = 0,
   GM_SL_CERT_PROVISIONAL,
   GM_SL_CERT_VALIDATED,
   GM_SL_CERT_CERTIFIED,
   GM_SL_CERT_DEGRADED
  };

string GmSlStatusName(const ENUM_GM_SL_STATUS s)
  {
   switch(s)
     {
      case GM_SL_STATUS_RUNNING: return "Running";
      case GM_SL_STATUS_READY:   return "Ready";
      case GM_SL_STATUS_CACHED:  return "Cached";
      case GM_SL_STATUS_ERROR:   return "Error";
     }
   return "Idle";
  }

string GmSlCertName(const ENUM_GM_SL_CERT c)
  {
   switch(c)
     {
      case GM_SL_CERT_PROVISIONAL: return "Provisional";
      case GM_SL_CERT_VALIDATED:   return "Validated";
      case GM_SL_CERT_CERTIFIED:   return "Certified";
      case GM_SL_CERT_DEGRADED:    return "Degraded";
     }
   return "Unknown";
  }

double GmSlClamp(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

#endif // GM_SELF_LEARNING_CONSTANTS_MQH
//+------------------------------------------------------------------+
