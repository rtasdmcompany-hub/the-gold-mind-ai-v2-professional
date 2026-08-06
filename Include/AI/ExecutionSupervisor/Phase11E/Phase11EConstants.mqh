//+------------------------------------------------------------------+
//|                         Phase11EConstants.mqh                    |
//|  PHASE 11E — Dynamic AI Pre-Activation Execution Engine (Owner)  |
//|  Continuous monitor BEFORE activation — Trading Engine MASTER    |
//+------------------------------------------------------------------+
#ifndef GM_PHASE11E_CONSTANTS_MQH
#define GM_PHASE11E_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_P11E_VERSION              "11E.1.0"
#define GM_P11E_LABEL                "PHASE11E_DYNAMIC_PRE_ACTIVATION_ENGINE"
#define GM_P11E_UI_PREFIX            "TGM_AI_"
#define GM_P11E_LEARN_FILE           "GM_P11E_EXEC_LEARN.csv"
#define GM_P11E_THROTTLE_MS          500
#define GM_P11E_SCHEDULE_SEC         5
#define GM_P11E_FAILSAFE_TIMEOUT_SEC 120
#define GM_P11E_MAX_FROZEN           16
#define GM_P11E_MAX_TRACKED          32
#define GM_P11E_WHY_MAX              320
#define GM_P11E_LOT_EPS              0.0000001

#define GM_P11E_DEF_MAX_LOT_INCREASE_PCT  20.0
#define GM_P11E_DEF_MAX_LOT_REDUCE_PCT    50.0
#define GM_P11E_DEF_MAX_FREEZE_MIN        30
#define GM_P11E_DEF_EMERGENCY_CANCEL      true
#define GM_P11E_DEF_NEWS_PROTECTION       true
#define GM_P11E_DEF_BROKER_PROTECTION     true
#define GM_P11E_DEF_WEEKEND_PROTECTION    true
#define GM_P11E_DEF_DYNAMIC_LOT           true

#define GM_P11E_PANEL_W                   280
#define GM_P11E_PANEL_H                   286
#define GM_P11E_PANEL_H_MIN               36
#define GM_P11E_PANEL_HEADER_H            28
#define GM_P11E_PANEL_BTN_W               28
#define GM_P11E_PANEL_BTN_H               22

enum ENUM_GM_P11E_DECISION_BAND
  {
   GM_P11E_BAND_EXTREMELY_STRONG = 0, // 95-100
   GM_P11E_BAND_STRONG,               // 80-94
   GM_P11E_BAND_CAUTION,              // 60-79
   GM_P11E_BAND_HIGH_RISK,            // 40-59
   GM_P11E_BAND_EXTREME_RISK          // <40
  };

enum ENUM_GM_P11E_ACTION
  {
   GM_P11E_ACT_PASS = 0,
   GM_P11E_ACT_INCREASE_LOT,
   GM_P11E_ACT_RESTORE_LOT,
   GM_P11E_ACT_REDUCE_LOT,
   GM_P11E_ACT_FREEZE,
   GM_P11E_ACT_RESUME,
   GM_P11E_ACT_CANCEL,
   GM_P11E_ACT_READONLY
  };

enum ENUM_GM_P11E_HEALTH
  {
   GM_P11E_HEALTH_OK = 0,
   GM_P11E_HEALTH_DEGRADED,
   GM_P11E_HEALTH_DISABLED
  };

enum ENUM_GM_P11E_PENDING_STATE
  {
   GM_P11E_STATE_LIVE = 0,
   GM_P11E_STATE_FROZEN,
   GM_P11E_STATE_CANCELLED,
   GM_P11E_STATE_ACTIVATED_READONLY,
   GM_P11E_STATE_EXPIRED
  };

string GmP11EBandName(const ENUM_GM_P11E_DECISION_BAND b)
  {
   switch(b)
     {
      case GM_P11E_BAND_EXTREMELY_STRONG: return "EXTREMELY STRONG";
      case GM_P11E_BAND_STRONG:           return "STRONG";
      case GM_P11E_BAND_CAUTION:          return "CAUTION";
      case GM_P11E_BAND_HIGH_RISK:        return "HIGH RISK";
      case GM_P11E_BAND_EXTREME_RISK:     return "EXTREME RISK";
     }
   return "UNKNOWN";
  }

string GmP11EActionName(const ENUM_GM_P11E_ACTION a)
  {
   switch(a)
     {
      case GM_P11E_ACT_INCREASE_LOT: return "INCREASE LOT";
      case GM_P11E_ACT_RESTORE_LOT:  return "RESTORE LOT";
      case GM_P11E_ACT_REDUCE_LOT:   return "REDUCE LOT";
      case GM_P11E_ACT_FREEZE:       return "FREEZE";
      case GM_P11E_ACT_RESUME:       return "RESUME";
      case GM_P11E_ACT_CANCEL:       return "CANCEL";
      case GM_P11E_ACT_READONLY:     return "READ ONLY";
     }
   return "PASS";
  }

string GmP11EStateName(const ENUM_GM_P11E_PENDING_STATE s)
  {
   switch(s)
     {
      case GM_P11E_STATE_LIVE:               return "LIVE";
      case GM_P11E_STATE_FROZEN:             return "FROZEN";
      case GM_P11E_STATE_CANCELLED:          return "CANCELLED";
      case GM_P11E_STATE_ACTIVATED_READONLY: return "ACTIVATED/RO";
      case GM_P11E_STATE_EXPIRED:            return "EXPIRED";
     }
   return "UNKNOWN";
  }

double GmP11EClamp01(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

ENUM_GM_P11E_DECISION_BAND GmP11EBandFromConfidence(const double confidence)
  {
   if(confidence >= 95.0) return GM_P11E_BAND_EXTREMELY_STRONG;
   if(confidence >= 80.0) return GM_P11E_BAND_STRONG;
   if(confidence >= 60.0) return GM_P11E_BAND_CAUTION;
   if(confidence >= 40.0) return GM_P11E_BAND_HIGH_RISK;
   return GM_P11E_BAND_EXTREME_RISK;
  }

#endif // GM_PHASE11E_CONSTANTS_MQH
//+------------------------------------------------------------------+
