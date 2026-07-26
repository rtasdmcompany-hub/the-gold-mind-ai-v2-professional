//+------------------------------------------------------------------+
//|                              MultiTimeframeConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 5 Sprint 5 — Multi-Timeframe / Sync / H4 Context      |
//|     ANALYZE ONLY — H4 remains sole execution timeframe          |
//+------------------------------------------------------------------+
#ifndef GM_MULTI_TIMEFRAME_CONSTANTS_MQH
#define GM_MULTI_TIMEFRAME_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../Trend/TrendAIConstants.mqh"

#define GM_MTF_VERSION              "1.0.0-mtf"
#define GM_MTF_DB_PREFIX            "GM_AI_MTF_"
#define GM_MTF_THROTTLE_MS          3800
#define GM_MTF_HIST_MAX             64
#define GM_MTF_CACHE_TTL_MS         7600
#define GM_MTF_ANALYSIS_ONLY        "MULTI-TIMEFRAME ANALYSIS ONLY"
#define GM_MTF_ADVISORY             "ADVISORY ONLY — H4 GOLD MIND IS SOLE EXECUTION FRAMEWORK"
#define GM_MTF_H4_RULE              "H4=EXECUTION | HigherTF=CONFIRMATION | LowerTF=CONTEXT ONLY"

enum ENUM_GM_MTF_STATUS
  {
   GM_MTF_STATUS_IDLE = 0,
   GM_MTF_STATUS_RUNNING,
   GM_MTF_STATUS_READY,
   GM_MTF_STATUS_CACHED,
   GM_MTF_STATUS_ERROR
  };

enum ENUM_GM_MTF_GRADE
  {
   GM_MTF_GRADE_UNKNOWN = 0,
   GM_MTF_GRADE_F,
   GM_MTF_GRADE_D,
   GM_MTF_GRADE_C,
   GM_MTF_GRADE_B,
   GM_MTF_GRADE_A,
   GM_MTF_GRADE_A_PLUS
  };

enum ENUM_GM_MTF_BIAS
  {
   GM_MTF_BIAS_UNKNOWN = 0,
   GM_MTF_BIAS_BULL,
   GM_MTF_BIAS_BEAR,
   GM_MTF_BIAS_NEUTRAL,
   GM_MTF_BIAS_MIXED
  };

string GmMtfStatusName(const ENUM_GM_MTF_STATUS s)
  {
   switch(s)
     {
      case GM_MTF_STATUS_RUNNING: return "Running";
      case GM_MTF_STATUS_READY:   return "Ready";
      case GM_MTF_STATUS_CACHED:  return "Cached";
      case GM_MTF_STATUS_ERROR:   return "Error";
     }
   return "Idle";
  }

string GmMtfGradeName(const ENUM_GM_MTF_GRADE g)
  {
   switch(g)
     {
      case GM_MTF_GRADE_A_PLUS: return "A+";
      case GM_MTF_GRADE_A:      return "A";
      case GM_MTF_GRADE_B:      return "B";
      case GM_MTF_GRADE_C:      return "C";
      case GM_MTF_GRADE_D:      return "D";
      case GM_MTF_GRADE_F:      return "F";
     }
   return "?";
  }

string GmMtfBiasName(const ENUM_GM_MTF_BIAS b)
  {
   switch(b)
     {
      case GM_MTF_BIAS_BULL:    return "Bullish";
      case GM_MTF_BIAS_BEAR:    return "Bearish";
      case GM_MTF_BIAS_NEUTRAL: return "Neutral";
      case GM_MTF_BIAS_MIXED:   return "Mixed";
     }
   return "Unknown";
  }

ENUM_GM_MTF_BIAS GmMtfBiasFromTrend(const ENUM_GM_TREND_DIR d)
  {
   if(d == GM_TREND_DIR_BULL) return GM_MTF_BIAS_BULL;
   if(d == GM_TREND_DIR_BEAR) return GM_MTF_BIAS_BEAR;
   if(d == GM_TREND_DIR_FLAT) return GM_MTF_BIAS_NEUTRAL;
   return GM_MTF_BIAS_UNKNOWN;
  }

double GmMtfClamp(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

#endif // GM_MULTI_TIMEFRAME_CONSTANTS_MQH
//+------------------------------------------------------------------+
