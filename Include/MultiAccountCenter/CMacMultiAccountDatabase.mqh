//+------------------------------------------------------------------+
//|                                 CMacMultiAccountDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CMAC_MULTI_ACCOUNT_DATABASE_MQH
#define GM_CMAC_MULTI_ACCOUNT_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMultiAccountCenterResult.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"

class CGmMacMultiAccountDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL) return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmMacMultiAccountDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_MAC_DB_PREFIX, magic, sym);
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Database Updated | Multi-Account Center DB Ready | " + m_pfx, "MAC");
      return true;
     }

   string Prefix(void) const { return m_pfx; }
   void Shutdown(void) { m_ready = false; }

   void Persist(const SGmMultiAccountCenterResult &r)
     {
      if(!m_ready || m_files == NULL || !r.valid) return;
      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s\r\n", ts);

      WriteTable("account_registry", head + r.account_list);
      WriteTable("account_groups", head + r.cluster_overview);
      WriteTable("performance_history", head + r.comparison_report);
      WriteTable("capital_history", head + r.capital_report);
      WriteTable("health_history", head + StringFormat("Account=%.0f Enterprise=%.0f\r\n",
                                                        r.account_health, r.enterprise_health));
      WriteTable("connection_history", head + StringFormat("Status=%s Connected=%d Offline=%d\r\n",
                                                            GmMacConnName(r.connection_status),
                                                            r.connected_count, r.offline_count));
      WriteTable("ranking_history", head + r.ranking_report + "\r\n" + r.audit_trail);

      if(m_logger != NULL)
         m_logger.Debug("Database Updated | MAC tables persisted", "MAC");
     }
  };

#endif // GM_CMAC_MULTI_ACCOUNT_DATABASE_MQH
//+------------------------------------------------------------------+
