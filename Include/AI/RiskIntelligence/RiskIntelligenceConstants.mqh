//+------------------------------------------------------------------+
//|                                RiskIntelligenceConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 4 Sprint 7 — AI Risk Intelligence Center              |
//|     OBSERVE / MEASURE / ANALYZE / WARN / REPORT — NEVER acts    |
//+------------------------------------------------------------------+
#ifndef GM_RISK_INTELLIGENCE_CONSTANTS_MQH
#define GM_RISK_INTELLIGENCE_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_RISKINT_VERSION         "1.0.0-riskintel"
#define GM_RISKINT_DB_PREFIX       "GM_AI_RISK_"
#define GM_RISKINT_THROTTLE_MS     3200
#define GM_RISKINT_HIST_MAX        64
#define GM_RISKINT_CACHE_TTL_MS    6500
#define GM_RISKINT_ALERT_MAX       8
#define GM_RISKINT_ANALYSIS_ONLY   "RISK INTELLIGENCE ADVISORY ONLY"
#define GM_RISKINT_ADVISORY        "ADVISORY ONLY — NO RISK MODIFICATION"

enum ENUM_GM_RISKINT_STATUS
  {
   GM_RISKINT_STATUS_IDLE = 0,
   GM_RISKINT_STATUS_RUNNING,
   GM_RISKINT_STATUS_READY,
   GM_RISKINT_STATUS_CACHED,
   GM_RISKINT_STATUS_ERROR
  };

enum ENUM_GM_MARGIN_GRADE
  {
   GM_MARGIN_GRADE_UNKNOWN = 0,
   GM_MARGIN_GRADE_A,   // Excellent
   GM_MARGIN_GRADE_B,   // Healthy
   GM_MARGIN_GRADE_C,   // Monitor
   GM_MARGIN_GRADE_D,   // Warning
   GM_MARGIN_GRADE_F    // Critical
  };

enum ENUM_GM_RISK_LEVEL
  {
   GM_RISK_LEVEL_UNKNOWN = 0,
   GM_RISK_LEVEL_LOW,
   GM_RISK_LEVEL_MODERATE,
   GM_RISK_LEVEL_ELEVATED,
   GM_RISK_LEVEL_HIGH
  };

enum ENUM_GM_CAP_STATUS
  {
   GM_CAP_STATUS_UNKNOWN = 0,
   GM_CAP_STATUS_EXCELLENT,
   GM_CAP_STATUS_GOOD,
   GM_CAP_STATUS_FAIR,
   GM_CAP_STATUS_PRESSURE,
   GM_CAP_STATUS_STRESSED
  };

string GmRiskIntStatusName(const ENUM_GM_RISKINT_STATUS s)
  {
   switch(s)
     {
      case GM_RISKINT_STATUS_RUNNING: return "Running";
      case GM_RISKINT_STATUS_READY:   return "Ready";
      case GM_RISKINT_STATUS_CACHED:  return "Cached";
      case GM_RISKINT_STATUS_ERROR:   return "Error";
     }
   return "Idle";
  }

string GmMarginGradeName(const ENUM_GM_MARGIN_GRADE g)
  {
   switch(g)
     {
      case GM_MARGIN_GRADE_A: return "A — Excellent";
      case GM_MARGIN_GRADE_B: return "B — Healthy";
      case GM_MARGIN_GRADE_C: return "C — Monitor";
      case GM_MARGIN_GRADE_D: return "D — Warning";
      case GM_MARGIN_GRADE_F: return "F — Critical";
     }
   return "Unknown";
  }

string GmRiskLevelName(const ENUM_GM_RISK_LEVEL r)
  {
   switch(r)
     {
      case GM_RISK_LEVEL_LOW:      return "Low";
      case GM_RISK_LEVEL_MODERATE: return "Moderate";
      case GM_RISK_LEVEL_ELEVATED: return "Elevated";
      case GM_RISK_LEVEL_HIGH:     return "High";
     }
   return "Unknown";
  }

string GmCapStatusName(const ENUM_GM_CAP_STATUS c)
  {
   switch(c)
     {
      case GM_CAP_STATUS_EXCELLENT: return "Excellent";
      case GM_CAP_STATUS_GOOD:      return "Good";
      case GM_CAP_STATUS_FAIR:      return "Fair";
      case GM_CAP_STATUS_PRESSURE:  return "Pressure";
      case GM_CAP_STATUS_STRESSED: return "Stressed";
     }
   return "Unknown";
  }

double GmRiskIntClamp(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

#endif // GM_RISK_INTELLIGENCE_CONSTANTS_MQH
//+------------------------------------------------------------------+
