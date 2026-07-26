//+------------------------------------------------------------------+
//|                                      OrderFlowAIConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 5 Sprint 2 — Order Flow / Session / Energy            |
//|     ANALYZE / EXPLAIN — NEVER executes                          |
//+------------------------------------------------------------------+
#ifndef GM_ORDER_FLOW_AI_CONSTANTS_MQH
#define GM_ORDER_FLOW_AI_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_OF_VERSION              "1.0.0-orderflow"
#define GM_OF_DB_PREFIX            "GM_AI_OF_"
#define GM_OF_THROTTLE_MS          3300
#define GM_OF_HIST_MAX             64
#define GM_OF_CACHE_TTL_MS         6800
#define GM_OF_ANALYSIS_ONLY        "ORDER FLOW ANALYSIS ONLY"
#define GM_OF_ADVISORY             "ADVISORY ONLY — NO EXECUTION"

enum ENUM_GM_OF_STATUS
  {
   GM_OF_STATUS_IDLE = 0,
   GM_OF_STATUS_RUNNING,
   GM_OF_STATUS_READY,
   GM_OF_STATUS_CACHED,
   GM_OF_STATUS_ERROR
  };

enum ENUM_GM_OF_SESSION
  {
   GM_OF_SESSION_UNKNOWN = 0,
   GM_OF_SESSION_SYDNEY,
   GM_OF_SESSION_TOKYO,
   GM_OF_SESSION_LONDON,
   GM_OF_SESSION_NEWYORK,
   GM_OF_SESSION_OVERLAP_ASIA,
   GM_OF_SESSION_OVERLAP_LONDON_NY
  };

enum ENUM_GM_OF_TEMPERATURE
  {
   GM_OF_TEMP_UNKNOWN = 0,
   GM_OF_TEMP_COLD,
   GM_OF_TEMP_CALM,
   GM_OF_TEMP_NORMAL,
   GM_OF_TEMP_ACTIVE,
   GM_OF_TEMP_HOT,
   GM_OF_TEMP_EXTREME
  };

enum ENUM_GM_OF_PERSONALITY
  {
   GM_OF_PERS_UNKNOWN = 0,
   GM_OF_PERS_TRENDING,
   GM_OF_PERS_RANGING,
   GM_OF_PERS_HIGH_VOL,
   GM_OF_PERS_LOW_VOL,
   GM_OF_PERS_NEWS,
   GM_OF_PERS_RECOVERY
  };

string GmOfStatusName(const ENUM_GM_OF_STATUS s)
  {
   switch(s)
     {
      case GM_OF_STATUS_RUNNING: return "Running";
      case GM_OF_STATUS_READY:   return "Ready";
      case GM_OF_STATUS_CACHED:  return "Cached";
      case GM_OF_STATUS_ERROR:   return "Error";
     }
   return "Idle";
  }

string GmOfSessionName(const ENUM_GM_OF_SESSION s)
  {
   switch(s)
     {
      case GM_OF_SESSION_SYDNEY:            return "Sydney";
      case GM_OF_SESSION_TOKYO:             return "Tokyo";
      case GM_OF_SESSION_LONDON:            return "London";
      case GM_OF_SESSION_NEWYORK:           return "New York";
      case GM_OF_SESSION_OVERLAP_ASIA:      return "Asia Overlap";
      case GM_OF_SESSION_OVERLAP_LONDON_NY: return "London/NY Overlap";
     }
   return "Unknown";
  }

string GmOfTempName(const ENUM_GM_OF_TEMPERATURE t)
  {
   switch(t)
     {
      case GM_OF_TEMP_COLD:    return "Cold Market";
      case GM_OF_TEMP_CALM:    return "Calm Market";
      case GM_OF_TEMP_NORMAL:  return "Normal Market";
      case GM_OF_TEMP_ACTIVE:  return "Active Market";
      case GM_OF_TEMP_HOT:     return "Hot Market";
      case GM_OF_TEMP_EXTREME: return "Extreme Market";
     }
   return "Unknown";
  }

string GmOfPersonalityName(const ENUM_GM_OF_PERSONALITY p)
  {
   switch(p)
     {
      case GM_OF_PERS_TRENDING:  return "Trending Session";
      case GM_OF_PERS_RANGING:   return "Ranging Session";
      case GM_OF_PERS_HIGH_VOL:  return "High Volatility Session";
      case GM_OF_PERS_LOW_VOL:   return "Low Volatility Session";
      case GM_OF_PERS_NEWS:      return "News Session";
      case GM_OF_PERS_RECOVERY:  return "Recovery Session";
     }
   return "Unknown";
  }

double GmOfClamp(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

#endif // GM_ORDER_FLOW_AI_CONSTANTS_MQH
//+------------------------------------------------------------------+
