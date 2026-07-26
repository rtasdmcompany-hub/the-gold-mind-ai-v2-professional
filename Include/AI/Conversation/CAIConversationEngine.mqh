//+------------------------------------------------------------------+
//|                                     CAIConversationEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_CONVERSATION_ENGINE_MQH
#define GM_CAI_CONVERSATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmConversationResult.mqh"
#include "CAICommandSecurityLayer.mqh"
#include "CAIExplanationFramework.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../Intelligence/SGmIntelligenceResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"

class CGmAIConversationEngine
  {
private:
   CGmAICommandSecurityLayer m_sec;
   CGmAIExplanationFramework m_xai;

   ENUM_GM_CHAT_INTENT DetectIntent(const string query) const
     {
      const string q = GmChatLower(query);
      if(StringFind(q, "volatil") >= 0 || StringFind(q, "atr") >= 0)
         return GM_CHAT_INTENT_VOLATILITY;
      if(StringFind(q, "health") >= 0 || StringFind(q, "cpu") >= 0 || StringFind(q, "memory") >= 0)
         return GM_CHAT_INTENT_HEALTH;
      if(StringFind(q, "risk") >= 0 || StringFind(q, "drawdown") >= 0 || StringFind(q, "margin") >= 0)
         return GM_CHAT_INTENT_RISK;
      if(StringFind(q, "performance") >= 0 || StringFind(q, "scorecard") >= 0 ||
         StringFind(q, "accuracy") >= 0)
         return GM_CHAT_INTENT_PERFORMANCE;
      if(StringFind(q, "recover") >= 0)
         return GM_CHAT_INTENT_RECOVERY;
      if(StringFind(q, "learn") >= 0 || StringFind(q, "pattern") >= 0 ||
         StringFind(q, "memory") >= 0)
         return GM_CHAT_INTENT_LEARNING;
      if(StringFind(q, "report") >= 0 || StringFind(q, "executive") >= 0 ||
         StringFind(q, "brief") >= 0)
         return GM_CHAT_INTENT_REPORT;
      if(StringFind(q, "level") >= 0 || StringFind(q, "strategy") >= 0 ||
         StringFind(q, "gold mind") >= 0 || StringFind(q, "how is gold") >= 0 ||
         StringFind(q, "h4") >= 0)
         return GM_CHAT_INTENT_STRATEGY;
      if(StringFind(q, "market") >= 0 || StringFind(q, "condition") >= 0 ||
         StringFind(q, "trend") >= 0 || StringFind(q, "liquidity") >= 0)
         return GM_CHAT_INTENT_MARKET;
      return GM_CHAT_INTENT_GENERAL;
     }

public:
   void Respond(const string query,
                const SGmVolatilityAnalysisResult &vol,
                const SGmIntelligenceResult &intel,
                const SGmAssistantResult &sup,
                SGmConversationResult &r)
     {
      r.user_query = query;
      r.security_status = m_sec.Validate(query);
      r.may_execute = false;
      r.may_modify_orders = false;
      r.may_modify_risk = false;

      if(!m_sec.IsAllowed(r.security_status))
        {
         r.intent = GM_CHAT_INTENT_EXECUTION_BLOCKED;
         r.status = GM_CHAT_STATUS_BLOCKED;
         r.ai_response = m_sec.BlockMessage(r.security_status);
         r.short_response = "Execution disabled — analysis only.";
         return;
        }

      r.intent = DetectIntent(query);
      string body = "";

      switch(r.intent)
        {
         case GM_CHAT_INTENT_MARKET:
            body = r.market_answer;
            break;
         case GM_CHAT_INTENT_VOLATILITY:
            body = m_xai.ExplainVolatility(vol, intel);
            if(StringLen(r.market_answer) > 0)
               body += " " + r.market_answer;
            break;
         case GM_CHAT_INTENT_HEALTH:
            body = r.health_answer;
            break;
         case GM_CHAT_INTENT_RISK:
            body = r.risk_answer + " " + m_xai.ExplainDrawdown(sup);
            break;
         case GM_CHAT_INTENT_PERFORMANCE:
            body = r.performance_answer;
            break;
         case GM_CHAT_INTENT_RECOVERY:
            body = m_xai.ExplainRecovery(sup);
            break;
         case GM_CHAT_INTENT_LEARNING:
            body = r.learning_answer;
            break;
         case GM_CHAT_INTENT_REPORT:
            body = r.report_answer;
            break;
         case GM_CHAT_INTENT_STRATEGY:
            body = r.strategy_explain;
            if(StringLen(r.market_answer) > 0)
               body += " Current environment: " + r.market_answer;
            break;
         default:
            body = "Current environment analysis shows observational monitoring is active. ";
            body += r.market_answer;
            if(StringLen(r.health_answer) > 0)
               body += " " + r.health_answer;
            if(sup.valid && sup.warning_count <= 0)
               body += " No critical supervisory warnings are active.";
            break;
        }

      if(StringLen(body) == 0)
         body = "Gold Mind AI Assistant is ready for informational questions only.";

      r.ai_response = body + " (" + GM_CHAT_ADVISORY + ")";
      if(StringLen(body) > 120)
         r.short_response = StringSubstr(body, 0, 117) + "...";
      else
         r.short_response = body;
      r.status = GM_CHAT_STATUS_READY;
     }
  };

#endif // GM_CAI_CONVERSATION_ENGINE_MQH
//+------------------------------------------------------------------+
