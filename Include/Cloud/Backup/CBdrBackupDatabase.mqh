//+------------------------------------------------------------------+
//|                                        CBdrBackupDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CBDR_BACKUP_DATABASE_MQH
#define GM_CBDR_BACKUP_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "BackupConstants.mqh"
#include "SGmBackupResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmBdrBackupDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_hist[GM_BDR_HIST_MAX];
   int             m_n;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL) return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmBdrBackupDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_n(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_BDR_DB_PREFIX, magic, sym);
      m_n = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Backup Database Ready | " + m_pfx, "BDR");
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
      string body = "=== backup_history_index ===\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_hist[i] + "\r\n";
      m_files.WriteText(m_pfx + "backup_history.txt", body);
     }

   void Record(const SGmBackupResult &r, const string audit)
     {
      if(!m_ready || !r.valid) return;
      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s\r\n", ts);

      WriteTable("backup_history",
                 "=== backup_history ===\r\n" + head +
                 "Status=" + r.backup_status_text + "\r\n" +
                 "Mode=" + GmBdrBackupModeName(r.last_mode) + "\r\n" +
                 "Last=" + TimeToString(r.last_backup_at, TIME_DATE | TIME_SECONDS) + "\r\n" +
                 "Health=" + DoubleToString(r.backup_health, 1) + "\r\n" +
                 "Versions=" + IntegerToString(r.version_count) + "\r\n");

      WriteTable("restore_history",
                 "=== restore_history ===\r\n" + head +
                 "Restore=" + r.restore_status + "\r\n" +
                 r.restore_validation_report + "\r\n");

      WriteTable("backup_policies",
                 "=== backup_policies ===\r\n" + head +
                 r.policy_status + "\r\n" +
                 "Retention=" + r.retention_policy + "\r\n");

      WriteTable("integrity_reports",
                 "=== integrity_reports ===\r\n" + head +
                 r.integrity_status + "\r\n");

      WriteTable("recovery_reports",
                 "=== recovery_reports ===\r\n" + head +
                 "Readiness=" + DoubleToString(r.recovery_readiness, 1) + "\r\n" +
                 r.recovery_report + "\r\n");

      WriteTable("availability_reports",
                 "=== availability_reports ===\r\n" + head +
                 r.availability_report + "\r\n" +
                 "BC=" + DoubleToString(r.business_continuity, 1) + "\r\n");

      WriteTable("retention_logs",
                 "=== retention_logs ===\r\n" + head +
                 "Days=" + IntegerToString(r.retention_days) + "\r\n" +
                 "Storage=" + DoubleToString(r.storage_usage_pct, 1) + "%\r\n");

      WriteTable("audit_trail",
                 "=== audit_trail ===\r\n" + head + audit + "\r\n" +
                 "POLICY=" + GM_BDR_POLICY + "\r\n" +
                 "SAFE=" + GM_BDR_SAFE + "\r\n");

      const string line = StringFormat("%s | %s | health=%.0f | bc=%.0f | ready=%.0f",
                                       ts, r.backup_status_text, r.backup_health,
                                       r.business_continuity, r.recovery_readiness);
      if(m_n < GM_BDR_HIST_MAX)
         m_hist[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_BDR_HIST_MAX; i++)
            m_hist[i - 1] = m_hist[i];
         m_hist[GM_BDR_HIST_MAX - 1] = line;
        }
     }
  };

#endif // GM_CBDR_BACKUP_DATABASE_MQH
//+------------------------------------------------------------------+
