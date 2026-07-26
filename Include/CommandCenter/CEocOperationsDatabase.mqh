//+------------------------------------------------------------------+
//|                                    CEocOperationsDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEOC_OPERATIONS_DATABASE_MQH
#define GM_CEOC_OPERATIONS_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmCommandCenterResult.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"

class CGmEocOperationsDatabase
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
                     CGmEocOperationsDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_EOC_DB_PREFIX, magic, sym);
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Infrastructure Updated | Operations DB Ready | " + m_pfx, "EOC");
      return true;
     }

   string Prefix(void) const { return m_pfx; }
   void Shutdown(void) { m_ready = false; }

   void Persist(const SGmCommandCenterResult &r)
     {
      if(!m_ready || m_files == NULL || !r.valid) return;
      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s\r\n", ts);

      WriteTable("operations_history", head + r.ops_room_summary);
      WriteTable("infrastructure_history", head + StringFormat("Infra=%.0f Cloud=%s API=%s Backup=%s\r\n",
                                                                r.infrastructure_health, r.cloud_status,
                                                                r.api_status, r.backup_status));
      WriteTable("health_history", head + StringFormat("Enterprise=%.0f\r\n", r.enterprise_health));
      WriteTable("performance_history", head + r.performance_wall);
      WriteTable("alert_history", head + r.alert_center);
      WriteTable("availability_reports", head + r.availability_report);
      WriteTable("enterprise_reports", head + r.executive_summary + "\r\n" + r.audit_trail);

      if(m_logger != NULL)
         m_logger.Debug("Infrastructure Updated | EOC tables persisted", "EOC");
     }
  };

#endif // GM_CEOC_OPERATIONS_DATABASE_MQH
//+------------------------------------------------------------------+
