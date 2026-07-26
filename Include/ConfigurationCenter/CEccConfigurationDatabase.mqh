//+------------------------------------------------------------------+
//|                               CEccConfigurationDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CECC_CONFIGURATION_DATABASE_MQH
#define GM_CECC_CONFIGURATION_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmConfigurationCenterResult.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"

class CGmEccConfigurationDatabase
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
                     CGmEccConfigurationDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_ECC_DB_PREFIX, magic, sym);
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Database Updated | Configuration Center DB Ready | " + m_pfx, "ECC");
      return true;
     }

   string Prefix(void) const { return m_pfx; }
   void Shutdown(void) { m_ready = false; }

   void Persist(const SGmConfigurationCenterResult &r)
     {
      if(!m_ready || m_files == NULL || !r.valid) return;
      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s\r\n", ts);

      WriteTable("profiles", head + StringFormat("Name=%s Version=%d\r\n", r.profile_name, r.profile_version));
      WriteTable("templates", head + StringFormat("Name=%s Version=%d Locked=%s\r\n",
                                                   r.template_name, r.template_version,
                                                   r.template_locked ? "YES" : "NO"));
      WriteTable("configurations", head + r.config_summary);
      WriteTable("workspace_layouts", head + r.workspace_status + "\r\n");
      WriteTable("import_history", head + r.import_status + "\r\n");
      WriteTable("export_history", head + r.export_status + "\r\n");
      WriteTable("backup_history", head + r.last_backup + "\r\n" + r.audit_trail + "\r\n");

      if(m_logger != NULL)
         m_logger.Debug("Database Updated | ECC tables persisted", "ECC");
     }
  };

#endif // GM_CECC_CONFIGURATION_DATABASE_MQH
//+------------------------------------------------------------------+
