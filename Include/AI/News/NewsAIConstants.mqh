//+------------------------------------------------------------------+
//|                                          NewsAIConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     Phase 3 Sprint 5 — News Intelligence (ANALYSIS ONLY)        |
//|     NEVER blocks / skips / cancels Gold Mind trades             |
//+------------------------------------------------------------------+
#ifndef GM_NEWS_AI_CONSTANTS_MQH
#define GM_NEWS_AI_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_NEWS_AI_VERSION        "1.0.0-news"
#define GM_NEWS_LOOKAHEAD_HOURS   48
#define GM_NEWS_LOOKBACK_HOURS    24
#define GM_NEWS_EVENT_MAX         64
#define GM_NEWS_HIST_MAX          128
#define GM_NEWS_EVT_LOG_MAX       200
#define GM_NEWS_DB_PREFIX         "GM_AI_NEWS_"
#define GM_NEWS_THROTTLE_MS       1000
#define GM_NEWS_NO_TRADE_BLOCK    "NO TRADE BLOCK"

enum ENUM_GM_NEWS_IMPACT
  {
   GM_NEWS_IMPACT_VERY_LOW = 0,
   GM_NEWS_IMPACT_LOW,
   GM_NEWS_IMPACT_MEDIUM,
   GM_NEWS_IMPACT_HIGH,
   GM_NEWS_IMPACT_VERY_HIGH,
   GM_NEWS_IMPACT_BLACK_SWAN
  };

enum ENUM_GM_NEWS_EVENT_STATUS
  {
   GM_NEWS_STATUS_UNKNOWN = 0,
   GM_NEWS_STATUS_UPCOMING,
   GM_NEWS_STATUS_LIVE,
   GM_NEWS_STATUS_RELEASED,
   GM_NEWS_STATUS_EXPIRED
  };

enum ENUM_GM_NEWS_PROVIDER
  {
   GM_NEWS_PROVIDER_NONE = 0,
   GM_NEWS_PROVIDER_CALENDAR,
   GM_NEWS_PROVIDER_API,
   GM_NEWS_PROVIDER_BROKER,
   GM_NEWS_PROVIDER_RSS,
   GM_NEWS_PROVIDER_INSTITUTIONAL,
   GM_NEWS_PROVIDER_SYNTHETIC
  };

enum ENUM_GM_NEWS_REACTION
  {
   GM_NEWS_REACT_NONE = 0,
   GM_NEWS_REACT_QUIET,
   GM_NEWS_REACT_SPREAD_EXPAND,
   GM_NEWS_REACT_VOL_SPIKE,
   GM_NEWS_REACT_MOMENTUM,
   GM_NEWS_REACT_CONTINUATION,
   GM_NEWS_REACT_REVERSAL,
   GM_NEWS_REACT_LIQUIDITY,
   GM_NEWS_REACT_ACCELERATION,
   GM_NEWS_REACT_GAP
  };

enum ENUM_GM_NEWS_EVENT_TYPE
  {
   GM_NEWS_EVT_ENGINE_STARTED = 0,
   GM_NEWS_EVT_RECEIVED,
   GM_NEWS_EVT_IMPACT,
   GM_NEWS_EVT_REACTION,
   GM_NEWS_EVT_GOLD,
   GM_NEWS_EVT_DB,
   GM_NEWS_EVT_INFO
  };

string GmNewsImpactName(const ENUM_GM_NEWS_IMPACT i)
  {
   switch(i)
     {
      case GM_NEWS_IMPACT_VERY_LOW:  return "Very Low Impact";
      case GM_NEWS_IMPACT_LOW:       return "Low Impact";
      case GM_NEWS_IMPACT_MEDIUM:    return "Medium Impact";
      case GM_NEWS_IMPACT_HIGH:      return "High Impact";
      case GM_NEWS_IMPACT_VERY_HIGH: return "Very High Impact";
      case GM_NEWS_IMPACT_BLACK_SWAN:return "Black Swan / Exceptional";
     }
   return "Unknown";
  }

string GmNewsStatusName(const ENUM_GM_NEWS_EVENT_STATUS s)
  {
   switch(s)
     {
      case GM_NEWS_STATUS_UPCOMING: return "Upcoming";
      case GM_NEWS_STATUS_LIVE:     return "Live";
      case GM_NEWS_STATUS_RELEASED: return "Released";
      case GM_NEWS_STATUS_EXPIRED:  return "Expired";
     }
   return "Unknown";
  }

string GmNewsProviderName(const ENUM_GM_NEWS_PROVIDER p)
  {
   switch(p)
     {
      case GM_NEWS_PROVIDER_CALENDAR:      return "Economic Calendar";
      case GM_NEWS_PROVIDER_API:           return "News API";
      case GM_NEWS_PROVIDER_BROKER:        return "Broker News Feed";
      case GM_NEWS_PROVIDER_RSS:           return "RSS Feed";
      case GM_NEWS_PROVIDER_INSTITUTIONAL: return "Institutional News";
      case GM_NEWS_PROVIDER_SYNTHETIC:     return "Synthetic Schedule";
     }
   return "None";
  }

string GmNewsReactionName(const ENUM_GM_NEWS_REACTION r)
  {
   switch(r)
     {
      case GM_NEWS_REACT_QUIET:         return "Quiet";
      case GM_NEWS_REACT_SPREAD_EXPAND: return "Spread Expansion";
      case GM_NEWS_REACT_VOL_SPIKE:     return "Volatility Spike";
      case GM_NEWS_REACT_MOMENTUM:      return "Momentum Change";
      case GM_NEWS_REACT_CONTINUATION:  return "Trend Continuation";
      case GM_NEWS_REACT_REVERSAL:      return "Trend Reversal";
      case GM_NEWS_REACT_LIQUIDITY:     return "Liquidity Expansion";
      case GM_NEWS_REACT_ACCELERATION:  return "Price Acceleration";
      case GM_NEWS_REACT_GAP:           return "Gap Detection";
     }
   return "None";
  }

double GmNewsClamp(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

#endif // GM_NEWS_AI_CONSTANTS_MQH
//+------------------------------------------------------------------+
