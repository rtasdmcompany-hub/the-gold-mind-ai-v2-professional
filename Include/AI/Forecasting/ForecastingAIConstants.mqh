//+------------------------------------------------------------------+
//|                                   ForecastingAIConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 4 Sprint 8 — Market Forecasting & Scenario Analysis   |
//|     ANALYZE / SIMULATE / COMPARE / EXPLAIN / REPORT — NEVER acts|
//+------------------------------------------------------------------+
#ifndef GM_FORECASTING_AI_CONSTANTS_MQH
#define GM_FORECASTING_AI_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_FCST_VERSION            "1.0.0-forecast"
#define GM_FCST_DB_PREFIX          "GM_AI_FCST_"
#define GM_FCST_THROTTLE_MS        3400
#define GM_FCST_HIST_MAX           64
#define GM_FCST_CACHE_TTL_MS       7000
#define GM_FCST_ANALYSIS_ONLY      "FORECAST ANALYSIS ONLY"
#define GM_FCST_ADVISORY           "ADVISORY ONLY — NO EXECUTION"

enum ENUM_GM_FCST_STATUS
  {
   GM_FCST_STATUS_IDLE = 0,
   GM_FCST_STATUS_RUNNING,
   GM_FCST_STATUS_READY,
   GM_FCST_STATUS_CACHED,
   GM_FCST_STATUS_ERROR
  };

enum ENUM_GM_FCST_OUTLOOK
  {
   GM_FCST_OUTLOOK_UNKNOWN = 0,
   GM_FCST_OUTLOOK_NEGATIVE,
   GM_FCST_OUTLOOK_NEUTRAL,
   GM_FCST_OUTLOOK_MOD_POSITIVE,
   GM_FCST_OUTLOOK_POSITIVE
  };

enum ENUM_GM_FCST_SCENARIO
  {
   GM_FCST_SCN_UNKNOWN = 0,
   GM_FCST_SCN_CONTINUATION,
   GM_FCST_SCN_RANGE,
   GM_FCST_SCN_VOL_EXPANSION,
   GM_FCST_SCN_REVERSAL
  };

enum ENUM_GM_FCST_REGIME
  {
   GM_FCST_REGIME_UNKNOWN = 0,
   GM_FCST_REGIME_TRENDING,
   GM_FCST_REGIME_SIDEWAYS,
   GM_FCST_REGIME_VOLATILE,
   GM_FCST_REGIME_RECOVERY,
   GM_FCST_REGIME_UNSTABLE
  };

string GmFcstStatusName(const ENUM_GM_FCST_STATUS s)
  {
   switch(s)
     {
      case GM_FCST_STATUS_RUNNING: return "Running";
      case GM_FCST_STATUS_READY:   return "Ready";
      case GM_FCST_STATUS_CACHED:  return "Cached";
      case GM_FCST_STATUS_ERROR:   return "Error";
     }
   return "Idle";
  }

string GmFcstOutlookName(const ENUM_GM_FCST_OUTLOOK o)
  {
   switch(o)
     {
      case GM_FCST_OUTLOOK_NEGATIVE:     return "Negative";
      case GM_FCST_OUTLOOK_NEUTRAL:      return "Neutral";
      case GM_FCST_OUTLOOK_MOD_POSITIVE: return "Moderately Positive";
      case GM_FCST_OUTLOOK_POSITIVE:     return "Positive";
     }
   return "Unknown";
  }

string GmFcstScenarioName(const ENUM_GM_FCST_SCENARIO s)
  {
   switch(s)
     {
      case GM_FCST_SCN_CONTINUATION: return "Trend Continuation";
      case GM_FCST_SCN_RANGE:        return "Range Formation";
      case GM_FCST_SCN_VOL_EXPANSION:return "High Volatility Expansion";
      case GM_FCST_SCN_REVERSAL:     return "Market Reversal";
     }
   return "Unknown";
  }

string GmFcstRegimeName(const ENUM_GM_FCST_REGIME r)
  {
   switch(r)
     {
      case GM_FCST_REGIME_TRENDING:  return "Trending Market";
      case GM_FCST_REGIME_SIDEWAYS:  return "Sideways Market";
      case GM_FCST_REGIME_VOLATILE:  return "Volatile Market";
      case GM_FCST_REGIME_RECOVERY:  return "Recovery Market";
      case GM_FCST_REGIME_UNSTABLE:  return "Unstable Market";
     }
   return "Unknown";
  }

double GmFcstClamp(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

#endif // GM_FORECASTING_AI_CONSTANTS_MQH
//+------------------------------------------------------------------+
