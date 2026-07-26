//+------------------------------------------------------------------+
//|                                    CEnterpriseDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CENTERPRISE_DATABASE_MQH
#define GM_CENTERPRISE_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmEnterpriseResult.mqh"
#include "CEnterpriseObservationApi.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmEnterpriseDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_rows[GM_ENT_HIST_MAX];
   int             m_n;
   ulong           m_last_persist_ms;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL) return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmEnterpriseDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_n(0),
                         m_last_persist_ms(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_ENT_DB_PREFIX, magic, sym);
      m_n = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Enterprise Monitoring Database Ready | " + m_pfx, "AIEnt");
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
      string body = "=== connection_history / enterprise index ===\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      m_files.WriteText(m_pfx + "connection_history.txt", body);
     }

   void Record(const SGmEnterpriseResult &r, CGmEnterpriseObservationApi &api)
     {
      if(!m_ready || !r.valid) return;

      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s | SessionID=%I64u | Account=%s\r\n",
                                       ts, r.session_id, r.local_profile.account_id);

      WriteTable("enterprise_accounts",
                 "=== enterprise_accounts ===\r\n" + head +
                 StringFormat("Broker=%s Server=%s Type=%s Currency=%s Conn=%s CredentialsStored=false\r\n",
                              r.local_profile.broker, r.local_profile.server,
                              r.local_profile.account_type, r.local_profile.currency,
                              r.local_profile.connection_status));
      WriteTable("account_health_records",
                 "=== account_health_records ===\r\n" + head +
                 StringFormat("Health=%s Equity=%.2f DD=%.2f MarginUse=%.1f Recovery=%s\r\n",
                              GmEntAcctHealthName(r.local_health), r.local_equity,
                              r.local_dd_pct, r.local_margin_usage, r.local_recovery));
      WriteTable("cloud_monitoring_logs",
                 "=== cloud_monitoring_logs ===\r\n" + head + r.cloud_health_report);
      WriteTable("fleet_health_reports",
                 "=== fleet_health_reports ===\r\n" + head +
                 StringFormat("Fleet=%.0f Status=%s Alerts=%s\r\n%s\r\n",
                              r.fleet_health_score, r.fleet_status, r.enterprise_alerts,
                              api.FleetJson(r)));
      WriteTable("account_comparison_reports",
                 "=== account_comparison_reports ===\r\n" + head + r.comparison_report);
      WriteTable("api_observation_catalog",
                 "=== remote observation api (READ-ONLY) ===\r\n" + api.EndpointCatalog() + "\r\n" +
                 api.AccountsJson(r) + "\r\n" + api.AccountHealthJson(r) + "\r\n");

      const string line = StringFormat("%s | accts=%d fleet=%.0f local=%s alerts=%s",
                                       ts, r.accounts_monitored, r.fleet_health_score,
                                       GmEntAcctHealthName(r.local_health), r.enterprise_alerts);
      if(m_n < GM_ENT_HIST_MAX)
         m_rows[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_ENT_HIST_MAX; i++)
            m_rows[i - 1] = m_rows[i];
         m_rows[GM_ENT_HIST_MAX - 1] = line;
        }

      const ulong now = GetTickCount();
      if(m_last_persist_ms == 0 || (now - m_last_persist_ms) > 9000)
        {
         Persist();
         m_last_persist_ms = now;
         if(m_logger != NULL)
            m_logger.Info("Database Synchronization Completed | Enterprise tables", "AIEnt");
        }
     }
  };

#endif // GM_CENTERPRISE_DATABASE_MQH
//+------------------------------------------------------------------+
