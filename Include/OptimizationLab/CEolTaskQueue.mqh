//+------------------------------------------------------------------+
//|                                           CEolTaskQueue.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEOL_TASK_QUEUE_MQH
#define GM_CEOL_TASK_QUEUE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "OptimizationLabConstants.mqh"

class CGmEolTaskQueue
  {
private:
   ENUM_GM_EOL_QUEUE m_status;
   bool              m_cache_valid;
   ulong             m_cache_ms;

public:
                     CGmEolTaskQueue(void)
                       : m_status(GM_EOL_Q_IDLE), m_cache_valid(false), m_cache_ms(0) {}

   void Reset(void)
     {
      m_status = GM_EOL_Q_IDLE;
      m_cache_valid = false;
      m_cache_ms = 0;
     }

   ENUM_GM_EOL_QUEUE Status(void) const { return m_status; }

   bool MayRunHeavy(const int active_gm_trades)
     {
      if(active_gm_trades > 0)
        {
         m_status = GM_EOL_Q_PAUSED;
         return false;
        }
      return true;
     }

   void MarkRunning(void) { m_status = GM_EOL_Q_RUNNING; }

   void MarkCached(void)
     {
      m_status = GM_EOL_Q_CACHED;
      m_cache_valid = true;
      m_cache_ms = GetTickCount();
     }

   bool PreferCache(const ulong throttle_ms) const
     {
      if(!m_cache_valid) return false;
      return (GetTickCount() - m_cache_ms) < throttle_ms * 3;
     }
  };

#endif // GM_CEOL_TASK_QUEUE_MQH
//+------------------------------------------------------------------+
