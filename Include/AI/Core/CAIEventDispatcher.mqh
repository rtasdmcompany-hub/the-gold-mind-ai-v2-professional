//+------------------------------------------------------------------+
//|                                        CAIEventDispatcher.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CAI_EVENT_DISPATCHER_MQH
#define GM_CAI_EVENT_DISPATCHER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "Phase3AIConstants.mqh"
#include "../../Logging/CLogger.mqh"

class CGmAIEventDispatcher
  {
private:
   CGmLogger *m_logger;
   string     m_events[GM_AI_CORE_EVENT_MAX];
   int        m_n;
   bool       m_ready;

public:
                     CGmAIEventDispatcher(void)
                       : m_logger(NULL), m_n(0), m_ready(false) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_n = 0;
      m_ready = true;
     }

   bool IsReady(void) const { return m_ready; }
   int Count(void) const { return m_n; }

   void Dispatch(const string type, const string detail)
     {
      if(!m_ready)
         return;
      const string line = StringFormat("%s | %s | %s",
                                       TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS),
                                       type, detail);
      if(m_n < GM_AI_CORE_EVENT_MAX)
         m_events[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_AI_CORE_EVENT_MAX; i++)
            m_events[i - 1] = m_events[i];
         m_events[GM_AI_CORE_EVENT_MAX - 1] = line;
        }
      if(m_logger != NULL)
         m_logger.Info(StringFormat("%s | %s", type, detail), "AIEvent");
     }

   string Latest(void) const
     {
      return (m_n > 0) ? m_events[m_n - 1] : "";
     }
  };

#endif // GM_CAI_EVENT_DISPATCHER_MQH
//+------------------------------------------------------------------+
