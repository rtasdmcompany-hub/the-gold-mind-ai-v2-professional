//+------------------------------------------------------------------+
//|                                CMultiTimeframeDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CMULTI_TIMEFRAME_DATABASE_MQH
#define GM_CMULTI_TIMEFRAME_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMultiTimeframeResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmMultiTimeframeDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_rows[GM_MTF_HIST_MAX];
   int             m_n;
   ulong           m_last_persist_ms;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL) return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmMultiTimeframeDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_n(0),
                         m_last_persist_ms(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_MTF_DB_PREFIX, magic, sym);
      m_n = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Multi-Timeframe Database Ready | " + m_pfx, "AIMTF");
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
      string body = "=== historical_comparison_index ===\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      m_files.WriteText(m_pfx + "historical_comparison.txt", body);
     }

   void Record(const SGmMultiTimeframeResult &r)
     {
      if(!m_ready || !r.valid) return;

      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s | SessionID=%I64u | Symbol=%s\r\n",
                                       ts, r.session_id, r.symbol);

      WriteTable("timeframe_analysis", "=== timeframe_analysis ===\r\n" + head + r.mtf_report);
      WriteTable("trend_alignment", "=== trend_alignment ===\r\n" + head + r.sync_report);
      WriteTable("confluence_reports", "=== confluence_reports ===\r\n" + head + r.confluence_report);
      WriteTable("correlation_reports", "=== correlation_reports ===\r\n" + head + r.correlation_report);
      WriteTable("context_reports", "=== context_reports ===\r\n" + head + r.context_report);

      const string line = StringFormat("%s | sync=%.0f conf=%.0f ctx=%.0f corr=%.0f bias=%s grade=%s",
                                       ts, r.synchronization_score, r.confluence_score,
                                       r.execution_context_score, r.correlation_index,
                                       GmMtfBiasName(r.overall_market_bias),
                                       GmMtfGradeName(r.market_context_grade));
      if(m_n < GM_MTF_HIST_MAX)
         m_rows[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_MTF_HIST_MAX; i++)
            m_rows[i - 1] = m_rows[i];
         m_rows[GM_MTF_HIST_MAX - 1] = line;
        }

      const ulong now = GetTickCount();
      if(m_last_persist_ms == 0 || (now - m_last_persist_ms) > 9000)
        {
         Persist();
         m_last_persist_ms = now;
         if(m_logger != NULL)
            m_logger.Info("Database Synchronization Completed | Multi-Timeframe tables", "AIMTF");
        }
     }
  };

#endif // GM_CMULTI_TIMEFRAME_DATABASE_MQH
//+------------------------------------------------------------------+
