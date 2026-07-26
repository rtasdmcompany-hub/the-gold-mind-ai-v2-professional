//+------------------------------------------------------------------+
//|                           PredictiveIntelligenceConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 5 Sprint 7 — Predictive / Probability / Scenarios     |
//|     ANALYZE / FORECAST ONLY — NEVER executes                    |
//+------------------------------------------------------------------+
#ifndef GM_PREDICTIVE_INTELLIGENCE_CONSTANTS_MQH
#define GM_PREDICTIVE_INTELLIGENCE_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_PRED_VERSION              "1.0.0-predictive"
#define GM_PRED_DB_PREFIX            "GM_AI_PRED_"
#define GM_PRED_THROTTLE_MS          4100
#define GM_PRED_HIST_MAX             64
#define GM_PRED_CACHE_TTL_MS         8200
#define GM_PRED_ANALYSIS_ONLY        "PREDICTIVE INTELLIGENCE ANALYSIS ONLY"
#define GM_PRED_ADVISORY             "ADVISORY ONLY — NO EXECUTION / NO STRATEGY OVERRIDE"
#define GM_PRED_CONTEXT              "H4 | 3Buy/3Sell | ATR-14 TP Env | 30pip SL | BE | 80% Partial | 20% Trail | Second Attempt"

enum ENUM_GM_PRED_STATUS
  {
   GM_PRED_STATUS_IDLE = 0,
   GM_PRED_STATUS_RUNNING,
   GM_PRED_STATUS_READY,
   GM_PRED_STATUS_CACHED,
   GM_PRED_STATUS_ERROR
  };

enum ENUM_GM_PRED_SCENARIO
  {
   GM_PRED_SCN_UNKNOWN = 0,
   GM_PRED_SCN_BULL_CONT,
   GM_PRED_SCN_BEAR_CONT,
   GM_PRED_SCN_RANGE,
   GM_PRED_SCN_BREAKOUT,
   GM_PRED_SCN_FALSE_BREAKOUT,
   GM_PRED_SCN_HIGH_VOL,
   GM_PRED_SCN_LOW_VOL,
   GM_PRED_SCN_RECOVERY
  };

string GmPredStatusName(const ENUM_GM_PRED_STATUS s)
  {
   switch(s)
     {
      case GM_PRED_STATUS_RUNNING: return "Running";
      case GM_PRED_STATUS_READY:   return "Ready";
      case GM_PRED_STATUS_CACHED:  return "Cached";
      case GM_PRED_STATUS_ERROR:   return "Error";
     }
   return "Idle";
  }

string GmPredScenarioName(const ENUM_GM_PRED_SCENARIO s)
  {
   switch(s)
     {
      case GM_PRED_SCN_BULL_CONT:      return "Bullish Continuation";
      case GM_PRED_SCN_BEAR_CONT:      return "Bearish Continuation";
      case GM_PRED_SCN_RANGE:          return "Range Scenario";
      case GM_PRED_SCN_BREAKOUT:       return "Breakout Scenario";
      case GM_PRED_SCN_FALSE_BREAKOUT: return "False Breakout Scenario";
      case GM_PRED_SCN_HIGH_VOL:       return "High Volatility Scenario";
      case GM_PRED_SCN_LOW_VOL:        return "Low Volatility Scenario";
      case GM_PRED_SCN_RECOVERY:       return "Recovery Scenario";
     }
   return "Unknown Scenario";
  }

double GmPredClamp(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

#endif // GM_PREDICTIVE_INTELLIGENCE_CONSTANTS_MQH
//+------------------------------------------------------------------+
