//+------------------------------------------------------------------+
//|                                   MarketAnalysisConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     Phase 3 Sprint 2 — Market Analysis (ANALYSIS ONLY)          |
//+------------------------------------------------------------------+
#ifndef GM_MARKET_ANALYSIS_CONSTANTS_MQH
#define GM_MARKET_ANALYSIS_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_MKT_AI_VERSION           "1.0.0-market"
#define GM_MKT_SWING_LOOKBACK       20
#define GM_MKT_ATR_PERIOD           14
#define GM_MKT_SNAP_MAX             64
#define GM_MKT_HIST_MAX             128
#define GM_MKT_DB_PREFIX            "GM_AI_MKT_"
#define GM_MKT_THROTTLE_MS          400

enum ENUM_GM_MKT_DIRECTION
  {
   GM_MKT_DIR_UNKNOWN = 0,
   GM_MKT_DIR_BULLISH,
   GM_MKT_DIR_BEARISH,
   GM_MKT_DIR_SIDEWAYS
  };

enum ENUM_GM_MKT_STRUCTURE
  {
   GM_MKT_STRUCT_NONE = 0,
   GM_MKT_STRUCT_HH,
   GM_MKT_STRUCT_HL,
   GM_MKT_STRUCT_LH,
   GM_MKT_STRUCT_LL,
   GM_MKT_STRUCT_BOS_UP,
   GM_MKT_STRUCT_BOS_DOWN
  };

enum ENUM_GM_MKT_PATTERN
  {
   GM_MKT_PAT_NONE = 0,
   GM_MKT_PAT_BULL_ENGULF,
   GM_MKT_PAT_BEAR_ENGULF,
   GM_MKT_PAT_INSIDE,
   GM_MKT_PAT_OUTSIDE,
   GM_MKT_PAT_DOJI,
   GM_MKT_PAT_PIN_BULL,
   GM_MKT_PAT_PIN_BEAR,
   GM_MKT_PAT_HAMMER,
   GM_MKT_PAT_SHOOTING_STAR,
   GM_MKT_PAT_STRONG_BULL,
   GM_MKT_PAT_STRONG_BEAR,
   GM_MKT_PAT_WEAK
  };

enum ENUM_GM_MKT_CONDITION
  {
   GM_MKT_COND_UNCERTAIN = 0,
   GM_MKT_COND_TRENDING,
   GM_MKT_COND_STRONG_TREND,
   GM_MKT_COND_RANGING,
   GM_MKT_COND_HIGH_VOL,
   GM_MKT_COND_LOW_VOL,
   GM_MKT_COND_BREAKOUT,
   GM_MKT_COND_PULLBACK,
   GM_MKT_COND_CONSOLIDATION
  };

string GmMktDirName(const ENUM_GM_MKT_DIRECTION d)
  {
   switch(d)
     {
      case GM_MKT_DIR_BULLISH:  return "Bullish";
      case GM_MKT_DIR_BEARISH:  return "Bearish";
      case GM_MKT_DIR_SIDEWAYS: return "Sideways";
     }
   return "Unknown";
  }

string GmMktStructName(const ENUM_GM_MKT_STRUCTURE s)
  {
   switch(s)
     {
      case GM_MKT_STRUCT_HH:       return "Higher High";
      case GM_MKT_STRUCT_HL:       return "Higher Low";
      case GM_MKT_STRUCT_LH:       return "Lower High";
      case GM_MKT_STRUCT_LL:       return "Lower Low";
      case GM_MKT_STRUCT_BOS_UP:   return "BOS Up";
      case GM_MKT_STRUCT_BOS_DOWN: return "BOS Down";
     }
   return "None";
  }

string GmMktPatternName(const ENUM_GM_MKT_PATTERN p)
  {
   switch(p)
     {
      case GM_MKT_PAT_BULL_ENGULF:  return "Bullish Engulfing";
      case GM_MKT_PAT_BEAR_ENGULF:  return "Bearish Engulfing";
      case GM_MKT_PAT_INSIDE:       return "Inside Bar";
      case GM_MKT_PAT_OUTSIDE:      return "Outside Bar";
      case GM_MKT_PAT_DOJI:         return "Doji";
      case GM_MKT_PAT_PIN_BULL:     return "Pin Bar Bull";
      case GM_MKT_PAT_PIN_BEAR:     return "Pin Bar Bear";
      case GM_MKT_PAT_HAMMER:       return "Hammer";
      case GM_MKT_PAT_SHOOTING_STAR:return "Shooting Star";
      case GM_MKT_PAT_STRONG_BULL:  return "Strong Momentum Bull";
      case GM_MKT_PAT_STRONG_BEAR:  return "Strong Momentum Bear";
      case GM_MKT_PAT_WEAK:         return "Weak Candle";
     }
   return "None";
  }

string GmMktConditionName(const ENUM_GM_MKT_CONDITION c)
  {
   switch(c)
     {
      case GM_MKT_COND_TRENDING:       return "Trending";
      case GM_MKT_COND_STRONG_TREND:   return "Strong Trending";
      case GM_MKT_COND_RANGING:        return "Ranging";
      case GM_MKT_COND_HIGH_VOL:       return "High Volatility";
      case GM_MKT_COND_LOW_VOL:        return "Low Volatility";
      case GM_MKT_COND_BREAKOUT:       return "Breakout";
      case GM_MKT_COND_PULLBACK:       return "Pullback";
      case GM_MKT_COND_CONSOLIDATION:  return "Consolidation";
     }
   return "Uncertain";
  }

#endif // GM_MARKET_ANALYSIS_CONSTANTS_MQH
//+------------------------------------------------------------------+
