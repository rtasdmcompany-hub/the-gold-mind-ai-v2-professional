//+------------------------------------------------------------------+
//|                                 OptimizationLabConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 7 Sprint 3 — Strategy Compare / AI Optimization Lab   |
//|     RESEARCH ONLY — NEVER auto-modifies live parameters         |
//+------------------------------------------------------------------+
#ifndef GM_OPTIMIZATION_LAB_CONSTANTS_MQH
#define GM_OPTIMIZATION_LAB_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_EOL_VERSION              "1.0.0-enterprise-optimization-lab"
#define GM_EOL_DB_PREFIX            "GM_EOL_"
#define GM_EOL_THROTTLE_MS          35000
#define GM_EOL_PROFILES             5
#define GM_EOL_DATASETS             9
#define GM_EOL_POLICY               "OPTIMIZATION RESEARCH ONLY — RECOMMENDATIONS REQUIRE USER APPROVAL"
#define GM_EOL_SAFE                 "PAUSE OPTIMIZATION WHILE GM TRADES ACTIVE — NEVER AUTO-APPLY"

// Reference knowledge (READ-ONLY — never written to live config)
#define GM_EOL_REF_SL_PIPS          30.0
#define GM_EOL_REF_ATR_PERIOD       14
#define GM_EOL_REF_BE_PIPS          50.0
#define GM_EOL_REF_PARTIAL_PCT      80.0
#define GM_EOL_REF_TRAIL_PIPS       30.0

enum ENUM_GM_EOL_QUEUE
  {
   GM_EOL_Q_IDLE = 0,
   GM_EOL_Q_PENDING,
   GM_EOL_Q_RUNNING,
   GM_EOL_Q_CACHED,
   GM_EOL_Q_PAUSED
  };

enum ENUM_GM_EOL_DATASET
  {
   GM_EOL_DS_TRENDING = 0,
   GM_EOL_DS_RANGING,
   GM_EOL_DS_HIGH_VOL,
   GM_EOL_DS_LOW_VOL,
   GM_EOL_DS_NEWS,
   GM_EOL_DS_ASIA,
   GM_EOL_DS_LONDON,
   GM_EOL_DS_NEWYORK,
   GM_EOL_DS_HISTORICAL_YEARS
  };

string GmEolQueueName(const ENUM_GM_EOL_QUEUE q)
  {
   switch(q)
     {
      case GM_EOL_Q_PENDING: return "Pending";
      case GM_EOL_Q_RUNNING: return "Running";
      case GM_EOL_Q_CACHED:  return "Cached";
      case GM_EOL_Q_PAUSED:  return "Paused";
     }
   return "Idle";
  }

string GmEolDatasetName(const ENUM_GM_EOL_DATASET d)
  {
   switch(d)
     {
      case GM_EOL_DS_TRENDING:         return "Trending";
      case GM_EOL_DS_RANGING:          return "Ranging";
      case GM_EOL_DS_HIGH_VOL:         return "High Volatility";
      case GM_EOL_DS_LOW_VOL:          return "Low Volatility";
      case GM_EOL_DS_NEWS:             return "News Sessions";
      case GM_EOL_DS_ASIA:             return "Asian Session";
      case GM_EOL_DS_LONDON:           return "London Session";
      case GM_EOL_DS_NEWYORK:          return "New York Session";
      case GM_EOL_DS_HISTORICAL_YEARS: return "Historical Years";
     }
   return "Unknown";
  }

#endif // GM_OPTIMIZATION_LAB_CONSTANTS_MQH
//+------------------------------------------------------------------+
