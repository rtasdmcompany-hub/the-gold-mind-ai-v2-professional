//+------------------------------------------------------------------+
//|                                    CPerformanceAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CPERFORMANCE_ANALYZER_MQH
#define GM_CPERFORMANCE_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ValidationConstants.mqh"
#include "CErrorClassifier.mqh"
#include "../Logging/CLogger.mqh"

/// @file CPerformanceAnalyzer.mqh
/// @brief Measures validation / session / trade processing performance.

struct SGmPerfReport
  {
   ulong validation_us;
   ulong trade_process_us;
   ulong session_process_us;
   ulong db_sync_us;
   ulong avg_process_us;
   ulong memory_kb;
   ulong cpu_cores;
   bool  valid;

   void Reset(void)
     {
      validation_us = 0;
      trade_process_us = 0;
      session_process_us = 0;
      db_sync_us = 0;
      avg_process_us = 0;
      memory_kb = 0;
      cpu_cores = 0;
      valid = false;
     }
  };

class CGmPerformanceAnalyzer
  {
private:
   CGmLogger          *m_logger;
   CGmErrorClassifier *m_errors;
   SGmPerfReport       m_report;

public:
                     CGmPerformanceAnalyzer(void)
                       : m_logger(NULL), m_errors(NULL)
     {
      m_report.Reset();
     }

                    ~CGmPerformanceAnalyzer(void) { m_logger = NULL; m_errors = NULL; }

   void Init(CGmLogger *logger, CGmErrorClassifier *errors)
     {
      m_logger = logger;
      m_errors = errors;
      m_report.Reset();
     }

   SGmPerfReport Report(void) const { return m_report; }

   void Capture(const ulong validation_us,
                const ulong trade_us,
                const ulong session_us,
                const ulong db_us)
     {
      m_report.validation_us = validation_us;
      m_report.trade_process_us = trade_us;
      m_report.session_process_us = session_us;
      m_report.db_sync_us = db_us;
      m_report.avg_process_us = (trade_us + session_us + db_us) / 3;
      m_report.memory_kb = (ulong)TerminalInfoInteger(TERMINAL_MEMORY_USED);
      m_report.cpu_cores = (ulong)TerminalInfoInteger(TERMINAL_CPU_CORES);
      m_report.valid = true;

      if(validation_us > GM_VAL_PERF_SLOW_US || m_report.avg_process_us > GM_VAL_PERF_SLOW_US)
        {
         if(m_errors != NULL)
            m_errors.Add(GM_VAL_SEV_PERF, "Performance",
                         StringFormat("Slow processing | val=%I64u avg=%I64u us",
                                      validation_us, m_report.avg_process_us),
                         "Profile tick path; reduce file I/O frequency if needed.");
        }

      if(m_logger != NULL)
         m_logger.Info(StringFormat("Perf | val=%I64uus trade=%I64uus session=%I64uus db=%I64uus mem=%I64uKB cores=%I64u",
                                    m_report.validation_us, m_report.trade_process_us,
                                    m_report.session_process_us, m_report.db_sync_us,
                                    m_report.memory_kb, m_report.cpu_cores),
                       "Performance");
     }

   string Dump(void) const
     {
      if(!m_report.valid)
         return "Performance: n/a\r\n";
      return StringFormat(
         "ExecutionSpeed(validation)=%I64u us\r\n"
         "AverageProcessingTime=%I64u us\r\n"
         "TradeProcessingTime=%I64u us\r\n"
         "SessionProcessingTime=%I64u us\r\n"
         "DatabasePerformance=%I64u us\r\n"
         "MemoryUsage=%I64u KB\r\n"
         "CPUCores=%I64u\r\n",
         m_report.validation_us,
         m_report.avg_process_us,
         m_report.trade_process_us,
         m_report.session_process_us,
         m_report.db_sync_us,
         m_report.memory_kb,
         m_report.cpu_cores);
     }
  };

#endif // GM_CPERFORMANCE_ANALYZER_MQH
//+------------------------------------------------------------------+
