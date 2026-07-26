//+------------------------------------------------------------------+
//|                               CConversationResponseCache.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CCONVERSATION_RESPONSE_CACHE_MQH
#define GM_CCONVERSATION_RESPONSE_CACHE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ConversationAIConstants.mqh"

class CGmConversationResponseCache
  {
private:
   string m_query;
   string m_response;
   ulong  m_until;
   bool   m_have;

public:
                     CGmConversationResponseCache(void)
                       : m_query(""), m_response(""), m_until(0), m_have(false) {}

   void Store(const string query, const string response, const ulong now)
     {
      m_query = query;
      m_response = response;
      m_until = now + (ulong)GM_CHAT_CACHE_TTL_MS;
      m_have = true;
     }

   bool TryGet(const string query, const ulong now, string &out_response) const
     {
      if(!m_have || now >= m_until)
         return false;
      if(query != m_query)
         return false;
      out_response = m_response;
      return true;
     }
  };

#endif // GM_CCONVERSATION_RESPONSE_CACHE_MQH
//+------------------------------------------------------------------+
