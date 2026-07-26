//+------------------------------------------------------------------+
//|                                           CMacTaskQueue.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CMAC_TASK_QUEUE_MQH
#define GM_CMAC_TASK_QUEUE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "MultiAccountCenterConstants.mqh"

class CGmMacTaskQueue
  {
private:
   ENUM_GM_MAC_QUEUE m_status;
   bool              m_cache_valid;
   ulong             m_cache_ms;

public:
                     CGmMacTaskQueue(void)
                       : m_status(GM_MAC_Q_IDLE), m_cache_valid(false), m_cache_ms(0) {}

   void Reset(void)
     {
      m_status = GM_MAC_Q_IDLE;
      m_cache_valid = false;
      m_cache_ms = 0;
     }

   ENUM_GM_MAC_QUEUE Status(void) const { return m_status; }
   void MarkRunning(void) { m_status = GM_MAC_Q_RUNNING; }

   void MarkCached(void)
     {
      m_status = GM_MAC_Q_CACHED;
      m_cache_valid = true;
      m_cache_ms = GetTickCount();
     }

   void MarkExported(void) { m_status = GM_MAC_Q_EXPORTED; }

   bool PreferCache(const ulong throttle_ms) const
     {
      if(!m_cache_valid) return false;
      return (GetTickCount() - m_cache_ms) < throttle_ms * 3;
     }
  };

#endif // GM_CMAC_TASK_QUEUE_MQH
//+------------------------------------------------------------------+
