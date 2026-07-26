//+------------------------------------------------------------------+
//|                                  CLearningBatchScheduler.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Batch / cache scheduler — no impact on trading engine       |
//+------------------------------------------------------------------+
#ifndef GM_CLEARNING_BATCH_SCHEDULER_MQH
#define GM_CLEARNING_BATCH_SCHEDULER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "MemoryAIConstants.mqh"

class CGmLearningBatchScheduler
  {
private:
   int    m_batch_pending;
   ulong  m_last_ms;
   ulong  m_cache_until;
   bool   m_busy;

public:
                     CGmLearningBatchScheduler(void)
                       : m_batch_pending(0), m_last_ms(0), m_cache_until(0), m_busy(false) {}

   void Reset(void)
     {
      m_batch_pending = 0;
      m_last_ms = 0;
      m_cache_until = 0;
      m_busy = false;
     }

   void Signal(void)
     {
      if(m_batch_pending < GM_MEM_BATCH_SIZE)
         m_batch_pending++;
     }

   bool CacheValid(const ulong now) const
     {
      return (m_cache_until != 0 && now < m_cache_until);
     }

   bool ShouldRun(const ulong now, const uint throttle_ms)
     {
      if(CacheValid(now) && m_batch_pending <= 0)
         return false;
      if(m_busy)
         return false;
      if(m_last_ms != 0 && (now - m_last_ms) < (ulong)throttle_ms && m_batch_pending <= 0)
         return false;
      return true;
     }

   void Begin(const ulong now)
     {
      m_busy = true;
      if(m_batch_pending > 0)
         m_batch_pending--;
      m_last_ms = now;
     }

   void Complete(const ulong now)
     {
      m_busy = false;
      m_cache_until = now + (ulong)GM_MEM_CACHE_TTL_MS;
     }

   int Pending(void) const { return m_batch_pending; }
  };

#endif // GM_CLEARNING_BATCH_SCHEDULER_MQH
//+------------------------------------------------------------------+
