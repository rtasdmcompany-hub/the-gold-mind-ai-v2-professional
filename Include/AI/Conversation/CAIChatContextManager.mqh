//+------------------------------------------------------------------+
//|                                  CAIChatContextManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_CHAT_CONTEXT_MANAGER_MQH
#define GM_CAI_CHAT_CONTEXT_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ConversationAIConstants.mqh"

class CGmAIChatContextManager
  {
private:
   string m_last_query;
   string m_prev_query;
   string m_last_response;
   string m_market_ctx;
   string m_session_ctx;
   string m_history[GM_CHAT_CTX_MAX];
   int    m_n;

public:
                     CGmAIChatContextManager(void)
                       : m_last_query(""), m_prev_query(""), m_last_response(""),
                         m_market_ctx(""), m_session_ctx(""), m_n(0) {}

   void SetMarketContext(const string ctx) { m_market_ctx = ctx; }
   void SetSessionContext(const string ctx) { m_session_ctx = ctx; }

   void Push(const string query, const string response)
     {
      m_prev_query = m_last_query;
      m_last_query = query;
      m_last_response = response;
      const string line = StringFormat("%s => %s", query, response);
      if(m_n < GM_CHAT_CTX_MAX)
         m_history[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_CHAT_CTX_MAX; i++)
            m_history[i - 1] = m_history[i];
         m_history[GM_CHAT_CTX_MAX - 1] = line;
        }
     }

   string LastQuery(void) const { return m_last_query; }
   string PrevQuery(void) const { return m_prev_query; }
   string LastResponse(void) const { return m_last_response; }

   string Summary(void) const
     {
      return StringFormat("PrevQ=%s | MarketCtx=%s | SessionCtx=%s | Turns=%d",
                          (StringLen(m_prev_query) > 0 ? m_prev_query : "none"),
                          m_market_ctx, m_session_ctx, m_n);
     }
  };

#endif // GM_CAI_CHAT_CONTEXT_MANAGER_MQH
//+------------------------------------------------------------------+
