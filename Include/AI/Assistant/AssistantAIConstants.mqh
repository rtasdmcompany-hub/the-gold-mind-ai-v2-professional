//+------------------------------------------------------------------+
//|                                     AssistantAIConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     Phase 4 Sprint 1 — Enterprise AI Assistant / Supervisor     |
//|     SUPERVISION ONLY — NEVER executes or mutates Core / Risk    |
//+------------------------------------------------------------------+
#ifndef GM_ASSISTANT_AI_CONSTANTS_MQH
#define GM_ASSISTANT_AI_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_ASSIST_VERSION          "1.0.0-supervisor"
#define GM_ASSIST_DB_PREFIX        "GM_AI_SUP_"
#define GM_ASSIST_THROTTLE_MS      1500
#define GM_ASSIST_HIST_MAX         128
#define GM_ASSIST_WARN_MAX         12
#define GM_ASSIST_ANALYSIS_ONLY    "SUPERVISION ONLY"
#define GM_ASSIST_ADVISORY         "ADVISORY ONLY — NO EXECUTION"

// Soft thresholds (informational — never gates trading)
#define GM_ASSIST_DD_WARN_PCT      5.0
#define GM_ASSIST_DD_EXTREME_PCT   10.0
#define GM_ASSIST_SPREAD_WARN_PTS  40.0
#define GM_ASSIST_MARGIN_WARN_PCT  70.0
#define GM_ASSIST_CONF_LOW         40.0
#define GM_ASSIST_PING_WARN_MS     250

enum ENUM_GM_ASSIST_STATUS
  {
   GM_ASSIST_STATUS_IDLE = 0,
   GM_ASSIST_STATUS_RUNNING,
   GM_ASSIST_STATUS_READY,
   GM_ASSIST_STATUS_WARNING,
   GM_ASSIST_STATUS_ERROR
  };

enum ENUM_GM_ENV_GRADE
  {
   GM_ENV_GRADE_UNKNOWN = 0,
   GM_ENV_GRADE_A,
   GM_ENV_GRADE_B,
   GM_ENV_GRADE_C,
   GM_ENV_GRADE_D,
   GM_ENV_GRADE_F
  };

enum ENUM_GM_WARN_TYPE
  {
   GM_WARN_NONE = 0,
   GM_WARN_HIGH_VOLATILITY,
   GM_WARN_ABNORMAL_SPREAD,
   GM_WARN_WEAK_TREND,
   GM_WARN_EXTREME_DRAWDOWN,
   GM_WARN_CONNECTION,
   GM_WARN_BROKER_DELAY,
   GM_WARN_MARKET_GAP,
   GM_WARN_NEWS_VOLATILITY,
   GM_WARN_LOW_CONFIDENCE,
   GM_WARN_RECOVERY_ACTIVE,
   GM_WARN_MARGIN_PRESSURE,
   GM_WARN_SYSTEM_HEALTH
  };

string GmAssistStatusName(const ENUM_GM_ASSIST_STATUS s)
  {
   switch(s)
     {
      case GM_ASSIST_STATUS_RUNNING: return "Running";
      case GM_ASSIST_STATUS_READY:   return "Ready";
      case GM_ASSIST_STATUS_WARNING: return "Warning";
      case GM_ASSIST_STATUS_ERROR:   return "Error";
     }
   return "Idle";
  }

string GmEnvGradeName(const ENUM_GM_ENV_GRADE g)
  {
   switch(g)
     {
      case GM_ENV_GRADE_A: return "A";
      case GM_ENV_GRADE_B: return "B";
      case GM_ENV_GRADE_C: return "C";
      case GM_ENV_GRADE_D: return "D";
      case GM_ENV_GRADE_F: return "F";
     }
   return "—";
  }

string GmWarnTypeName(const ENUM_GM_WARN_TYPE w)
  {
   switch(w)
     {
      case GM_WARN_HIGH_VOLATILITY:  return "High Volatility";
      case GM_WARN_ABNORMAL_SPREAD:  return "Abnormal Spread";
      case GM_WARN_WEAK_TREND:       return "Weak Trend";
      case GM_WARN_EXTREME_DRAWDOWN: return "Extreme Drawdown";
      case GM_WARN_CONNECTION:       return "Connection Instability";
      case GM_WARN_BROKER_DELAY:     return "Broker Delay";
      case GM_WARN_MARKET_GAP:       return "Market Gap";
      case GM_WARN_NEWS_VOLATILITY:  return "News Volatility";
      case GM_WARN_LOW_CONFIDENCE:   return "Low Confidence";
      case GM_WARN_RECOVERY_ACTIVE:  return "Recovery Active";
      case GM_WARN_MARGIN_PRESSURE:  return "Margin Pressure";
      case GM_WARN_SYSTEM_HEALTH:    return "System Health";
     }
   return "None";
  }

double GmAssistClamp(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

#endif // GM_ASSISTANT_AI_CONSTANTS_MQH
//+------------------------------------------------------------------+
