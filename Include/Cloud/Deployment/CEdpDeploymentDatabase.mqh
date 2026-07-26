//+------------------------------------------------------------------+
//|                                    CEdpDeploymentDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEDP_DEPLOYMENT_DATABASE_MQH
#define GM_CEDP_DEPLOYMENT_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "DeploymentConstants.mqh"
#include "SGmDeploymentResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmEdpDeploymentDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_hist[GM_EDP_HIST_MAX];
   int             m_n;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL) return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmEdpDeploymentDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_n(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_EDP_DB_PREFIX, magic, sym);
      m_n = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Deployment Database Ready | " + m_pfx, "EDP");
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
      string body = "=== version_history ===\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_hist[i] + "\r\n";
      m_files.WriteText(m_pfx + "version_history.txt", body);
     }

   void Record(const SGmDeploymentResult &r, const string audit, const string rollback_report)
     {
      if(!m_ready || !r.valid) return;
      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s\r\n", ts);

      WriteTable("version_history",
                 "=== version_history ===\r\n" + head +
                 "Current=" + r.current_version + "\r\n" +
                 "Latest=" + r.latest_version + "\r\n" +
                 "Build=" + IntegerToString(r.current_build) + "\r\n");

      WriteTable("deployment_history",
                 "=== deployment_history ===\r\n" + head +
                 r.deployment_status_text + "\r\n" +
                 "Health=" + DoubleToString(r.deployment_health, 1) + "\r\n");

      WriteTable("update_history",
                 "=== update_history ===\r\n" + head +
                 r.update_status_text + "\r\n" +
                 "Deferred=" + (r.update_deferred ? "yes" : "no") + "\r\n" +
                 "ActiveGMTrades=" + IntegerToString(r.active_gm_trades) + "\r\n");

      WriteTable("rollback_history",
                 "=== rollback_history ===\r\n" + head +
                 r.rollback_status + "\r\n" + rollback_report + "\r\n");

      WriteTable("release_notes",
                 "=== release_notes ===\r\n" + head + r.release_notes + "\r\n");

      WriteTable("validation_reports",
                 "=== validation_reports ===\r\n" + head + r.production_readiness + "\r\n");

      WriteTable("approval_history",
                 "=== approval_history ===\r\n" + head +
                 r.approval_status + "\r\n");

      WriteTable("deployment_audit_trail",
                 "=== deployment_audit_trail ===\r\n" + head + audit + "\r\n" +
                 "POLICY=" + GM_EDP_POLICY + "\r\n" +
                 "SAFE=" + GM_EDP_SAFE + "\r\n");

      const string line = StringFormat("%s | %s → %s | %s | trades=%d | health=%.0f",
                                       ts, r.current_version, r.latest_version,
                                       r.update_status_text, r.active_gm_trades,
                                       r.deployment_health);
      if(m_n < GM_EDP_HIST_MAX)
         m_hist[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_EDP_HIST_MAX; i++)
            m_hist[i - 1] = m_hist[i];
         m_hist[GM_EDP_HIST_MAX - 1] = line;
        }
     }
  };

#endif // GM_CEDP_DEPLOYMENT_DATABASE_MQH
//+------------------------------------------------------------------+
