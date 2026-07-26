//+------------------------------------------------------------------+
//|                                CAnalyticsPerfMonitor.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CANALYTICS_PERF_MONITOR_MQH
#define GM_CANALYTICS_PERF_MONITOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "AnalyticsConstants.mqh"

/// @file CAnalyticsPerfMonitor.mqh
/// @brief Performance Engine — tick/collect timing, memory, health (read-only).

class CGmAnalyticsPerfMonitor
  {
private:
   ulong m_samples[GM_ANALYTICS_PERF_WINDOW];
   int   m_count;
   int   m_idx;
   ulong m_last_tick_us;
   ulong m_avg_us;

public:
                     CGmAnalyticsPerfMonitor(void)
                       : m_count(0), m_idx(0), m_last_tick_us(0), m_avg_us(0)
     {
      ArrayInitialize(m_samples, 0);
     }

   void Record(const ulong elapsed_us)
     {
      m_last_tick_us = elapsed_us;
      m_samples[m_idx] = elapsed_us;
      m_idx = (m_idx + 1) % GM_ANALYTICS_PERF_WINDOW;
      if(m_count < GM_ANALYTICS_PERF_WINDOW)
         m_count++;

      ulong sum = 0;
      for(int i = 0; i < m_count; i++)
         sum += m_samples[i];
      m_avg_us = (m_count > 0) ? (sum / (ulong)m_count) : 0;
     }

   ulong LastUs(void) const { return m_last_tick_us; }
   ulong AvgUs(void) const { return m_avg_us; }

   ulong MemoryKb(void) const
     {
      return (ulong)TerminalInfoInteger(TERMINAL_MEMORY_USED);
     }

   double CpuLoadPct(void) const
     {
      // Not universally available across MT5 builds — reserved for future.
      return 0.0;
     }

   string Health(const ulong collect_us) const
     {
      if(collect_us > 250000)
         return "SLOW";
      if(collect_us > 100000)
         return "WARN";
      return "OK";
     }
  };

#endif // GM_CANALYTICS_PERF_MONITOR_MQH
//+------------------------------------------------------------------+
