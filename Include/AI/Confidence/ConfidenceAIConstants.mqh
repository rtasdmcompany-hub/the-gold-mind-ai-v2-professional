//+------------------------------------------------------------------+
//|                                    ConfidenceAIConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     Phase 3 Sprint 6 — Trade Confidence (ADVISOR ONLY)          |
//|     NEVER rejects / modifies / cancels Gold Mind trades         |
//+------------------------------------------------------------------+
#ifndef GM_CONFIDENCE_AI_CONSTANTS_MQH
#define GM_CONFIDENCE_AI_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_CONF_AI_VERSION        "1.0.0-conf"
#define GM_CONF_HIST_MAX          128
#define GM_CONF_EVT_MAX           200
#define GM_CONF_DB_PREFIX         "GM_AI_CONF_"
#define GM_CONF_THROTTLE_MS       500
#define GM_CONF_ADVISOR_ONLY      "ADVISOR ONLY"
#define GM_CONF_NO_EXECUTION      "NO EXECUTION AUTHORITY"

enum ENUM_GM_CONF_ENV
  {
   GM_CONF_ENV_UNKNOWN = 0,
   GM_CONF_ENV_EXCELLENT,
   GM_CONF_ENV_VERY_GOOD,
   GM_CONF_ENV_GOOD,
   GM_CONF_ENV_NEUTRAL,
   GM_CONF_ENV_CAUTION,
   GM_CONF_ENV_HIGH_RISK,
   GM_CONF_ENV_EXTREME_RISK
  };

enum ENUM_GM_CONF_RECO
  {
   GM_CONF_RECO_NONE = 0,
   GM_CONF_RECO_HIGH_PROB,
   GM_CONF_RECO_NORMAL,
   GM_CONF_RECO_ELEVATED_VOL,
   GM_CONF_RECO_WEAK_TREND,
   GM_CONF_RECO_STRONG_MOMENTUM,
   GM_CONF_RECO_SPREAD_EXPAND,
   GM_CONF_RECO_UNCERTAIN,
   GM_CONF_RECO_NEWS_VOL
  };

enum ENUM_GM_CONF_TREND
  {
   GM_CONF_TREND_FLAT = 0,
   GM_CONF_TREND_UP,
   GM_CONF_TREND_DOWN
  };

enum ENUM_GM_CONF_EVENT
  {
   GM_CONF_EVT_CALCULATED = 0,
   GM_CONF_EVT_QUALITY,
   GM_CONF_EVT_ENV,
   GM_CONF_EVT_RECO,
   GM_CONF_EVT_H4,
   GM_CONF_EVT_INFO
  };

/// @brief Configurable multi-factor weights (sum normalized at runtime).
struct SGmConfidenceWeights
  {
   double trend;
   double volatility;
   double atr;
   double news;
   double structure;
   double momentum;
   double spread;
   double session;
   double history;

   void Defaults(void)
     {
      trend = 0.18;
      volatility = 0.14;
      atr = 0.10;
      news = 0.12;
      structure = 0.12;
      momentum = 0.10;
      spread = 0.08;
      session = 0.08;
      history = 0.08;
     }

   void Normalize(void)
     {
      const double s = trend + volatility + atr + news + structure +
                       momentum + spread + session + history;
      if(s <= 0.0)
        {
         Defaults();
         return;
        }
      trend /= s; volatility /= s; atr /= s; news /= s; structure /= s;
      momentum /= s; spread /= s; session /= s; history /= s;
     }
  };

string GmConfEnvName(const ENUM_GM_CONF_ENV e)
  {
   switch(e)
     {
      case GM_CONF_ENV_EXCELLENT:    return "Excellent";
      case GM_CONF_ENV_VERY_GOOD:    return "Very Good";
      case GM_CONF_ENV_GOOD:         return "Good";
      case GM_CONF_ENV_NEUTRAL:      return "Neutral";
      case GM_CONF_ENV_CAUTION:      return "Caution";
      case GM_CONF_ENV_HIGH_RISK:    return "High Risk";
      case GM_CONF_ENV_EXTREME_RISK: return "Extreme Risk";
     }
   return "Unknown";
  }

string GmConfRecoName(const ENUM_GM_CONF_RECO r)
  {
   switch(r)
     {
      case GM_CONF_RECO_HIGH_PROB:       return "High Probability Environment";
      case GM_CONF_RECO_NORMAL:          return "Normal Trading Conditions";
      case GM_CONF_RECO_ELEVATED_VOL:    return "Elevated Volatility";
      case GM_CONF_RECO_WEAK_TREND:      return "Weak Trend";
      case GM_CONF_RECO_STRONG_MOMENTUM: return "Strong Momentum";
      case GM_CONF_RECO_SPREAD_EXPAND:   return "Spread Expansion";
      case GM_CONF_RECO_UNCERTAIN:       return "Market Uncertain";
      case GM_CONF_RECO_NEWS_VOL:        return "News Volatility Expected";
     }
   return "None";
  }

string GmConfTrendName(const ENUM_GM_CONF_TREND t)
  {
   if(t == GM_CONF_TREND_UP) return "Rising";
   if(t == GM_CONF_TREND_DOWN) return "Falling";
   return "Flat";
  }

double GmConfClamp(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

#endif // GM_CONFIDENCE_AI_CONSTANTS_MQH
//+------------------------------------------------------------------+
