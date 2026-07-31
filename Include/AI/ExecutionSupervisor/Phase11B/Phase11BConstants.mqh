//+------------------------------------------------------------------+
//|                         Phase11BConstants.mqh                    |
//|     PHASE 11B — Controlled AI Execution Authority (Owner ADR)    |
//|     Pre-activation ONLY — Trading Engine remains MASTER          |
//+------------------------------------------------------------------+
#ifndef GM_PHASE11B_CONSTANTS_MQH
#define GM_PHASE11B_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_P11B_VERSION              "11B.1.0"
#define GM_P11B_LABEL                "PHASE11B_AI_EXECUTION_SUPERVISOR"
#define GM_P11B_UI_PREFIX            "TGM_AI_"
#define GM_P11B_LEARN_FILE           "GM_P11B_EXEC_LEARN.csv"
#define GM_P11B_THROTTLE_MS          1200
#define GM_P11B_FAILSAFE_TIMEOUT_SEC 90
#define GM_P11B_MAX_FROZEN           12
#define GM_P11B_MAX_TRACKED          24
#define GM_P11B_WHY_MAX              256

// Owner defaults (overridable via EA inputs in bridge)
#define GM_P11B_DEF_MAX_LOT_INCREASE_PCT  20.0
#define GM_P11B_DEF_MAX_LOT_REDUCE_PCT    50.0
#define GM_P11B_DEF_MAX_FREEZE_MIN        30
#define GM_P11B_DEF_EMERGENCY_CANCEL      true
#define GM_P11B_DEF_NEWS_PROTECTION       true
#define GM_P11B_DEF_BROKER_PROTECTION     true
#define GM_P11B_DEF_WEEKEND_PROTECTION    true

enum ENUM_GM_P11B_DECISION_BAND
  {
   GM_P11B_BAND_EXTREMELY_STRONG = 0, // 95-100
   GM_P11B_BAND_STRONG,               // 80-94
   GM_P11B_BAND_CAUTION,              // 60-79
   GM_P11B_BAND_HIGH_RISK,            // 40-59
   GM_P11B_BAND_EXTREME_RISK          // <40
  };

enum ENUM_GM_P11B_ACTION
  {
   GM_P11B_ACT_PASS = 0,
   GM_P11B_ACT_INCREASE_LOT,
   GM_P11B_ACT_NORMAL,
   GM_P11B_ACT_REDUCE_LOT,
   GM_P11B_ACT_FREEZE,
   GM_P11B_ACT_CANCEL
  };

enum ENUM_GM_P11B_HEALTH
  {
   GM_P11B_HEALTH_OK = 0,
   GM_P11B_HEALTH_DEGRADED,
   GM_P11B_HEALTH_DISABLED
  };

string GmP11BBandName(const ENUM_GM_P11B_DECISION_BAND b)
  {
   switch(b)
     {
      case GM_P11B_BAND_EXTREMELY_STRONG: return "EXTREMELY STRONG";
      case GM_P11B_BAND_STRONG:           return "STRONG";
      case GM_P11B_BAND_CAUTION:          return "CAUTION";
      case GM_P11B_BAND_HIGH_RISK:        return "HIGH RISK";
      case GM_P11B_BAND_EXTREME_RISK:     return "EXTREME RISK";
     }
   return "UNKNOWN";
  }

string GmP11BActionName(const ENUM_GM_P11B_ACTION a)
  {
   switch(a)
     {
      case GM_P11B_ACT_INCREASE_LOT: return "INCREASE LOT";
      case GM_P11B_ACT_NORMAL:       return "NORMAL";
      case GM_P11B_ACT_REDUCE_LOT:     return "REDUCE LOT";
      case GM_P11B_ACT_FREEZE:         return "FREEZE";
      case GM_P11B_ACT_CANCEL:         return "CANCEL";
     }
   return "PASS";
  }

double GmP11BClamp01(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

ENUM_GM_P11B_DECISION_BAND GmP11BBandFromConfidence(const double confidence)
  {
   if(confidence >= 95.0) return GM_P11B_BAND_EXTREMELY_STRONG;
   if(confidence >= 80.0) return GM_P11B_BAND_STRONG;
   if(confidence >= 60.0) return GM_P11B_BAND_CAUTION;
   if(confidence >= 40.0) return GM_P11B_BAND_HIGH_RISK;
   return GM_P11B_BAND_EXTREME_RISK;
  }

#endif // GM_PHASE11B_CONSTANTS_MQH
//+------------------------------------------------------------------+
