//+------------------------------------------------------------------+
//|                                    CAICorePerfMonitor.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CAI_CORE_PERF_MONITOR_MQH
#define GM_CAI_CORE_PERF_MONITOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../../Logging/CLogger.mqh"

class CGmAICorePerfMonitor
  {
private:
   CGmLogger *m_logger;
   double     m_sum_us;
   double     m_peak_us;
   ulong      m_samples;
   ulong      m_mem_peak;

public:
                     CGmAICorePerfMonitor(void)
                       : m_logger(NULL), m_sum_us(0.0), m_peak_us(0.0),
                         m_samples(0), m_mem_peak(0) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_sum_us = 0.0;
      m_peak_us = 0.0;
      m_samples = 0;
      m_mem_peak = (ulong)TerminalInfoInteger(TERMINAL_MEMORY_USED);
     }

   void Record(const ulong us)
     {
      m_samples++;
      m_sum_us += (double)us;
      if((double)us > m_peak_us)
         m_peak_us = (double)us;
      const ulong mem = (ulong)TerminalInfoInteger(TERMINAL_MEMORY_USED);
      if(mem > m_mem_peak)
         m_mem_peak = mem;
      if(m_logger != NULL && (m_samples % 50) == 0)
         m_logger.Debug(StringFormat("Performance | avg=%.0fus peak=%.0fus mem=%I64u",
                                     AvgUs(), m_peak_us, m_mem_peak),
                        "AIPerf");
     }

   double AvgUs(void) const
     {
      return (m_samples > 0) ? (m_sum_us / (double)m_samples) : 0.0;
     }

   double PeakUs(void) const { return m_peak_us; }
   ulong Samples(void) const { return m_samples; }
   ulong MemPeak(void) const { return m_mem_peak; }
  };

#endif // GM_CAI_CORE_PERF_MONITOR_MQH
//+------------------------------------------------------------------+
