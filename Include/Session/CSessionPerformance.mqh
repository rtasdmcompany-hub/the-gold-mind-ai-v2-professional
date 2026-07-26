//+------------------------------------------------------------------+
//|                                      CSessionPerformance.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CSESSION_PERFORMANCE_MQH
#define GM_CSESSION_PERFORMANCE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SessionConstants.mqh"
#include "SGmSessionLogSettings.mqh"
#include "CSessionAudit.mqh"
#include "../Logging/CLogger.mqh"

/// @file CSessionPerformance.mqh
/// @brief Measures execution / memory / sync / session init timings.

struct SGmSessionPerfSnapshot
  {
   ulong last_exec_us;
   ulong order_process_us;
   ulong db_sync_us;
   ulong session_init_us;
   ulong memory_kb;
   ulong cpu_load_pct;   ///< TerminalInfoInteger(TERMINAL_CPU_*) if available proxy
   bool  abnormal;

   void Reset(void)
     {
      last_exec_us = 0;
      order_process_us = 0;
      db_sync_us = 0;
      session_init_us = 0;
      memory_kb = 0;
      cpu_load_pct = 0;
      abnormal = false;
     }
  };

class CGmSessionPerformance
  {
private:
   CGmLogger             *m_logger;
   CGmSessionAudit       *m_audit;
   SGmSessionLogSettings  m_settings;
   SGmSessionPerfSnapshot m_snap;
   bool                   m_ready;

   void MaybeAbnormal(const string label, const ulong us)
     {
      if(us < GM_SESSION_PERF_SLOW_US)
         return;
      m_snap.abnormal = true;
      if(m_logger != NULL && m_settings.enable_performance_logs)
         m_logger.Warning(StringFormat("Abnormal performance | %s=%I64u us", label, us),
                          "SessionPerf");
      if(m_audit != NULL)
         m_audit.Record(GM_AUDIT_PERF, "SessionPerf",
                        StringFormat("SLOW %s=%I64u us", label, us));
     }

public:
                     CGmSessionPerformance(void)
                       : m_logger(NULL), m_audit(NULL), m_ready(false)
     {
      m_settings.Defaults();
      m_snap.Reset();
     }

                    ~CGmSessionPerformance(void) { m_logger = NULL; m_audit = NULL; }

   void Init(CGmLogger *logger, CGmSessionAudit *audit, const SGmSessionLogSettings &settings)
     {
      m_logger = logger;
      m_audit = audit;
      m_settings = settings;
      m_snap.Reset();
      m_ready = true;
      if(m_logger != NULL && m_settings.enable_performance_logs)
         m_logger.Info("Session Performance Monitor ready", "SessionPerf");
     }

   SGmSessionPerfSnapshot Snapshot(void) const { return m_snap; }

   void RefreshSystem(void)
     {
      if(!m_ready)
         return;
      m_snap.memory_kb = (ulong)TerminalInfoInteger(TERMINAL_MEMORY_USED);
      // CPU: use available cores / load proxy from terminal if present
      m_snap.cpu_load_pct = (ulong)TerminalInfoInteger(TERMINAL_CPU_CORES);
      if(m_logger != NULL && m_settings.enable_performance_logs)
         m_logger.Debug(StringFormat("Perf | mem=%I64uKB cores=%I64u exec=%I64uus sync=%I64uus",
                                     m_snap.memory_kb, m_snap.cpu_load_pct,
                                     m_snap.last_exec_us, m_snap.db_sync_us),
                        "SessionPerf");
     }

   void RecordExec(const ulong us)
     {
      m_snap.last_exec_us = us;
      MaybeAbnormal("ExecutionSpeed", us);
     }

   void RecordOrderProcess(const ulong us)
     {
      m_snap.order_process_us = us;
      MaybeAbnormal("OrderProcessing", us);
     }

   void RecordDbSync(const ulong us)
     {
      m_snap.db_sync_us = us;
      MaybeAbnormal("DatabaseSync", us);
     }

   void RecordSessionInit(const ulong us)
     {
      m_snap.session_init_us = us;
      MaybeAbnormal("SessionInit", us);
      if(m_logger != NULL && m_settings.enable_performance_logs)
         m_logger.Info(StringFormat("SessionInitTime=%I64u us", us), "SessionPerf");
     }
  };

#endif // GM_CSESSION_PERFORMANCE_MQH
//+------------------------------------------------------------------+
