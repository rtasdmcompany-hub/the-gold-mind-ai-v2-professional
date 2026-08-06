//+------------------------------------------------------------------+
//|                                         Phase14Constants.mqh |
//|  PHASE 14 — Institutional AI Validation Engine (enhancement) |
//|  Does NOT replace H4 Trading Engine — gate before OrderSend  |
//+------------------------------------------------------------------+
#ifndef GM_PHASE14_CONSTANTS_MQH
#define GM_PHASE14_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_P14_VERSION                 "14.1.0"
#define GM_P14_LABEL                   "PHASE14_INSTITUTIONAL_AI_VALIDATION"

#define GM_P14_W_H4                    0.60
#define GM_P14_W_STRUCTURE             0.20
#define GM_P14_W_INSTITUTIONAL         0.10
#define GM_P14_W_MARKET                0.10

#define GM_P14_CONF_EXECUTE            85.0
#define GM_P14_CONF_OPTIONAL           70.0

#define GM_P14_SL_ATR_ADJUST_MAX       0.20   // max SL move = 20% ATR
#define GM_P14_SWING_LOOKBACK          40
#define GM_P14_SWING_STRENGTH          2
#define GM_P14_MAX_SPREAD_POINTS       500.0
#define GM_P14_ATR_SPIKE_MULT          2.50   // vs median of last 14

enum ENUM_GM_P14_VERDICT
  {
   GM_P14_REJECT = 0,
   GM_P14_OPTIONAL,
   GM_P14_EXECUTE
  };

string GmP14VerdictName(const ENUM_GM_P14_VERDICT v)
  {
   switch(v)
     {
      case GM_P14_EXECUTE:  return "EXECUTE";
      case GM_P14_OPTIONAL: return "OPTIONAL";
      case GM_P14_REJECT:   return "REJECT";
     }
   return "REJECT";
  }

#endif // GM_PHASE14_CONSTANTS_MQH
//+------------------------------------------------------------------+
