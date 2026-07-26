//+------------------------------------------------------------------+
//|                                           CEslTaskQueue.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CESL_TASK_QUEUE_MQH
#define GM_CESL_TASK_QUEUE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "StrategyLabConstants.mqh"

class CGmEslTaskQueue
  {
private:
   ENUM_GM_ESL_QUEUE m_status;
   ENUM_GM_ESL_MODE  m_next;
   bool              m_cache_valid;
   ulong             m_cache_ms;

public:
                     CGmEslTaskQueue(void)
                       : m_status(GM_ESL_Q_IDLE), m_next(GM_ESL_MODE_IDLE),
                         m_cache_valid(false), m_cache_ms(0) {}

   void Reset(void)
     {
      m_status = GM_ESL_Q_IDLE;
      m_next = GM_ESL_MODE_IDLE;
      m_cache_valid = false;
      m_cache_ms = 0;
     }

   ENUM_GM_ESL_QUEUE Status(void) const { return m_status; }
   bool CacheValid(void) const { return m_cache_valid; }

   void EnqueueFullCycle(void)
     {
      m_next = GM_ESL_MODE_BACKTEST;
      m_status = GM_ESL_Q_PENDING;
     }

   /// @brief Returns false if heavy work must pause (live GM trades open).
   bool MayRunHeavy(const int active_gm_trades)
     {
      if(active_gm_trades > 0)
        {
         m_status = GM_ESL_Q_PAUSED;
         return false;
        }
      return true;
     }

   void MarkRunning(void) { m_status = GM_ESL_Q_RUNNING; }

   void MarkCached(void)
     {
      m_status = GM_ESL_Q_CACHED;
      m_cache_valid = true;
      m_cache_ms = GetTickCount();
     }

   bool PreferCache(const ulong throttle_ms) const
     {
      if(!m_cache_valid)
         return false;
      return (GetTickCount() - m_cache_ms) < throttle_ms * 3;
     }
  };

#endif // GM_CESL_TASK_QUEUE_MQH
//+------------------------------------------------------------------+
