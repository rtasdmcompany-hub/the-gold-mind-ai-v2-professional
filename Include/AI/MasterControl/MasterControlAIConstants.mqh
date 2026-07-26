//+------------------------------------------------------------------+
//|                                  MasterControlAIConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 4 Sprint 10 — Master Control Center & Phase 4 Closure |
//|     MONITOR / ANALYZE / ORGANIZE / EXPLAIN / REPORT — READ-ONLY |
//+------------------------------------------------------------------+
#ifndef GM_MASTER_CONTROL_AI_CONSTANTS_MQH
#define GM_MASTER_CONTROL_AI_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_MCC_VERSION             "1.0.0-mastercontrol"
#define GM_MCC_DB_PREFIX           "GM_AI_MCC_"
#define GM_MCC_THROTTLE_MS         4000
#define GM_MCC_HIST_MAX            48
#define GM_MCC_CACHE_TTL_MS        8000
#define GM_MCC_ANALYSIS_ONLY       "MASTER CONTROL READ-ONLY"
#define GM_MCC_ADVISORY            "ADVISORY ONLY — NO EXECUTION"
#define GM_PHASE4_COMPLETE_LABEL   "PHASE4_ENTERPRISE_AI_COMPLETE"
#define GM_PHASE4_RC_LABEL         "Enterprise-AI-Phase4-Release"

enum ENUM_GM_MCC_STATUS
  {
   GM_MCC_STATUS_IDLE = 0,
   GM_MCC_STATUS_RUNNING,
   GM_MCC_STATUS_READY,
   GM_MCC_STATUS_CACHED,
   GM_MCC_STATUS_ERROR
  };

enum ENUM_GM_MCC_GRADE
  {
   GM_MCC_GRADE_UNKNOWN = 0,
   GM_MCC_GRADE_A_PLUS,
   GM_MCC_GRADE_A,
   GM_MCC_GRADE_B,
   GM_MCC_GRADE_C
  };

string GmMccStatusName(const ENUM_GM_MCC_STATUS s)
  {
   switch(s)
     {
      case GM_MCC_STATUS_RUNNING: return "Running";
      case GM_MCC_STATUS_READY:   return "Ready";
      case GM_MCC_STATUS_CACHED:  return "Cached";
      case GM_MCC_STATUS_ERROR:   return "Error";
     }
   return "Idle";
  }

string GmMccGradeName(const ENUM_GM_MCC_GRADE g)
  {
   switch(g)
     {
      case GM_MCC_GRADE_A_PLUS: return "A+";
      case GM_MCC_GRADE_A:      return "A";
      case GM_MCC_GRADE_B:      return "B";
      case GM_MCC_GRADE_C:      return "C";
     }
   return "—";
  }

double GmMccClamp(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

#endif // GM_MASTER_CONTROL_AI_CONSTANTS_MQH
//+------------------------------------------------------------------+
