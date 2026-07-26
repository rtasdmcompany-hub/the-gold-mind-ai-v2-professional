//+------------------------------------------------------------------+
//|                                       DecisionAIConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     Phase 3 Sprint 8 — Decision Support & XAI (ADVISORY ONLY)   |
//+------------------------------------------------------------------+
#ifndef GM_DECISION_AI_CONSTANTS_MQH
#define GM_DECISION_AI_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_DEC_AI_VERSION         "1.0.0-xai"
#define GM_DEC_HIST_MAX           128
#define GM_DEC_SIM_MAX            16
#define GM_DEC_FACTOR_MAX         8
#define GM_DEC_REASON_MAX         8
#define GM_DEC_EVT_MAX            200
#define GM_DEC_DB_PREFIX          "GM_AI_DEC_"
#define GM_DEC_THROTTLE_MS        800
#define GM_DEC_ADVISORY_ONLY      "ADVISORY ONLY"
#define GM_DEC_NO_EXECUTION       "NO EXECUTION AUTHORITY"

enum ENUM_GM_DEC_RECO
  {
   GM_DEC_RECO_NONE = 0,
   GM_DEC_RECO_FAVORABLE,
   GM_DEC_RECO_NORMAL,
   GM_DEC_RECO_CAUTION,
   GM_DEC_RECO_ELEVATED_RISK,
   GM_DEC_RECO_UNCERTAIN
  };

enum ENUM_GM_DEC_STRATEGY_MATCH
  {
   GM_DEC_MATCH_UNKNOWN = 0,
   GM_DEC_MATCH_VERY_STRONG,
   GM_DEC_MATCH_STRONG,
   GM_DEC_MATCH_AVERAGE,
   GM_DEC_MATCH_WEAK
  };

string GmDecRecoName(const ENUM_GM_DEC_RECO r)
  {
   switch(r)
     {
      case GM_DEC_RECO_FAVORABLE:     return "Favorable Environment";
      case GM_DEC_RECO_NORMAL:        return "Normal Conditions";
      case GM_DEC_RECO_CAUTION:       return "Caution Advised";
      case GM_DEC_RECO_ELEVATED_RISK: return "Elevated Risk Environment";
      case GM_DEC_RECO_UNCERTAIN:     return "Market Uncertain";
     }
   return "None";
  }

string GmDecMatchName(const ENUM_GM_DEC_STRATEGY_MATCH m)
  {
   switch(m)
     {
      case GM_DEC_MATCH_VERY_STRONG: return "Very Strong Match";
      case GM_DEC_MATCH_STRONG:      return "Strong Match";
      case GM_DEC_MATCH_AVERAGE:     return "Average Match";
      case GM_DEC_MATCH_WEAK:        return "Weak Match";
     }
   return "Unknown";
  }

double GmDecClamp(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

#endif // GM_DECISION_AI_CONSTANTS_MQH
//+------------------------------------------------------------------+
