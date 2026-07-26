//+------------------------------------------------------------------+
//|                            CExecutionSupervisorDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEXECUTION_SUPERVISOR_DATABASE_MQH
#define GM_CEXECUTION_SUPERVISOR_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmExecutionSupervisorResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmExecutionSupervisorDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_rows[GM_ES_HIST_MAX];
   int             m_n;
   ulong           m_last_persist_ms;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL) return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmExecutionSupervisorDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_n(0),
                         m_last_persist_ms(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_ES_DB_PREFIX, magic, sym);
      m_n = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Execution Supervisor Database Ready | " + m_pfx, "AIES");
      return true;
     }

   void Shutdown(void)
     {
      Persist();
      m_ready = false;
     }

   void Persist(void)
     {
      if(!m_ready || m_files == NULL) return;
      string body = "=== execution_history_index ===\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      m_files.WriteText(m_pfx + "execution_history.txt", body);
     }

   void Record(const SGmExecutionSupervisorResult &r)
     {
      if(!m_ready || !r.valid) return;

      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s | SessionID=%I64u | Symbol=%s\r\n",
                                       ts, r.session_id, r.symbol);

      WriteTable("trade_lifecycle", "=== trade_lifecycle ===\r\n" + head + r.lifecycle_report);
      WriteTable("execution_reports", "=== execution_reports ===\r\n" + head + r.supervisor_report);
      WriteTable("trade_quality", "=== trade_quality ===\r\n" + head + r.quality_report);
      WriteTable("alert_history", "=== alert_history ===\r\n" + head + r.alert_center);
      WriteTable("decision_timeline", "=== decision_timeline ===\r\n" + head + r.decision_report);
      WriteTable("environment_timeline", "=== environment_timeline ===\r\n" + head + r.environment_report);
      WriteTable("recovery_timeline", "=== recovery_timeline ===\r\n" + head + r.recovery_timeline);

      const string line = StringFormat("%s | stage=%s health=%.0f quality=%.0f grade=%s dec=%.0f env=%.0f alert=%s",
                                       ts, r.lifecycle_status, r.execution_health_score,
                                       r.trade_quality_score, GmEsGradeName(r.trade_quality_grade),
                                       r.decision_stability_score, r.environment_stability_score,
                                       r.latest_alert);
      if(m_n < GM_ES_HIST_MAX)
         m_rows[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_ES_HIST_MAX; i++)
            m_rows[i - 1] = m_rows[i];
         m_rows[GM_ES_HIST_MAX - 1] = line;
        }

      const ulong now = GetTickCount();
      if(m_last_persist_ms == 0 || (now - m_last_persist_ms) > 7000)
        {
         Persist();
         m_last_persist_ms = now;
         if(m_logger != NULL)
            m_logger.Info("Execution Report Saved | Execution Supervisor tables", "AIES");
        }
     }
  };

#endif // GM_CEXECUTION_SUPERVISOR_DATABASE_MQH
//+------------------------------------------------------------------+
