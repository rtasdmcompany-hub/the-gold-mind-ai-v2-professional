//+------------------------------------------------------------------+
//|                                     VolatilityAIConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     Phase 3 Sprint 4 — Volatility Intelligence (ANALYSIS ONLY)  |
//+------------------------------------------------------------------+
#ifndef GM_VOLATILITY_AI_CONSTANTS_MQH
#define GM_VOLATILITY_AI_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_VOL_AI_VERSION         "1.0.0-vol"
#define GM_VOL_ATR_PERIOD         14
#define GM_VOL_LOOKBACK           48
#define GM_VOL_HIST_MAX           128
#define GM_VOL_EVENT_MAX          200
#define GM_VOL_DB_PREFIX          "GM_AI_VOL_"
#define GM_VOL_THROTTLE_MS        500

enum ENUM_GM_ATR_TREND
  {
   GM_ATR_TREND_UNKNOWN = 0,
   GM_ATR_TREND_EXPANDING,
   GM_ATR_TREND_COMPRESSING,
   GM_ATR_TREND_STABLE
  };

enum ENUM_GM_MARKET_ENERGY
  {
   GM_ENERGY_UNKNOWN = 0,
   GM_ENERGY_LOW,
   GM_ENERGY_BUILDING,
   GM_ENERGY_NORMAL,
   GM_ENERGY_STRONG,
   GM_ENERGY_EXTREME,
   GM_ENERGY_EXPLOSIVE
  };

enum ENUM_GM_VOL_PHASE
  {
   GM_VOL_PHASE_UNCERTAIN = 0,
   GM_VOL_PHASE_CALM,
   GM_VOL_PHASE_NORMAL,
   GM_VOL_PHASE_EXPANDING,
   GM_VOL_PHASE_CONTRACTING,
   GM_VOL_PHASE_VOLATILE,
   GM_VOL_PHASE_EXPLOSIVE,
   GM_VOL_PHASE_NEWS_DRIVEN,
   GM_VOL_PHASE_EXHAUSTED
  };

enum ENUM_GM_VOL_EVENT
  {
   GM_VOL_EVT_ATR_UPDATED = 0,
   GM_VOL_EVT_VOL_UPDATED,
   GM_VOL_EVT_ENERGY_UPDATED,
   GM_VOL_EVT_RANGE_UPDATED,
   GM_VOL_EVT_PROB_UPDATED,
   GM_VOL_EVT_EXPANSION,
   GM_VOL_EVT_COMPRESSION,
   GM_VOL_EVT_ENERGY_SPIKE,
   GM_VOL_EVT_INFO
  };

string GmAtrTrendName(const ENUM_GM_ATR_TREND t)
  {
   switch(t)
     {
      case GM_ATR_TREND_EXPANDING:   return "Expanding";
      case GM_ATR_TREND_COMPRESSING: return "Compressing";
      case GM_ATR_TREND_STABLE:      return "Stable";
     }
   return "Unknown";
  }

string GmEnergyName(const ENUM_GM_MARKET_ENERGY e)
  {
   switch(e)
     {
      case GM_ENERGY_LOW:       return "Low Energy";
      case GM_ENERGY_BUILDING:  return "Building Energy";
      case GM_ENERGY_NORMAL:    return "Normal Energy";
      case GM_ENERGY_STRONG:    return "Strong Energy";
      case GM_ENERGY_EXTREME:   return "Extreme Energy";
      case GM_ENERGY_EXPLOSIVE: return "Explosive Energy";
     }
   return "Unknown";
  }

string GmVolPhaseName(const ENUM_GM_VOL_PHASE p)
  {
   switch(p)
     {
      case GM_VOL_PHASE_CALM:         return "Calm Market";
      case GM_VOL_PHASE_NORMAL:       return "Normal Market";
      case GM_VOL_PHASE_EXPANDING:    return "Expanding Market";
      case GM_VOL_PHASE_CONTRACTING:  return "Contracting Market";
      case GM_VOL_PHASE_VOLATILE:     return "Volatile Market";
      case GM_VOL_PHASE_EXPLOSIVE:    return "Explosive Market";
      case GM_VOL_PHASE_NEWS_DRIVEN:  return "News Driven Movement";
      case GM_VOL_PHASE_EXHAUSTED:    return "Exhausted Movement";
     }
   return "Uncertain";
  }

string GmVolEventName(const ENUM_GM_VOL_EVENT e)
  {
   switch(e)
     {
      case GM_VOL_EVT_ATR_UPDATED:    return "ATR Updated";
      case GM_VOL_EVT_VOL_UPDATED:    return "Volatility Updated";
      case GM_VOL_EVT_ENERGY_UPDATED: return "Energy Updated";
      case GM_VOL_EVT_RANGE_UPDATED:  return "Range Updated";
      case GM_VOL_EVT_PROB_UPDATED:   return "Probability Updated";
      case GM_VOL_EVT_EXPANSION:      return "ATR Expansion";
      case GM_VOL_EVT_COMPRESSION:    return "ATR Compression";
      case GM_VOL_EVT_ENERGY_SPIKE:   return "Energy Spike";
     }
   return "Info";
  }

double GmClamp01(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

#endif // GM_VOLATILITY_AI_CONSTANTS_MQH
//+------------------------------------------------------------------+
