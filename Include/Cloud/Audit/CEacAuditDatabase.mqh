//+------------------------------------------------------------------+
//|                                         CEacAuditDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEAC_AUDIT_DATABASE_MQH
#define GM_CEAC_AUDIT_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "AuditConstants.mqh"
#include "SGmAuditResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmEacAuditDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_hist[GM_EAC_HIST_MAX];
   int             m_n;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL) return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmEacAuditDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_n(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_EAC_DB_PREFIX, magic, sym);
      m_n = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Audit Database Ready | " + m_pfx, "EAC");
      return true;
     }

   string Prefix(void) const { return m_pfx; }

   void Shutdown(void)
     {
      Persist();
      m_ready = false;
     }

   void Persist(void)
     {
      if(!m_ready || m_files == NULL) return;
      string body = "=== event_history ===\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_hist[i] + "\r\n";
      m_files.WriteText(m_pfx + "event_history.txt", body);
     }

   void Record(const SGmAuditResult &r, const string encrypted_audit, const string trail)
     {
      if(!m_ready || !r.valid) return;
      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s\r\nSession=%s\r\n", ts, r.session_id);

      WriteTable("audit_logs",
                 "=== audit_logs (encrypted) ===\r\n" + head +
                 encrypted_audit + "\r\n" +
                 "Recent=" + r.recent_events + "\r\n");

      WriteTable("compliance_reports",
                 "=== compliance_reports ===\r\n" + head + r.compliance_report + "\r\n");

      WriteTable("integrity_reports",
                 "=== integrity_reports ===\r\n" + head + r.integrity_report + "\r\n");

      WriteTable("security_reports",
                 "=== security_reports ===\r\n" + head +
                 r.security_status + "\r\n" + r.security_report + "\r\n");

      WriteTable("export_history",
                 "=== export_history ===\r\n" + head +
                 "Export=" + r.export_status + "\r\n" +
                 "Reports=" + IntegerToString(r.reports_generated) + "\r\n");

      WriteTable("audit_trail",
                 "=== audit_trail ===\r\n" + head + trail + "\r\n" +
                 "POLICY=" + GM_EAC_POLICY + "\r\n");

      const string line = StringFormat("%s | trust=%.0f | compliance=%.0f | critical=%d | %s",
                                       ts, r.trust_score, r.compliance_score,
                                       r.critical_count, r.audit_status);
      if(m_n < GM_EAC_HIST_MAX)
         m_hist[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_EAC_HIST_MAX; i++)
            m_hist[i - 1] = m_hist[i];
         m_hist[GM_EAC_HIST_MAX - 1] = line;
        }
     }
  };

#endif // GM_CEAC_AUDIT_DATABASE_MQH
//+------------------------------------------------------------------+
