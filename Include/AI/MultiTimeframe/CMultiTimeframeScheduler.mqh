//+------------------------------------------------------------------+
//|                               CMultiTimeframeScheduler.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CMULTI_TIMEFRAME_SCHEDULER_MQH
#define GM_CMULTI_TIMEFRAME_SCHEDULER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "MultiTimeframeConstants.mqh"

class CGmMultiTimeframeScheduler
  {
private:
   ulong m_last_ms;
   ulong m_cache_until;
   bool  m_busy;
   int   m_pending;

public:
                     CGmMultiTimeframeScheduler(void)
                       : m_last_ms(0), m_cache_until(0), m_busy(false), m_pending(0) {}

   void Reset(void) { m_last_ms = 0; m_cache_until = 0; m_busy = false; m_pending = 0; }
   void Signal(void) { if(m_pending < 4) m_pending++; }
   bool CacheValid(const ulong now) const { return (m_cache_until != 0 && now < m_cache_until); }

   bool ShouldRun(const ulong now, const uint throttle_ms)
     {
      if(CacheValid(now) && m_pending <= 0) return false;
      if(m_busy) return false;
      if(m_last_ms != 0 && (now - m_last_ms) < (ulong)throttle_ms && m_pending <= 0)
         return false;
      return true;
     }

   void Begin(const ulong now)
     {
      m_busy = true;
      if(m_pending > 0) m_pending--;
      m_last_ms = now;
     }

   void Complete(const ulong now)
     {
      m_busy = false;
      m_cache_until = now + (ulong)GM_MTF_CACHE_TTL_MS;
     }

   int Pending(void) const { return m_pending; }
  };

#endif // GM_CMULTI_TIMEFRAME_SCHEDULER_MQH
//+------------------------------------------------------------------+
