//+------------------------------------------------------------------+
//|                                       LearningAIConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     Phase 3 Sprint 7 — Learning Engine (ANALYTICAL ONLY)        |
//|     NEVER modifies trading rules / risk / execution             |
//+------------------------------------------------------------------+
#ifndef GM_LEARNING_AI_CONSTANTS_MQH
#define GM_LEARNING_AI_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_LEARN_AI_VERSION       "1.0.0-learn"
#define GM_LEARN_KB_VERSION       "KB-1.0.0"
#define GM_LEARN_HIST_MAX         128
#define GM_LEARN_PATTERN_MAX      48
#define GM_LEARN_EVT_MAX          200
#define GM_LEARN_DB_PREFIX        "GM_AI_LEARN_"
#define GM_LEARN_THROTTLE_MS      1500
#define GM_LEARN_ADVISOR_ONLY     "LEARNING ONLY"
#define GM_LEARN_LOOKBACK_DAYS    30

enum ENUM_GM_LEARN_STATUS
  {
   GM_LEARN_STATUS_IDLE = 0,
   GM_LEARN_STATUS_RUNNING,
   GM_LEARN_STATUS_READY,
   GM_LEARN_STATUS_ERROR
  };

enum ENUM_GM_LEARN_PATTERN
  {
   GM_LEARN_PAT_NONE = 0,
   GM_LEARN_PAT_WIN_H4,
   GM_LEARN_PAT_LOSE_H4,
   GM_LEARN_PAT_STRONG_TREND,
   GM_LEARN_PAT_WEAK_TREND,
   GM_LEARN_PAT_VOL_EXPAND,
   GM_LEARN_PAT_VOL_COMPRESS,
   GM_LEARN_PAT_ATR_BEHAVIOUR,
   GM_LEARN_PAT_NEWS_REACTION,
   GM_LEARN_PAT_BREAKOUT,
   GM_LEARN_PAT_REVERSAL,
   GM_LEARN_PAT_CONSOLIDATION,
   GM_LEARN_PAT_RECOVERY_SUCCESS,
   GM_LEARN_PAT_SECOND_ATTEMPT
  };

enum ENUM_GM_LEARN_EXPERIENCE
  {
   GM_LEARN_XP_NOVICE = 0,
   GM_LEARN_XP_APPRENTICE,
   GM_LEARN_XP_COMPETENT,
   GM_LEARN_XP_PROFICIENT,
   GM_LEARN_XP_EXPERT,
   GM_LEARN_XP_MASTER
  };

string GmLearnStatusName(const ENUM_GM_LEARN_STATUS s)
  {
   switch(s)
     {
      case GM_LEARN_STATUS_RUNNING: return "Learning";
      case GM_LEARN_STATUS_READY:   return "Ready";
      case GM_LEARN_STATUS_ERROR:   return "Error";
     }
   return "Idle";
  }

string GmLearnPatternName(const ENUM_GM_LEARN_PATTERN p)
  {
   switch(p)
     {
      case GM_LEARN_PAT_WIN_H4:           return "Winning H4 Structure";
      case GM_LEARN_PAT_LOSE_H4:          return "Losing H4 Structure";
      case GM_LEARN_PAT_STRONG_TREND:     return "Strong Trend Pattern";
      case GM_LEARN_PAT_WEAK_TREND:       return "Weak Trend Pattern";
      case GM_LEARN_PAT_VOL_EXPAND:       return "Volatility Expansion";
      case GM_LEARN_PAT_VOL_COMPRESS:     return "Volatility Compression";
      case GM_LEARN_PAT_ATR_BEHAVIOUR:    return "ATR Behaviour Pattern";
      case GM_LEARN_PAT_NEWS_REACTION:    return "News Reaction Pattern";
      case GM_LEARN_PAT_BREAKOUT:         return "Breakout Pattern";
      case GM_LEARN_PAT_REVERSAL:         return "Reversal Pattern";
      case GM_LEARN_PAT_CONSOLIDATION:    return "Consolidation Pattern";
      case GM_LEARN_PAT_RECOVERY_SUCCESS: return "Recovery Success Pattern";
      case GM_LEARN_PAT_SECOND_ATTEMPT:   return "Second Attempt Success";
     }
   return "None";
  }

string GmLearnXpName(const ENUM_GM_LEARN_EXPERIENCE x)
  {
   switch(x)
     {
      case GM_LEARN_XP_APPRENTICE: return "Apprentice";
      case GM_LEARN_XP_COMPETENT:  return "Competent";
      case GM_LEARN_XP_PROFICIENT: return "Proficient";
      case GM_LEARN_XP_EXPERT:     return "Expert";
      case GM_LEARN_XP_MASTER:     return "Master";
     }
   return "Novice";
  }

double GmLearnClamp(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

#endif // GM_LEARNING_AI_CONSTANTS_MQH
//+------------------------------------------------------------------+
