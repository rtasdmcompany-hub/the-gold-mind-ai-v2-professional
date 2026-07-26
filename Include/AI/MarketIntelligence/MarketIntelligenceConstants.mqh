//+------------------------------------------------------------------+
//|                             MarketIntelligenceConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 5 Sprint 1 — Enterprise Market Intelligence           |
//|     ANALYZE / EXPLAIN — NEVER executes                          |
//+------------------------------------------------------------------+
#ifndef GM_MARKET_INTELLIGENCE_CONSTANTS_MQH
#define GM_MARKET_INTELLIGENCE_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_MI_VERSION              "1.0.0-marketintel"
#define GM_MI_DB_PREFIX            "GM_AI_MI_"
#define GM_MI_THROTTLE_MS          3200
#define GM_MI_HIST_MAX             64
#define GM_MI_CACHE_TTL_MS         6500
#define GM_MI_ANALYSIS_ONLY        "MARKET INTELLIGENCE ANALYSIS ONLY"
#define GM_MI_ADVISORY             "ADVISORY ONLY — NO EXECUTION"

enum ENUM_GM_MI_STATUS
  {
   GM_MI_STATUS_IDLE = 0,
   GM_MI_STATUS_RUNNING,
   GM_MI_STATUS_READY,
   GM_MI_STATUS_CACHED,
   GM_MI_STATUS_ERROR
  };

enum ENUM_GM_MI_INST_PHASE
  {
   GM_MI_INST_UNKNOWN = 0,
   GM_MI_INST_ACCUMULATION,
   GM_MI_INST_DISTRIBUTION,
   GM_MI_INST_EXPANSION,
   GM_MI_INST_CONSOLIDATION,
   GM_MI_INST_IMPULSE,
   GM_MI_INST_CORRECTION
  };

enum ENUM_GM_MI_STRUCTURE
  {
   GM_MI_STRUCT_UNKNOWN = 0,
   GM_MI_STRUCT_HH_HL,      // bullish structure
   GM_MI_STRUCT_LH_LL,      // bearish structure
   GM_MI_STRUCT_RANGE,
   GM_MI_STRUCT_TRANSITION
  };

string GmMiStatusName(const ENUM_GM_MI_STATUS s)
  {
   switch(s)
     {
      case GM_MI_STATUS_RUNNING: return "Running";
      case GM_MI_STATUS_READY:   return "Ready";
      case GM_MI_STATUS_CACHED:  return "Cached";
      case GM_MI_STATUS_ERROR:   return "Error";
     }
   return "Idle";
  }

string GmMiInstPhaseName(const ENUM_GM_MI_INST_PHASE p)
  {
   switch(p)
     {
      case GM_MI_INST_ACCUMULATION:  return "Accumulation";
      case GM_MI_INST_DISTRIBUTION:  return "Distribution";
      case GM_MI_INST_EXPANSION:     return "Expansion";
      case GM_MI_INST_CONSOLIDATION: return "Consolidation";
      case GM_MI_INST_IMPULSE:       return "Impulse";
      case GM_MI_INST_CORRECTION:    return "Correction";
     }
   return "Unknown";
  }

string GmMiStructureName(const ENUM_GM_MI_STRUCTURE s)
  {
   switch(s)
     {
      case GM_MI_STRUCT_HH_HL:       return "HH/HL Bullish";
      case GM_MI_STRUCT_LH_LL:       return "LH/LL Bearish";
      case GM_MI_STRUCT_RANGE:       return "Range Formation";
      case GM_MI_STRUCT_TRANSITION:  return "Structure Transition";
     }
   return "Unknown";
  }

double GmMiClamp(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

#endif // GM_MARKET_INTELLIGENCE_CONSTANTS_MQH
//+------------------------------------------------------------------+
