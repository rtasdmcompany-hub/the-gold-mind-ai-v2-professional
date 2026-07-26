//+------------------------------------------------------------------+
//|                              NewsIntelligenceConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 5 Sprint 3 — News Intelligence / Economic Impact      |
//|     ANALYZE / CLASSIFY / EXPLAIN — NEVER disables trading       |
//+------------------------------------------------------------------+
#ifndef GM_NEWS_INTELLIGENCE_CONSTANTS_MQH
#define GM_NEWS_INTELLIGENCE_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_NI_VERSION              "1.0.0-newsintel"
#define GM_NI_DB_PREFIX            "GM_AI_NI_"
#define GM_NI_THROTTLE_MS          3500
#define GM_NI_HIST_MAX             64
#define GM_NI_CACHE_TTL_MS         7200
#define GM_NI_ANALYSIS_ONLY        "NEWS INTELLIGENCE ANALYSIS ONLY"
#define GM_NI_ADVISORY             "ADVISORY ONLY — NEVER DISABLE / SKIP / PAUSE TRADING"
#define GM_NI_OPPORTUNITY          "News events are opportunity zones for Gold Mind H4"

enum ENUM_GM_NI_STATUS
  {
   GM_NI_STATUS_IDLE = 0,
   GM_NI_STATUS_RUNNING,
   GM_NI_STATUS_READY,
   GM_NI_STATUS_CACHED,
   GM_NI_STATUS_ERROR
  };

enum ENUM_GM_NI_IMPACT
  {
   GM_NI_IMPACT_NONE = 0,
   GM_NI_IMPACT_LOW,
   GM_NI_IMPACT_MEDIUM,
   GM_NI_IMPACT_HIGH,
   GM_NI_IMPACT_EXTREME
  };

enum ENUM_GM_NI_GOLD_BIAS
  {
   GM_NI_GOLD_NEUTRAL = 0,
   GM_NI_GOLD_BULLISH,
   GM_NI_GOLD_BEARISH
  };

enum ENUM_GM_NI_EVENT_CLASS
  {
   GM_NI_EVT_UNKNOWN = 0,
   GM_NI_EVT_FOMC,
   GM_NI_EVT_CPI,
   GM_NI_EVT_PPI,
   GM_NI_EVT_NFP,
   GM_NI_EVT_GDP,
   GM_NI_EVT_RATE,
   GM_NI_EVT_ECB,
   GM_NI_EVT_BOE,
   GM_NI_EVT_BOJ,
   GM_NI_EVT_INFLATION,
   GM_NI_EVT_EMPLOYMENT,
   GM_NI_EVT_GEOPOLITICAL,
   GM_NI_EVT_OTHER
  };

string GmNiStatusName(const ENUM_GM_NI_STATUS s)
  {
   switch(s)
     {
      case GM_NI_STATUS_RUNNING: return "Running";
      case GM_NI_STATUS_READY:   return "Ready";
      case GM_NI_STATUS_CACHED:  return "Cached";
      case GM_NI_STATUS_ERROR:   return "Error";
     }
   return "Idle";
  }

string GmNiImpactName(const ENUM_GM_NI_IMPACT i)
  {
   switch(i)
     {
      case GM_NI_IMPACT_LOW:     return "Low Impact";
      case GM_NI_IMPACT_MEDIUM:  return "Medium Impact";
      case GM_NI_IMPACT_HIGH:    return "High Impact";
      case GM_NI_IMPACT_EXTREME: return "Extreme Impact";
      case GM_NI_IMPACT_NONE:    return "No Scheduled Event";
     }
   return "Unknown";
  }

string GmNiGoldBiasName(const ENUM_GM_NI_GOLD_BIAS b)
  {
   switch(b)
     {
      case GM_NI_GOLD_BULLISH: return "Bullish Bias";
      case GM_NI_GOLD_BEARISH: return "Bearish Bias";
      case GM_NI_GOLD_NEUTRAL: return "Neutral Bias";
     }
   return "Neutral Bias";
  }

string GmNiEventClassName(const ENUM_GM_NI_EVENT_CLASS c)
  {
   switch(c)
     {
      case GM_NI_EVT_FOMC:         return "FOMC";
      case GM_NI_EVT_CPI:          return "CPI";
      case GM_NI_EVT_PPI:          return "PPI";
      case GM_NI_EVT_NFP:          return "NFP";
      case GM_NI_EVT_GDP:          return "GDP";
      case GM_NI_EVT_RATE:         return "Interest Rate";
      case GM_NI_EVT_ECB:          return "ECB";
      case GM_NI_EVT_BOE:          return "BOE";
      case GM_NI_EVT_BOJ:          return "BOJ";
      case GM_NI_EVT_INFLATION:    return "Inflation";
      case GM_NI_EVT_EMPLOYMENT:   return "Employment";
      case GM_NI_EVT_GEOPOLITICAL: return "Geopolitical";
      case GM_NI_EVT_OTHER:        return "Other";
     }
   return "Unknown";
  }

double GmNiClamp(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

string GmNiFormatCountdown(const int seconds)
  {
   if(seconds <= 0)
      return "Now / Live";
   const int h = seconds / 3600;
   const int m = (seconds % 3600) / 60;
   const int s = seconds % 60;
   if(h > 0)
      return StringFormat("%dh %dm", h, m);
   if(m > 0)
      return StringFormat("%dm %ds", m, s);
   return StringFormat("%ds", s);
  }

#endif // GM_NEWS_INTELLIGENCE_CONSTANTS_MQH
//+------------------------------------------------------------------+
