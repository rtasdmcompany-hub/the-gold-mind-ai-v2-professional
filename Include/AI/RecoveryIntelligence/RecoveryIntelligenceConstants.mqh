//+------------------------------------------------------------------+
//|                           RecoveryIntelligenceConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 5 Sprint 4 — Recovery / Hedge / Loss Minimization    |
//|     ANALYZE / EXPLAIN — NEVER opens/closes/modifies trades      |
//+------------------------------------------------------------------+
#ifndef GM_RECOVERY_INTELLIGENCE_CONSTANTS_MQH
#define GM_RECOVERY_INTELLIGENCE_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_RI_VERSION              "1.0.0-recintel"
#define GM_RI_DB_PREFIX            "GM_AI_RI_"
#define GM_RI_THROTTLE_MS          3600
#define GM_RI_HIST_MAX             64
#define GM_RI_CACHE_TTL_MS         7400
#define GM_RI_ANALYSIS_ONLY        "RECOVERY INTELLIGENCE ANALYSIS ONLY"
#define GM_RI_ADVISORY             "ADVISORY ONLY — NO TRADE / ORDER / RISK MUTATION"
#define GM_RI_GOLDMIND_CONTEXT     "H4 | 3Buy/3Sell | ATR-14 | 30pip SL | BE | 80% Partial | 20% Trail | Second Attempt"

enum ENUM_GM_RI_STATUS
  {
   GM_RI_STATUS_IDLE = 0,
   GM_RI_STATUS_RUNNING,
   GM_RI_STATUS_READY,
   GM_RI_STATUS_CACHED,
   GM_RI_STATUS_ERROR
  };

enum ENUM_GM_RI_HEALTH
  {
   GM_RI_HEALTH_UNKNOWN = 0,
   GM_RI_HEALTH_CRITICAL,
   GM_RI_HEALTH_WEAK,
   GM_RI_HEALTH_STABLE,
   GM_RI_HEALTH_STRONG,
   GM_RI_HEALTH_EXCELLENT
  };

enum ENUM_GM_RI_PATTERN
  {
   GM_RI_PAT_UNKNOWN = 0,
   GM_RI_PAT_BEST,
   GM_RI_PAT_WORST,
   GM_RI_PAT_HIGH_SUCCESS,
   GM_RI_PAT_WEAK,
   GM_RI_PAT_NEWS,
   GM_RI_PAT_TREND,
   GM_RI_PAT_RANGE
  };

string GmRiStatusName(const ENUM_GM_RI_STATUS s)
  {
   switch(s)
     {
      case GM_RI_STATUS_RUNNING: return "Running";
      case GM_RI_STATUS_READY:   return "Ready";
      case GM_RI_STATUS_CACHED:  return "Cached";
      case GM_RI_STATUS_ERROR:   return "Error";
     }
   return "Idle";
  }

string GmRiHealthName(const ENUM_GM_RI_HEALTH h)
  {
   switch(h)
     {
      case GM_RI_HEALTH_CRITICAL:  return "Critical";
      case GM_RI_HEALTH_WEAK:      return "Weak";
      case GM_RI_HEALTH_STABLE:    return "Stable";
      case GM_RI_HEALTH_STRONG:    return "Strong";
      case GM_RI_HEALTH_EXCELLENT: return "Excellent";
     }
   return "Unknown";
  }

string GmRiPatternName(const ENUM_GM_RI_PATTERN p)
  {
   switch(p)
     {
      case GM_RI_PAT_BEST:         return "Best Recovery Conditions";
      case GM_RI_PAT_WORST:        return "Worst Recovery Conditions";
      case GM_RI_PAT_HIGH_SUCCESS: return "High Success Environment";
      case GM_RI_PAT_WEAK:         return "Weak Recovery Environment";
      case GM_RI_PAT_NEWS:         return "News Recovery Performance";
      case GM_RI_PAT_TREND:        return "Trend Recovery Performance";
      case GM_RI_PAT_RANGE:        return "Range Recovery Performance";
     }
   return "Unknown Pattern";
  }

double GmRiClamp(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

#endif // GM_RECOVERY_INTELLIGENCE_CONSTANTS_MQH
//+------------------------------------------------------------------+
