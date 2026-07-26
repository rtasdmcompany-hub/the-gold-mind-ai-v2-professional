//+------------------------------------------------------------------+
//|                                    SGmConversationResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_CONVERSATION_RESULT_MQH
#define GM_SGM_CONVERSATION_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ConversationAIConstants.mqh"

struct SGmConversationResult
  {
   datetime              stamped_at;
   string                symbol;
   ulong                 session_id;
   ENUM_GM_CHAT_STATUS   status;

   string                user_query;
   string                ai_response;
   string                short_response;
   ENUM_GM_CHAT_INTENT   intent;
   ENUM_GM_CHAT_SECURITY security_status;

   string                market_answer;
   string                risk_answer;
   string                performance_answer;
   string                learning_answer;
   string                health_answer;
   string                report_answer;
   string                strategy_explain;

   string                knowledge_snippet;
   string                context_summary;
   string                voice_status;     // foundation only
   bool                  voice_activated;  // ALWAYS false

   string                assistant_status;
   string                advisory_status;
   string                insight;
   bool                  may_execute;
   bool                  may_modify_orders;
   bool                  may_modify_risk;
   bool                  from_cache;
   bool                  valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = "";
      session_id = 0;
      status = GM_CHAT_STATUS_IDLE;
      user_query = "";
      ai_response = "";
      short_response = "";
      intent = GM_CHAT_INTENT_UNKNOWN;
      security_status = GM_CHAT_SEC_ALLOW;
      market_answer = risk_answer = performance_answer = "";
      learning_answer = health_answer = report_answer = strategy_explain = "";
      knowledge_snippet = context_summary = "";
      voice_status = "Voice Assistant: INACTIVE (architecture only)";
      voice_activated = false;
      assistant_status = "Idle";
      advisory_status = GM_CHAT_ADVISORY;
      insight = "";
      may_execute = false;
      may_modify_orders = false;
      may_modify_risk = false;
      from_cache = false;
      valid = false;
     }
  };

#endif // GM_SGM_CONVERSATION_RESULT_MQH
//+------------------------------------------------------------------+
