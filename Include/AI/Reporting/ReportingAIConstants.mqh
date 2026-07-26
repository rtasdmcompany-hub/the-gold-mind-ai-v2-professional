//+------------------------------------------------------------------+
//|                                      ReportingAIConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 4 Sprint 4 — Enterprise AI Reporting & Analytics      |
//|     REPORT / EXPLAIN / ADVISE ONLY — NEVER executes or mutates  |
//+------------------------------------------------------------------+
#ifndef GM_REPORTING_AI_CONSTANTS_MQH
#define GM_REPORTING_AI_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_RPT_VERSION            "1.0.0-report"
#define GM_RPT_DB_PREFIX          "GM_AI_RPT_"
#define GM_RPT_THROTTLE_MS        3000
#define GM_RPT_HIST_MAX           96
#define GM_RPT_AUDIT_MAX          48
#define GM_RPT_CACHE_TTL_MS       6000
#define GM_RPT_ANALYSIS_ONLY      "REPORTING ONLY"
#define GM_RPT_ADVISORY           "ADVISORY ONLY — NO EXECUTION"

enum ENUM_GM_RPT_STATUS
  {
   GM_RPT_STATUS_IDLE = 0,
   GM_RPT_STATUS_RUNNING,
   GM_RPT_STATUS_READY,
   GM_RPT_STATUS_CACHED,
   GM_RPT_STATUS_ERROR
  };

enum ENUM_GM_RPT_TYPE
  {
   GM_RPT_TYPE_DAILY = 0,
   GM_RPT_TYPE_WEEKLY,
   GM_RPT_TYPE_MONTHLY,
   GM_RPT_TYPE_SESSION,
   GM_RPT_TYPE_RISK,
   GM_RPT_TYPE_PERFORMANCE,
   GM_RPT_TYPE_LEARNING,
   GM_RPT_TYPE_EXECUTIVE,
   GM_RPT_TYPE_ENTERPRISE,
   GM_RPT_TYPE_AUDIT
  };

enum ENUM_GM_RPT_GRADE
  {
   GM_RPT_GRADE_UNKNOWN = 0,
   GM_RPT_GRADE_A_PLUS,
   GM_RPT_GRADE_A,
   GM_RPT_GRADE_B,
   GM_RPT_GRADE_C,
   GM_RPT_GRADE_D,
   GM_RPT_GRADE_F
  };

string GmRptStatusName(const ENUM_GM_RPT_STATUS s)
  {
   switch(s)
     {
      case GM_RPT_STATUS_RUNNING: return "Running";
      case GM_RPT_STATUS_READY:   return "Ready";
      case GM_RPT_STATUS_CACHED:  return "Cached";
      case GM_RPT_STATUS_ERROR:   return "Error";
     }
   return "Idle";
  }

string GmRptTypeName(const ENUM_GM_RPT_TYPE t)
  {
   switch(t)
     {
      case GM_RPT_TYPE_DAILY:       return "Daily AI Report";
      case GM_RPT_TYPE_WEEKLY:      return "Weekly AI Report";
      case GM_RPT_TYPE_MONTHLY:     return "Monthly AI Report";
      case GM_RPT_TYPE_SESSION:     return "Session Analysis Report";
      case GM_RPT_TYPE_RISK:        return "Risk Report";
      case GM_RPT_TYPE_PERFORMANCE: return "Performance Report";
      case GM_RPT_TYPE_LEARNING:    return "Learning Report";
      case GM_RPT_TYPE_EXECUTIVE:   return "Executive Brief";
      case GM_RPT_TYPE_ENTERPRISE:  return "Enterprise Analytics";
      case GM_RPT_TYPE_AUDIT:       return "Audit Report";
     }
   return "Report";
  }

string GmRptGradeName(const ENUM_GM_RPT_GRADE g)
  {
   switch(g)
     {
      case GM_RPT_GRADE_A_PLUS: return "A+";
      case GM_RPT_GRADE_A:      return "A";
      case GM_RPT_GRADE_B:      return "B";
      case GM_RPT_GRADE_C:      return "C";
      case GM_RPT_GRADE_D:      return "D";
      case GM_RPT_GRADE_F:      return "F";
     }
   return "—";
  }

double GmRptClamp(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

ENUM_GM_RPT_GRADE GmRptGradeFromScore(const double score)
  {
   if(score >= 92.0) return GM_RPT_GRADE_A_PLUS;
   if(score >= 85.0) return GM_RPT_GRADE_A;
   if(score >= 70.0) return GM_RPT_GRADE_B;
   if(score >= 55.0) return GM_RPT_GRADE_C;
   if(score >= 40.0) return GM_RPT_GRADE_D;
   return GM_RPT_GRADE_F;
  }

#endif // GM_REPORTING_AI_CONSTANTS_MQH
//+------------------------------------------------------------------+
