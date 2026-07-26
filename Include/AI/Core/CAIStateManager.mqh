//+------------------------------------------------------------------+
//|                                           CAIStateManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CAI_STATE_MANAGER_MQH
#define GM_CAI_STATE_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "Phase3AIConstants.mqh"
#include "../../Logging/CLogger.mqh"

class CGmAIStateManager
  {
private:
   CGmLogger            *m_logger;
   ENUM_GM_AI_CORE_STATE m_state;
   ENUM_GM_AI_CORE_STATE m_prev;
   bool                  m_ready;

public:
                     CGmAIStateManager(void)
                       : m_logger(NULL),
                         m_state(GM_AI_CORE_STATE_DISABLED),
                         m_prev(GM_AI_CORE_STATE_DISABLED),
                         m_ready(false) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_state = GM_AI_CORE_STATE_INITIALIZING;
      m_prev = GM_AI_CORE_STATE_DISABLED;
      m_ready = true;
     }

   bool IsReady(void) const { return m_ready; }
   ENUM_GM_AI_CORE_STATE State(void) const { return m_state; }
   string StateName(void) const { return GmAICoreStateName(m_state); }

   bool SetState(const ENUM_GM_AI_CORE_STATE next)
     {
      if(!m_ready)
         return false;
      if(next == m_state)
         return true;
      m_prev = m_state;
      m_state = next;
      if(m_logger != NULL)
         m_logger.Info(StringFormat("AI State Changed | %s -> %s",
                                    GmAICoreStateName(m_prev),
                                    GmAICoreStateName(m_state)),
                       "AIState");
      return true;
     }
  };

#endif // GM_CAI_STATE_MANAGER_MQH
//+------------------------------------------------------------------+
