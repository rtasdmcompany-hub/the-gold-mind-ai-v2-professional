//+------------------------------------------------------------------+
//|                                 OrchestrationAIConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 4 Sprint 9 — Knowledge Orchestration & Decision Support|
//|     COLLECT / CONNECT / UNDERSTAND / EXPLAIN / SUPPORT — NEVER acts|
//+------------------------------------------------------------------+
#ifndef GM_ORCHESTRATION_AI_CONSTANTS_MQH
#define GM_ORCHESTRATION_AI_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_ORCH_VERSION            "1.0.0-orchestration"
#define GM_ORCH_DB_PREFIX          "GM_AI_ORCH_"
#define GM_ORCH_THROTTLE_MS        3600
#define GM_ORCH_HIST_MAX           64
#define GM_ORCH_CACHE_TTL_MS       7200
#define GM_ORCH_PRIORITY_MAX       8
#define GM_ORCH_GRAPH_NODES        24
#define GM_ORCH_GRAPH_EDGES        36
#define GM_ORCH_ANALYSIS_ONLY      "ORCHESTRATION SUPPORT ONLY"
#define GM_ORCH_ADVISORY           "ADVISORY ONLY — NO EXECUTION"

enum ENUM_GM_ORCH_STATUS
  {
   GM_ORCH_STATUS_IDLE = 0,
   GM_ORCH_STATUS_RUNNING,
   GM_ORCH_STATUS_READY,
   GM_ORCH_STATUS_CACHED,
   GM_ORCH_STATUS_ERROR
  };

enum ENUM_GM_ORCH_GRADE
  {
   GM_ORCH_GRADE_UNKNOWN = 0,
   GM_ORCH_GRADE_A_PLUS,
   GM_ORCH_GRADE_A,
   GM_ORCH_GRADE_B,
   GM_ORCH_GRADE_C,
   GM_ORCH_GRADE_D
  };

string GmOrchStatusName(const ENUM_GM_ORCH_STATUS s)
  {
   switch(s)
     {
      case GM_ORCH_STATUS_RUNNING: return "Running";
      case GM_ORCH_STATUS_READY:   return "Ready";
      case GM_ORCH_STATUS_CACHED:  return "Cached";
      case GM_ORCH_STATUS_ERROR:   return "Error";
     }
   return "Idle";
  }

string GmOrchGradeName(const ENUM_GM_ORCH_GRADE g)
  {
   switch(g)
     {
      case GM_ORCH_GRADE_A_PLUS: return "A+";
      case GM_ORCH_GRADE_A:      return "A";
      case GM_ORCH_GRADE_B:      return "B";
      case GM_ORCH_GRADE_C:      return "C";
      case GM_ORCH_GRADE_D:      return "D";
     }
   return "—";
  }

double GmOrchClamp(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

#endif // GM_ORCHESTRATION_AI_CONSTANTS_MQH
//+------------------------------------------------------------------+
