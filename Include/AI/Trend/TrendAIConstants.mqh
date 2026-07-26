//+------------------------------------------------------------------+
//|                                          TrendAIConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     Phase 3 Sprint 3 — Trend Detection (ANALYSIS ONLY)          |
//+------------------------------------------------------------------+
#ifndef GM_TREND_AI_CONSTANTS_MQH
#define GM_TREND_AI_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_TREND_AI_VERSION       "1.0.0-trend"
#define GM_TREND_LOOKBACK         30
#define GM_TREND_SWING_LEFT       2
#define GM_TREND_SWING_RIGHT      2
#define GM_TREND_HIST_MAX         128
#define GM_TREND_EVENT_MAX        200
#define GM_TREND_DB_PREFIX        "GM_AI_TREND_"
#define GM_TREND_THROTTLE_MS      500

enum ENUM_GM_TREND_DIR
  {
   GM_TREND_DIR_UNKNOWN = 0,
   GM_TREND_DIR_BULL,
   GM_TREND_DIR_BEAR,
   GM_TREND_DIR_FLAT
  };

enum ENUM_GM_TREND_PHASE
  {
   GM_TREND_PHASE_UNCERTAIN = 0,
   GM_TREND_PHASE_STRONG_BULL,
   GM_TREND_PHASE_BULL,
   GM_TREND_PHASE_WEAK_BULL,
   GM_TREND_PHASE_SIDEWAYS,
   GM_TREND_PHASE_WEAK_BEAR,
   GM_TREND_PHASE_BEAR,
   GM_TREND_PHASE_STRONG_BEAR,
   GM_TREND_PHASE_TRANSITION,
   GM_TREND_PHASE_ACCUMULATION,
   GM_TREND_PHASE_DISTRIBUTION
  };

enum ENUM_GM_TREND_STRUCTURE
  {
   GM_TREND_STRUCT_NONE = 0,
   GM_TREND_STRUCT_HH,
   GM_TREND_STRUCT_HL,
   GM_TREND_STRUCT_LH,
   GM_TREND_STRUCT_LL,
   GM_TREND_STRUCT_BOS_UP,
   GM_TREND_STRUCT_BOS_DOWN,
   GM_TREND_STRUCT_CHOCH_UP,
   GM_TREND_STRUCT_CHOCH_DOWN,
   GM_TREND_STRUCT_LIQ_SWEEP_HIGH,
   GM_TREND_STRUCT_LIQ_SWEEP_LOW
  };

enum ENUM_GM_TREND_EVENT
  {
   GM_TREND_EVT_STARTED = 0,
   GM_TREND_EVT_STRENGTH_UP,
   GM_TREND_EVT_STRENGTH_DOWN,
   GM_TREND_EVT_REVERSAL,
   GM_TREND_EVT_STRUCTURE,
   GM_TREND_EVT_BOS,
   GM_TREND_EVT_CHOCH,
   GM_TREND_EVT_LIQUIDITY,
   GM_TREND_EVT_INFO
  };

string GmTrendDirName(const ENUM_GM_TREND_DIR d)
  {
   switch(d)
     {
      case GM_TREND_DIR_BULL: return "Bullish";
      case GM_TREND_DIR_BEAR: return "Bearish";
      case GM_TREND_DIR_FLAT: return "Flat";
     }
   return "Unknown";
  }

string GmTrendPhaseName(const ENUM_GM_TREND_PHASE p)
  {
   switch(p)
     {
      case GM_TREND_PHASE_STRONG_BULL:   return "Strong Bullish Trend";
      case GM_TREND_PHASE_BULL:          return "Bullish Trend";
      case GM_TREND_PHASE_WEAK_BULL:     return "Weak Bullish Trend";
      case GM_TREND_PHASE_SIDEWAYS:      return "Sideways";
      case GM_TREND_PHASE_WEAK_BEAR:     return "Weak Bearish Trend";
      case GM_TREND_PHASE_BEAR:          return "Bearish Trend";
      case GM_TREND_PHASE_STRONG_BEAR:   return "Strong Bearish Trend";
      case GM_TREND_PHASE_TRANSITION:    return "Transition Phase";
      case GM_TREND_PHASE_ACCUMULATION:  return "Accumulation";
      case GM_TREND_PHASE_DISTRIBUTION:  return "Distribution";
     }
   return "Uncertain";
  }

string GmTrendStructName(const ENUM_GM_TREND_STRUCTURE s)
  {
   switch(s)
     {
      case GM_TREND_STRUCT_HH:            return "Higher High";
      case GM_TREND_STRUCT_HL:            return "Higher Low";
      case GM_TREND_STRUCT_LH:            return "Lower High";
      case GM_TREND_STRUCT_LL:            return "Lower Low";
      case GM_TREND_STRUCT_BOS_UP:        return "BOS Up";
      case GM_TREND_STRUCT_BOS_DOWN:      return "BOS Down";
      case GM_TREND_STRUCT_CHOCH_UP:      return "CHOCH Up";
      case GM_TREND_STRUCT_CHOCH_DOWN:    return "CHOCH Down";
      case GM_TREND_STRUCT_LIQ_SWEEP_HIGH:return "Liquidity Sweep High";
      case GM_TREND_STRUCT_LIQ_SWEEP_LOW: return "Liquidity Sweep Low";
     }
   return "None";
  }

string GmTrendEventName(const ENUM_GM_TREND_EVENT e)
  {
   switch(e)
     {
      case GM_TREND_EVT_STARTED:      return "Trend Started";
      case GM_TREND_EVT_STRENGTH_UP:  return "Trend Strength Increased";
      case GM_TREND_EVT_STRENGTH_DOWN:return "Trend Strength Decreased";
      case GM_TREND_EVT_REVERSAL:     return "Trend Reversal Detected";
      case GM_TREND_EVT_STRUCTURE:    return "Structure Changed";
      case GM_TREND_EVT_BOS:          return "BOS Detected";
      case GM_TREND_EVT_CHOCH:        return "CHOCH Detected";
      case GM_TREND_EVT_LIQUIDITY:    return "Liquidity Sweep Detected";
     }
   return "Info";
  }

ENUM_GM_TREND_DIR GmTrendFromCloses(const double c0, const double cN, const double range)
  {
   if(range <= 0.0)
      return GM_TREND_DIR_FLAT;
   const double r = (c0 - cN) / range;
   if(MathAbs(r) < 0.12)
      return GM_TREND_DIR_FLAT;
   return (r > 0.0) ? GM_TREND_DIR_BULL : GM_TREND_DIR_BEAR;
  }

#endif // GM_TREND_AI_CONSTANTS_MQH
//+------------------------------------------------------------------+
