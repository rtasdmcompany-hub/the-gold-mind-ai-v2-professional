//+------------------------------------------------------------------+
//|                           ExecutionSupervisorConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 5 Sprint 8 — Execution Supervisor / Lifecycle / Alerts|
//|     OBSERVE / VALIDATE / AUDIT ONLY — NEVER executes            |
//+------------------------------------------------------------------+
#ifndef GM_EXECUTION_SUPERVISOR_CONSTANTS_MQH
#define GM_EXECUTION_SUPERVISOR_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_ES_VERSION              "1.0.0-execution-supervisor"
#define GM_ES_DB_PREFIX            "GM_AI_ES_"
#define GM_ES_THROTTLE_MS          2800
#define GM_ES_HIST_MAX             64
#define GM_ES_CACHE_TTL_MS         5600
#define GM_ES_ALERT_MAX            8
#define GM_ES_ANALYSIS_ONLY        "EXECUTION SUPERVISOR OBSERVATION ONLY"
#define GM_ES_ADVISORY             "ADVISORY ONLY — NO EXECUTION / NO ORDER MODIFICATION"
#define GM_ES_CONTEXT              "H4 Close | 3Buy/3Sell | Pending→Active | ATR-14 TP | 30pip SL | BE | 80% Partial | 20% Trail | Second Attempt | Recovery"

enum ENUM_GM_ES_STATUS
  {
   GM_ES_STATUS_IDLE = 0,
   GM_ES_STATUS_RUNNING,
   GM_ES_STATUS_READY,
   GM_ES_STATUS_CACHED,
   GM_ES_STATUS_ERROR
  };

enum ENUM_GM_ES_STAGE
  {
   GM_ES_STAGE_IDLE = 0,
   GM_ES_STAGE_SIGNAL,
   GM_ES_STAGE_PENDING,
   GM_ES_STAGE_ACTIVATED,
   GM_ES_STAGE_IN_PROFIT,
   GM_ES_STAGE_BREAK_EVEN,
   GM_ES_STAGE_PARTIAL,
   GM_ES_STAGE_TRAILING,
   GM_ES_STAGE_RECOVERY,
   GM_ES_STAGE_CLOSED
  };

enum ENUM_GM_ES_GRADE
  {
   GM_ES_GRADE_UNKNOWN = 0,
   GM_ES_GRADE_A,
   GM_ES_GRADE_B,
   GM_ES_GRADE_C,
   GM_ES_GRADE_D,
   GM_ES_GRADE_F
  };

string GmEsStatusName(const ENUM_GM_ES_STATUS s)
  {
   switch(s)
     {
      case GM_ES_STATUS_RUNNING: return "Running";
      case GM_ES_STATUS_READY:   return "Ready";
      case GM_ES_STATUS_CACHED:  return "Cached";
      case GM_ES_STATUS_ERROR:   return "Error";
     }
   return "Idle";
  }

string GmEsStageName(const ENUM_GM_ES_STAGE s)
  {
   switch(s)
     {
      case GM_ES_STAGE_SIGNAL:     return "Signal Created";
      case GM_ES_STAGE_PENDING:    return "Pending Order Created";
      case GM_ES_STAGE_ACTIVATED:  return "Order Activated";
      case GM_ES_STAGE_IN_PROFIT:  return "Trade In Profit";
      case GM_ES_STAGE_BREAK_EVEN: return "Break Even Activated";
      case GM_ES_STAGE_PARTIAL:    return "80% Partial Close";
      case GM_ES_STAGE_TRAILING:   return "20% Trailing Active";
      case GM_ES_STAGE_RECOVERY:   return "Recovery Triggered";
      case GM_ES_STAGE_CLOSED:     return "Trade Closed";
     }
   return "Idle";
  }

string GmEsGradeName(const ENUM_GM_ES_GRADE g)
  {
   switch(g)
     {
      case GM_ES_GRADE_A: return "A";
      case GM_ES_GRADE_B: return "B";
      case GM_ES_GRADE_C: return "C";
      case GM_ES_GRADE_D: return "D";
      case GM_ES_GRADE_F: return "F";
     }
   return "—";
  }

double GmEsClamp(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

ENUM_GM_ES_GRADE GmEsGradeFromScore(const double score)
  {
   if(score >= 85.0) return GM_ES_GRADE_A;
   if(score >= 70.0) return GM_ES_GRADE_B;
   if(score >= 55.0) return GM_ES_GRADE_C;
   if(score >= 40.0) return GM_ES_GRADE_D;
   if(score > 0.0)   return GM_ES_GRADE_F;
   return GM_ES_GRADE_UNKNOWN;
  }

#endif // GM_EXECUTION_SUPERVISOR_CONSTANTS_MQH
//+------------------------------------------------------------------+
