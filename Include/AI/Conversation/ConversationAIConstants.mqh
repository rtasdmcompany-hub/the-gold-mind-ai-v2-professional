//+------------------------------------------------------------------+
//|                                   ConversationAIConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 4 Sprint 5 — Conversational Assistant / NL Interface  |
//|     UNDERSTAND / EXPLAIN / GUIDE / REPORT — NEVER executes      |
//+------------------------------------------------------------------+
#ifndef GM_CONVERSATION_AI_CONSTANTS_MQH
#define GM_CONVERSATION_AI_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_CHAT_VERSION           "1.0.0-chat"
#define GM_CHAT_DB_PREFIX         "GM_AI_CHAT_"
#define GM_CHAT_THROTTLE_MS       2000
#define GM_CHAT_HIST_MAX          64
#define GM_CHAT_CTX_MAX           12
#define GM_CHAT_CACHE_TTL_MS      4000
#define GM_CHAT_ANALYSIS_ONLY     "CONVERSATION ONLY"
#define GM_CHAT_ADVISORY          "ADVISORY ONLY — NO EXECUTION"
#define GM_CHAT_BLOCK_MSG         "Execution commands are disabled. The Gold Mind AI Assistant provides analysis only."

enum ENUM_GM_CHAT_STATUS
  {
   GM_CHAT_STATUS_IDLE = 0,
   GM_CHAT_STATUS_RUNNING,
   GM_CHAT_STATUS_READY,
   GM_CHAT_STATUS_BLOCKED,
   GM_CHAT_STATUS_CACHED,
   GM_CHAT_STATUS_ERROR
  };

enum ENUM_GM_CHAT_INTENT
  {
   GM_CHAT_INTENT_UNKNOWN = 0,
   GM_CHAT_INTENT_MARKET,
   GM_CHAT_INTENT_VOLATILITY,
   GM_CHAT_INTENT_HEALTH,
   GM_CHAT_INTENT_RISK,
   GM_CHAT_INTENT_PERFORMANCE,
   GM_CHAT_INTENT_RECOVERY,
   GM_CHAT_INTENT_LEARNING,
   GM_CHAT_INTENT_REPORT,
   GM_CHAT_INTENT_STRATEGY,
   GM_CHAT_INTENT_GENERAL,
   GM_CHAT_INTENT_EXECUTION_BLOCKED
  };

enum ENUM_GM_CHAT_SECURITY
  {
   GM_CHAT_SEC_ALLOW = 0,
   GM_CHAT_SEC_BLOCK_TRADE,
   GM_CHAT_SEC_BLOCK_ORDER,
   GM_CHAT_SEC_BLOCK_RISK,
   GM_CHAT_SEC_BLOCK_STRATEGY
  };

string GmChatStatusName(const ENUM_GM_CHAT_STATUS s)
  {
   switch(s)
     {
      case GM_CHAT_STATUS_RUNNING: return "Running";
      case GM_CHAT_STATUS_READY:   return "Ready";
      case GM_CHAT_STATUS_BLOCKED: return "Blocked";
      case GM_CHAT_STATUS_CACHED:  return "Cached";
      case GM_CHAT_STATUS_ERROR:   return "Error";
     }
   return "Idle";
  }

string GmChatIntentName(const ENUM_GM_CHAT_INTENT i)
  {
   switch(i)
     {
      case GM_CHAT_INTENT_MARKET:            return "Market";
      case GM_CHAT_INTENT_VOLATILITY:        return "Volatility";
      case GM_CHAT_INTENT_HEALTH:            return "System Health";
      case GM_CHAT_INTENT_RISK:              return "Risk";
      case GM_CHAT_INTENT_PERFORMANCE:       return "Performance";
      case GM_CHAT_INTENT_RECOVERY:          return "Recovery";
      case GM_CHAT_INTENT_LEARNING:          return "Learning";
      case GM_CHAT_INTENT_REPORT:            return "Report";
      case GM_CHAT_INTENT_STRATEGY:          return "Strategy Explain";
      case GM_CHAT_INTENT_GENERAL:           return "General";
      case GM_CHAT_INTENT_EXECUTION_BLOCKED: return "Execution Blocked";
     }
   return "Unknown";
  }

string GmChatSecName(const ENUM_GM_CHAT_SECURITY s)
  {
   switch(s)
     {
      case GM_CHAT_SEC_ALLOW:          return "ALLOW";
      case GM_CHAT_SEC_BLOCK_TRADE:    return "BLOCK_TRADE";
      case GM_CHAT_SEC_BLOCK_ORDER:    return "BLOCK_ORDER";
      case GM_CHAT_SEC_BLOCK_RISK:     return "BLOCK_RISK";
      case GM_CHAT_SEC_BLOCK_STRATEGY: return "BLOCK_STRATEGY";
     }
   return "UNKNOWN";
  }

double GmChatClamp(const double v)
  {
   if(v < 0.0) return 0.0;
   if(v > 100.0) return 100.0;
   return v;
  }

string GmChatLower(string s)
  {
   StringToLower(s);
   return s;
  }

#endif // GM_CONVERSATION_AI_CONSTANTS_MQH
//+------------------------------------------------------------------+
