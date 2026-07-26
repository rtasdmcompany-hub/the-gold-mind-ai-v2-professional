//+------------------------------------------------------------------+
//|                            PortfolioIntelligenceConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 5 Sprint 6 — Portfolio / Multi-Symbol / Capital       |
//|     MONITOR / ANALYZE / REPORT — XAUUSD ONLY execution live     |
//+------------------------------------------------------------------+
#ifndef GM_PORTFOLIO_INTELLIGENCE_CONSTANTS_MQH
#define GM_PORTFOLIO_INTELLIGENCE_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_PI_VERSION              "1.0.0-portfolio"
#define GM_PI_DB_PREFIX            "GM_AI_PI_"
#define GM_PI_THROTTLE_MS          4000
#define GM_PI_HIST_MAX             64
#define GM_PI_CACHE_TTL_MS         8000
#define GM_PI_SYMBOL_MAX           9
#define GM_PI_ANALYSIS_ONLY        "PORTFOLIO INTELLIGENCE ANALYSIS ONLY"
#define GM_PI_ADVISORY             "ADVISORY ONLY — NO EXECUTION / NO AUTO SYMBOL ENABLE"
#define GM_PI_LIVE_SYMBOL          "XAUUSD"
#define GM_PI_CONTEXT              "H4 | 3Buy/3Sell | ATR-14 | 30pip SL | BE | 80% Partial | 20% Trail | Second Attempt | XAUUSD ONLY"

enum ENUM_GM_PI_STATUS
  {
   GM_PI_STATUS_IDLE = 0,
   GM_PI_STATUS_RUNNING,
   GM_PI_STATUS_READY,
   GM_PI_STATUS_CACHED,
   GM_PI_STATUS_ERROR
  };

enum ENUM_GM_PI_HEALTH
  {
   GM_PI_HEALTH_UNKNOWN = 0,
   GM_PI_HEALTH_CRITICAL,
   GM_PI_HEALTH_WEAK,
   GM_PI_HEALTH_STABLE,
   GM_PI_HEALTH_STRONG,
   GM_PI_HEALTH_EXCELLENT
  };

enum ENUM_GM_PI_CORR_CLASS
  {
   GM_PI_CORR_NONE = 0,
   GM_PI_CORR_WEAK,
   GM_PI_CORR_MODERATE,
   GM_PI_CORR_STRONG,
   GM_PI_CORR_POSITIVE,
   GM_PI_CORR_NEGATIVE
  };

string GmPiStatusName(const ENUM_GM_PI_STATUS s)
  {
   switch(s)
     {
      case GM_PI_STATUS_RUNNING: return "Running";
      case GM_PI_STATUS_READY:   return "Ready";
      case GM_PI_STATUS_CACHED:  return "Cached";
      case GM_PI_STATUS_ERROR:   return "Error";
     }
   return "Idle";
  }

string GmPiHealthName(const ENUM_GM_PI_HEALTH h)
  {
   switch(h)
     {
      case GM_PI_HEALTH_CRITICAL:  return "Critical";
      case GM_PI_HEALTH_WEAK:      return "Weak";
      case GM_PI_HEALTH_STABLE:    return "Stable";
      case GM_PI_HEALTH_STRONG:    return "Strong";
      case GM_PI_HEALTH_EXCELLENT: return "Excellent";
     }
   return "Unknown";
  }

string GmPiCorrClassName(const ENUM_GM_PI_CORR_CLASS c)
  {
   switch(c)
     {
      case GM_PI_CORR_WEAK:     return "Weak Correlation";
      case GM_PI_CORR_MODERATE: return "Moderate Correlation";
      case GM_PI_CORR_STRONG:   return "Strong Correlation";
      case GM_PI_CORR_POSITIVE: return "Positive Correlation";
      case GM_PI_CORR_NEGATIVE: return "Negative Correlation";
     }
   return "No Correlation";
  }

double GmPiClamp(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

#endif // GM_PORTFOLIO_INTELLIGENCE_CONSTANTS_MQH
//+------------------------------------------------------------------+
