//+------------------------------------------------------------------+
//|                                       CIntelligenceQueue.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Lightweight queued / cached analysis scheduler              |
//+------------------------------------------------------------------+
#ifndef GM_CINTELLIGENCE_QUEUE_MQH
#define GM_CINTELLIGENCE_QUEUE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "IntelligenceAIConstants.mqh"

/// @brief Soft queue + cache TTL for low CPU intelligence refresh (pseudo-async).
class CGmIntelligenceQueue
  {
private:
   int    m_pending;
   ulong  m_last_run_ms;
   ulong  m_cache_until_ms;
   bool   m_busy;

public:
                     CGmIntelligenceQueue(void)
                       : m_pending(0), m_last_run_ms(0), m_cache_until_ms(0), m_busy(false) {}

   void Reset(void)
     {
      m_pending = 0;
      m_last_run_ms = 0;
      m_cache_until_ms = 0;
      m_busy = false;
     }

   void Enqueue(void)
     {
      if(m_pending < GM_INTEL_QUEUE_MAX)
         m_pending++;
     }

   bool CacheValid(const ulong now_ms) const
     {
      return (m_cache_until_ms != 0 && now_ms < m_cache_until_ms);
     }

   /// @return true if a full analysis cycle should run now
   bool ShouldRun(const ulong now_ms, const uint throttle_ms)
     {
      if(CacheValid(now_ms) && m_pending <= 0)
         return false;
      if(m_busy)
         return false;
      if(m_last_run_ms != 0 && (now_ms - m_last_run_ms) < (ulong)throttle_ms && m_pending <= 0)
         return false;
      return true;
     }

   void Begin(const ulong now_ms)
     {
      m_busy = true;
      if(m_pending > 0)
         m_pending--;
      m_last_run_ms = now_ms;
     }

   void Complete(const ulong now_ms)
     {
      m_busy = false;
      m_cache_until_ms = now_ms + (ulong)GM_INTEL_CACHE_TTL_MS;
     }

   int Pending(void) const { return m_pending; }
   bool Busy(void) const { return m_busy; }
  };

#endif // GM_CINTELLIGENCE_QUEUE_MQH
//+------------------------------------------------------------------+
