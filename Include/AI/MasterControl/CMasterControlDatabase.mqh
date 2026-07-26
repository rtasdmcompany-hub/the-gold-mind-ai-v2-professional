//+------------------------------------------------------------------+
//|                                     CMasterControlDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CMASTER_CONTROL_DATABASE_MQH
#define GM_CMASTER_CONTROL_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMasterControlResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmMasterControlDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_rows[GM_MCC_HIST_MAX];
   int             m_n;
   ulong           m_last_persist_ms;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL) return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmMasterControlDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_n(0),
                         m_last_persist_ms(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_MCC_DB_PREFIX, magic, sym);
      m_n = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Master Control Database Ready | " + m_pfx, "AIMCC");
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
      string body = "=== master_control_status_history ===\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      m_files.WriteText(m_pfx + "master_control_status_history.txt", body);
     }

   void Record(const SGmMasterControlResult &r)
     {
      if(!m_ready || !r.valid) return;

      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s | SessionID=%I64u\r\n", ts, r.session_id);

      WriteTable("master_overview", "=== master_overview ===\r\n" + head + r.master_overview);
      WriteTable("unified_ai_health", "=== unified_ai_health ===\r\n" + head + r.unified_status_report);
      WriteTable("integration_report", "=== integration_report ===\r\n" + head + r.integration_report);
      WriteTable("phase4_audit_report", "=== phase4_audit_report ===\r\n" + head + r.audit_report);
      WriteTable("production_readiness", "=== production_readiness ===\r\n" + head + r.production_report);
      WriteTable("security_compliance", "=== security_compliance ===\r\n" + head + r.security_report);
      WriteTable("database_consolidation", "=== database_consolidation ===\r\n" + head + r.database_audit_report);
      WriteTable("performance_report", "=== performance_report ===\r\n" + head + r.performance_report);

      const string line = StringFormat("%s | health=%.0f intel=%.0f prod=%.0f audit=%s sec=%s phase4=%s",
                                       ts, r.ai_health_score, r.ai_intelligence,
                                       r.production_readiness,
                                       (r.audit_pass ? "PASS" : "NO"),
                                       (r.security_pass ? "PASS" : "NO"),
                                       r.phase4_status);
      if(m_n < GM_MCC_HIST_MAX)
         m_rows[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_MCC_HIST_MAX; i++)
            m_rows[i - 1] = m_rows[i];
         m_rows[GM_MCC_HIST_MAX - 1] = line;
        }

      const ulong now = GetTickCount();
      if(m_last_persist_ms == 0 || (now - m_last_persist_ms) > 10000)
        {
         Persist();
         m_last_persist_ms = now;
         if(m_logger != NULL)
            m_logger.Info("Database Synchronization Completed | Master Control tables", "AIMCC");
        }
     }
  };

#endif // GM_CMASTER_CONTROL_DATABASE_MQH
//+------------------------------------------------------------------+
