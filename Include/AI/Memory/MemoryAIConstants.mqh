//+------------------------------------------------------------------+
//|                                         MemoryAIConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 4 Sprint 3 — Learning Memory & Adaptive Intelligence  |
//|     LEARN / ADVISE ONLY — NEVER mutates Core / Risk / Strategy  |
//+------------------------------------------------------------------+
#ifndef GM_MEMORY_AI_CONSTANTS_MQH
#define GM_MEMORY_AI_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../Market/MarketAnalysisConstants.mqh"

#define GM_MEM_VERSION            "1.0.0-memory"
#define GM_MEM_DB_PREFIX          "GM_AI_MEM_"
#define GM_MEM_THROTTLE_MS        2500
#define GM_MEM_HIST_MAX           128
#define GM_MEM_PATTERN_MAX        24
#define GM_MEM_GRAPH_NODES        16
#define GM_MEM_GRAPH_EDGES        24
#define GM_MEM_BATCH_SIZE         8
#define GM_MEM_CACHE_TTL_MS       5000
#define GM_MEM_ANALYSIS_ONLY      "LEARNING MEMORY ONLY"
#define GM_MEM_ADVISORY           "ADVISORY ONLY — NO EXECUTION / NO STRATEGY CHANGE"

enum ENUM_GM_MEM_STATUS
  {
   GM_MEM_STATUS_IDLE = 0,
   GM_MEM_STATUS_RUNNING,
   GM_MEM_STATUS_READY,
   GM_MEM_STATUS_CACHED,
   GM_MEM_STATUS_ERROR
  };

enum ENUM_GM_BEHAVIOR_TYPE
  {
   GM_BEH_UNKNOWN = 0,
   GM_BEH_TRENDING,
   GM_BEH_SIDEWAYS,
   GM_BEH_HIGH_VOL,
   GM_BEH_LOW_LIQUIDITY,
   GM_BEH_RECOVERY,
   GM_BEH_NEWS_DRIVEN,
   GM_BEH_FAKE_BREAKOUT,
   GM_BEH_STRONG_MOMENTUM,
   GM_BEH_HIGH_VOL_RECOVERY
  };

string GmMemStatusName(const ENUM_GM_MEM_STATUS s)
  {
   switch(s)
     {
      case GM_MEM_STATUS_RUNNING: return "Running";
      case GM_MEM_STATUS_READY:   return "Ready";
      case GM_MEM_STATUS_CACHED:  return "Cached";
      case GM_MEM_STATUS_ERROR:   return "Error";
     }
   return "Idle";
  }

string GmBehaviorName(const ENUM_GM_BEHAVIOR_TYPE b)
  {
   switch(b)
     {
      case GM_BEH_TRENDING:          return "Trending Market";
      case GM_BEH_SIDEWAYS:          return "Sideways Market";
      case GM_BEH_HIGH_VOL:          return "High Volatility Session";
      case GM_BEH_LOW_LIQUIDITY:     return "Low Liquidity Session";
      case GM_BEH_RECOVERY:          return "Recovery Condition";
      case GM_BEH_NEWS_DRIVEN:       return "News Driven Move";
      case GM_BEH_FAKE_BREAKOUT:     return "Fake Breakout Risk";
      case GM_BEH_STRONG_MOMENTUM:   return "Strong Momentum Period";
      case GM_BEH_HIGH_VOL_RECOVERY: return "High Volatility Recovery Environment";
     }
   return "Unknown Behavior";
  }

double GmMemClamp(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

#endif // GM_MEMORY_AI_CONSTANTS_MQH
//+------------------------------------------------------------------+
