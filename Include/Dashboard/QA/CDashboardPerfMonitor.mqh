//+------------------------------------------------------------------+
//|                                    CDashboardPerfMonitor.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CDASHBOARD_PERF_MONITOR_MQH
#define GM_CDASHBOARD_PERF_MONITOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "DashboardQAConstants.mqh"
#include "../SGmDashboardSnapshot.mqh"
#include "../../Logging/CLogger.mqh"

/// @file CDashboardPerfMonitor.mqh
/// @brief Tracks dashboard collect/render cost and memory (READ-ONLY).

class CGmDashboardPerfMonitor
  {
private:
   CGmLogger *m_logger;
   double     m_sum_us;
   double     m_peak_us;
   ulong      m_samples;
   ulong      m_mem_start;
   ulong      m_mem_peak;
   ulong      m_mem_samples[GM_DASH_QA_MEM_SAMPLES];
   int        m_mem_n;
   datetime   m_started_at;

public:
                     CGmDashboardPerfMonitor(void)
                       : m_logger(NULL), m_sum_us(0.0), m_peak_us(0.0), m_samples(0),
                         m_mem_start(0), m_mem_peak(0), m_mem_n(0), m_started_at(0)
     {
      ArrayInitialize(m_mem_samples, 0);
     }

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_sum_us = 0.0;
      m_peak_us = 0.0;
      m_samples = 0;
      m_mem_n = 0;
      m_mem_start = (ulong)TerminalInfoInteger(TERMINAL_MEMORY_USED);
      m_mem_peak = m_mem_start;
      m_started_at = TimeCurrent();
      SampleMemory();
     }

   void SampleMemory(void)
     {
      const ulong mem = (ulong)TerminalInfoInteger(TERMINAL_MEMORY_USED);
      if(mem > m_mem_peak)
         m_mem_peak = mem;
      if(m_mem_n < GM_DASH_QA_MEM_SAMPLES)
         m_mem_samples[m_mem_n++] = mem;
      else
        {
         for(int i = 1; i < GM_DASH_QA_MEM_SAMPLES; i++)
            m_mem_samples[i - 1] = m_mem_samples[i];
         m_mem_samples[GM_DASH_QA_MEM_SAMPLES - 1] = mem;
        }
     }

   void RecordCollect(const ulong us)
     {
      m_samples++;
      m_sum_us += (double)us;
      if((double)us > m_peak_us)
         m_peak_us = (double)us;
      SampleMemory();
      if(m_logger != NULL && (m_samples % 100) == 0)
         m_logger.Debug(StringFormat("Performance Metrics | avg=%.0fus peak=%.0fus mem=%I64uKB",
                                     AvgUs(), m_peak_us, m_mem_peak),
                        "DashPerf");
     }

   void RecordSnapshot(const SGmDashboardSnapshot &s)
     {
      if(s.last_refresh_us > 0)
         RecordCollect(s.last_refresh_us);
      else
         SampleMemory();
     }

   double AvgUs(void) const
     {
      return (m_samples > 0) ? (m_sum_us / (double)m_samples) : 0.0;
     }

   double PeakUs(void) const { return m_peak_us; }
   ulong Samples(void) const { return m_samples; }
   ulong MemStart(void) const { return m_mem_start; }
   ulong MemPeak(void) const { return m_mem_peak; }
   ulong MemEnd(void) const
     {
      return (ulong)TerminalInfoInteger(TERMINAL_MEMORY_USED);
     }

   datetime StartedAt(void) const { return m_started_at; }

   double PerformanceScore(void) const
     {
      // Prefer < 5000us avg collect, peak < 20000us, mem growth < 50MB
      double score = 100.0;
      const double avg = AvgUs();
      if(avg > 5000.0)
         score -= MathMin(40.0, (avg - 5000.0) / 500.0);
      if(m_peak_us > 20000.0)
         score -= MathMin(30.0, (m_peak_us - 20000.0) / 2000.0);
      const long growth = (long)MemEnd() - (long)m_mem_start;
      if(growth > 51200)
         score -= MathMin(20.0, (double)(growth - 51200) / 10240.0);
      if(score < 0.0)
         score = 0.0;
      return score;
     }

   /// @brief Adaptive refresh suggestion under load (ms).
   int SuggestedRefreshMs(const int current_ms) const
     {
      if(AvgUs() > 8000.0)
         return MathMin(2000, current_ms + 250);
      if(AvgUs() < 1500.0 && current_ms > 250)
         return MathMax(250, current_ms - 100);
      return current_ms;
     }
  };

#endif // GM_CDASHBOARD_PERF_MONITOR_MQH
//+------------------------------------------------------------------+
