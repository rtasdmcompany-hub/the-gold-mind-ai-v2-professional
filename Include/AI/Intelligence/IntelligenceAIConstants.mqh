//+------------------------------------------------------------------+
//|                                  IntelligenceAIConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 4 Sprint 2 — Decision Intelligence / Advisory Engine  |
//|     ADVISE ONLY — NEVER executes or mutates Core / Risk         |
//+------------------------------------------------------------------+
#ifndef GM_INTELLIGENCE_AI_CONSTANTS_MQH
#define GM_INTELLIGENCE_AI_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../Market/MarketAnalysisConstants.mqh"

#define GM_INTEL_VERSION           "1.0.0-intel"
#define GM_INTEL_DB_PREFIX         "GM_AI_INT_"
#define GM_INTEL_THROTTLE_MS       2000
#define GM_INTEL_HIST_MAX          96
#define GM_INTEL_QUEUE_MAX         8
#define GM_INTEL_CACHE_TTL_MS      4000
#define GM_INTEL_ANALYSIS_ONLY     "INTELLIGENCE ONLY"
#define GM_INTEL_ADVISORY          "ADVISORY ONLY — NO EXECUTION"

#define GM_INTEL_W_TREND           0.30
#define GM_INTEL_W_VOL             0.20
#define GM_INTEL_W_LIQ             0.15
#define GM_INTEL_W_HIST            0.15
#define GM_INTEL_W_RISK            0.20

enum ENUM_GM_INTEL_STATUS
  {
   GM_INTEL_STATUS_IDLE = 0,
   GM_INTEL_STATUS_QUEUED,
   GM_INTEL_STATUS_RUNNING,
   GM_INTEL_STATUS_READY,
   GM_INTEL_STATUS_CACHED,
   GM_INTEL_STATUS_ERROR
  };

enum ENUM_GM_RISK_ADVISORY
  {
   GM_RISK_ADV_UNKNOWN = 0,
   GM_RISK_ADV_LOW,
   GM_RISK_ADV_MODERATE,
   GM_RISK_ADV_ELEVATED,
   GM_RISK_ADV_HIGH
  };

enum ENUM_GM_INTEL_GRADE
  {
   GM_INTEL_GRADE_UNKNOWN = 0,
   GM_INTEL_GRADE_A,
   GM_INTEL_GRADE_B,
   GM_INTEL_GRADE_C,
   GM_INTEL_GRADE_D,
   GM_INTEL_GRADE_F
  };

string GmIntelStatusName(const ENUM_GM_INTEL_STATUS s)
  {
   switch(s)
     {
      case GM_INTEL_STATUS_QUEUED:  return "Queued";
      case GM_INTEL_STATUS_RUNNING: return "Running";
      case GM_INTEL_STATUS_READY:   return "Ready";
      case GM_INTEL_STATUS_CACHED:  return "Cached";
      case GM_INTEL_STATUS_ERROR:   return "Error";
     }
   return "Idle";
  }

string GmRiskAdvName(const ENUM_GM_RISK_ADVISORY r)
  {
   switch(r)
     {
      case GM_RISK_ADV_LOW:       return "LOW RISK";
      case GM_RISK_ADV_MODERATE:  return "MODERATE RISK";
      case GM_RISK_ADV_ELEVATED:  return "ELEVATED RISK";
      case GM_RISK_ADV_HIGH:      return "HIGH RISK";
     }
   return "UNKNOWN";
  }

string GmIntelGradeName(const ENUM_GM_INTEL_GRADE g)
  {
   switch(g)
     {
      case GM_INTEL_GRADE_A: return "A";
      case GM_INTEL_GRADE_B: return "B";
      case GM_INTEL_GRADE_C: return "C";
      case GM_INTEL_GRADE_D: return "D";
      case GM_INTEL_GRADE_F: return "F";
     }
   return "—";
  }

double GmIntelClamp(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

ENUM_GM_INTEL_GRADE GmIntelGradeFromScore(const double score)
  {
   if(score >= 85.0) return GM_INTEL_GRADE_A;
   if(score >= 70.0) return GM_INTEL_GRADE_B;
   if(score >= 55.0) return GM_INTEL_GRADE_C;
   if(score >= 40.0) return GM_INTEL_GRADE_D;
   return GM_INTEL_GRADE_F;
  }

#endif // GM_INTELLIGENCE_AI_CONSTANTS_MQH
//+------------------------------------------------------------------+
