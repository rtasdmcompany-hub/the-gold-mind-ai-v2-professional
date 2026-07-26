//+------------------------------------------------------------------+
//|                                    CErcReportingDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CERC_REPORTING_DATABASE_MQH
#define GM_CERC_REPORTING_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmReportingCenterResult.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"

class CGmErcReportingDatabase
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
                     CGmErcReportingDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_ERC_DB_PREFIX, magic, sym);
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Database Updated | Reporting Center DB Ready | " + m_pfx, "ERC");
      return true;
     }

   string Prefix(void) const { return m_pfx; }
   void Shutdown(void) { m_ready = false; }

   void Persist(const SGmReportingCenterResult &r)
     {
      if(!m_ready || m_files == NULL || !r.valid) return;
      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s\r\n", ts);

      WriteTable("generated_reports", head + r.latest_reports + "\r\n" + r.daily_report + "\r\n" + r.monthly_report);
      WriteTable("business_intelligence_reports", head + r.bi_report + "\r\n");
      WriteTable("executive_reports", head + r.executive_summary + "\r\n");
      WriteTable("investor_reports", head + r.investor_summary + "\r\n");
      WriteTable("visualization_metadata", head + r.visualization_catalog + "\r\n");
      WriteTable("historical_reports", head + r.yearly_report + "\r\n" + r.quarterly_report + "\r\n");
      WriteTable("export_history", head + r.export_status + "\r\n");

      if(m_logger != NULL)
         m_logger.Debug("Database Updated | ERC tables persisted", "ERC");
     }
  };

#endif // GM_CERC_REPORTING_DATABASE_MQH
//+------------------------------------------------------------------+
