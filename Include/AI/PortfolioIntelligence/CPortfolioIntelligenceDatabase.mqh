//+------------------------------------------------------------------+
//|                             CPortfolioIntelligenceDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CPORTFOLIO_INTELLIGENCE_DATABASE_MQH
#define GM_CPORTFOLIO_INTELLIGENCE_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmPortfolioIntelligenceResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmPortfolioIntelligenceDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_rows[GM_PI_HIST_MAX];
   int             m_n;
   ulong           m_last_persist_ms;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL) return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmPortfolioIntelligenceDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_n(0),
                         m_last_persist_ms(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_PI_DB_PREFIX, magic, sym);
      m_n = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Portfolio Intelligence Database Ready | " + m_pfx, "AIPI");
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
      string body = "=== historical_portfolio_index ===\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      m_files.WriteText(m_pfx + "historical_portfolio.txt", body);
     }

   void Record(const SGmPortfolioIntelligenceResult &r)
     {
      if(!m_ready || !r.valid) return;

      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s | SessionID=%I64u | Symbol=%s\r\n",
                                       ts, r.session_id, r.symbol);

      WriteTable("portfolio_reports", "=== portfolio_reports ===\r\n" + head + r.portfolio_report);
      WriteTable("capital_reports", "=== capital_reports ===\r\n" + head + r.capital_report);
      WriteTable("correlation_reports", "=== correlation_reports ===\r\n" + head + r.correlation_report);
      WriteTable("exposure_reports", "=== exposure_reports ===\r\n" + head + r.risk_report);
      WriteTable("growth_reports",
                 "=== growth_reports ===\r\n" + head +
                 StringFormat("Day=%.2f Week=%.2f Month=%.2f Eff=%.0f Stab=%.0f\r\n",
                              r.daily_growth, r.weekly_growth, r.monthly_growth,
                              r.capital_efficiency_score, r.growth_stability_score));
      WriteTable("multi_symbol_framework",
                 "=== multi_symbol_framework ===\r\n" + head + r.multi_symbol_report);

      const string line = StringFormat("%s | intel=%.0f health=%.0f risk=%.0f eff=%.0f div=%.0f live=%s",
                                       ts, r.portfolio_intelligence_score,
                                       r.portfolio_health_index, r.portfolio_risk_score,
                                       r.capital_efficiency_score, r.diversification_score,
                                       r.live_symbol);
      if(m_n < GM_PI_HIST_MAX)
         m_rows[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_PI_HIST_MAX; i++)
            m_rows[i - 1] = m_rows[i];
         m_rows[GM_PI_HIST_MAX - 1] = line;
        }

      const ulong now = GetTickCount();
      if(m_last_persist_ms == 0 || (now - m_last_persist_ms) > 9000)
        {
         Persist();
         m_last_persist_ms = now;
         if(m_logger != NULL)
            m_logger.Info("Database Synchronization Completed | Portfolio Intelligence tables", "AIPI");
        }
     }
  };

#endif // GM_CPORTFOLIO_INTELLIGENCE_DATABASE_MQH
//+------------------------------------------------------------------+
