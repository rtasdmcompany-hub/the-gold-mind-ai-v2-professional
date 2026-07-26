//+------------------------------------------------------------------+
//|                                    AIValidationConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     Phase 3 Sprint 9 — AI Validation & Certification            |
//|     ANALYSIS ONLY — never modifies strategy / risk / orders     |
//+------------------------------------------------------------------+
#ifndef GM_AI_VALIDATION_CONSTANTS_MQH
#define GM_AI_VALIDATION_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_AIVAL_VERSION          "1.0.0-aival"
#define GM_AIVAL_HIST_MAX         128
#define GM_AIVAL_ACC_RING         32
#define GM_AIVAL_EVT_MAX          200
#define GM_AIVAL_DB_PREFIX        "GM_AI_VAL_"
#define GM_AIVAL_THROTTLE_MS      2000
#define GM_AIVAL_ANALYSIS_ONLY    "VALIDATION ONLY"
#define GM_AIVAL_DRIFT_THRESH     12.0

enum ENUM_GM_AIVAL_STATUS
  {
   GM_AIVAL_STATUS_IDLE = 0,
   GM_AIVAL_STATUS_RUNNING,
   GM_AIVAL_STATUS_READY,
   GM_AIVAL_STATUS_DRIFT,
   GM_AIVAL_STATUS_ERROR
  };

enum ENUM_GM_AIVAL_GRADE
  {
   GM_AIVAL_GRADE_UNKNOWN = 0,
   GM_AIVAL_GRADE_A,
   GM_AIVAL_GRADE_B,
   GM_AIVAL_GRADE_C,
   GM_AIVAL_GRADE_D,
   GM_AIVAL_GRADE_F
  };

enum ENUM_GM_AIVAL_DRIFT
  {
   GM_AIVAL_DRIFT_NONE = 0,
   GM_AIVAL_DRIFT_CONFIDENCE,
   GM_AIVAL_DRIFT_PREDICTION,
   GM_AIVAL_DRIFT_RECOMMENDATION,
   GM_AIVAL_DRIFT_PATTERN,
   GM_AIVAL_DRIFT_REGIME,
   GM_AIVAL_DRIFT_DEGRADATION
  };

string GmAiValStatusName(const ENUM_GM_AIVAL_STATUS s)
  {
   switch(s)
     {
      case GM_AIVAL_STATUS_RUNNING: return "Running";
      case GM_AIVAL_STATUS_READY:   return "Ready";
      case GM_AIVAL_STATUS_DRIFT:   return "Drift Alert";
      case GM_AIVAL_STATUS_ERROR:   return "Error";
     }
   return "Idle";
  }

string GmAiValGradeName(const ENUM_GM_AIVAL_GRADE g)
  {
   switch(g)
     {
      case GM_AIVAL_GRADE_A: return "A";
      case GM_AIVAL_GRADE_B: return "B";
      case GM_AIVAL_GRADE_C: return "C";
      case GM_AIVAL_GRADE_D: return "D";
      case GM_AIVAL_GRADE_F: return "F";
     }
   return "—";
  }

string GmAiValDriftName(const ENUM_GM_AIVAL_DRIFT d)
  {
   switch(d)
     {
      case GM_AIVAL_DRIFT_CONFIDENCE:     return "Confidence Drift";
      case GM_AIVAL_DRIFT_PREDICTION:     return "Prediction Drift";
      case GM_AIVAL_DRIFT_RECOMMENDATION: return "Recommendation Drift";
      case GM_AIVAL_DRIFT_PATTERN:        return "Pattern Drift";
      case GM_AIVAL_DRIFT_REGIME:         return "Market Regime Change";
      case GM_AIVAL_DRIFT_DEGRADATION:    return "Performance Degradation";
     }
   return "None";
  }

double GmAiValClamp(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

#endif // GM_AI_VALIDATION_CONSTANTS_MQH
//+------------------------------------------------------------------+
