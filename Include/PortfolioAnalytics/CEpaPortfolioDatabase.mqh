//+------------------------------------------------------------------+
//|                                 CEpaPortfolioDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEPA_PORTFOLIO_DATABASE_MQH
#define GM_CEPA_PORTFOLIO_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmPortfolioAnalyticsResult.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"

class CGmEpaPortfolioDatabase
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
                     CGmEpaPortfolioDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_EPA_DB_PREFIX, magic, sym);
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Database Updated | Portfolio Analytics DB Ready | " + m_pfx, "EPA");
      return true;
     }

   string Prefix(void) const { return m_pfx; }
   void Shutdown(void) { m_ready = false; }

   void Persist(const SGmPortfolioAnalyticsResult &r)
     {
      if(!m_ready || m_files == NULL || !r.valid) return;
      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s\r\n", ts);

      WriteTable("portfolio_reports", head + StringFormat("Health=%.1f D/W/M/Y=%.2f/%.2f/%.2f/%.2f\r\n",
                                                          r.portfolio_health, r.daily_pnl, r.weekly_pnl,
                                                          r.monthly_pnl, r.yearly_pnl));
      WriteTable("risk_reports", head + r.risk_report + "\r\n");
      WriteTable("capital_reports", head + r.capital_report + "\r\n");
      WriteTable("performance_reports", head + r.performance_report + "\r\n");
      WriteTable("equity_curves", head + r.equity_curve_summary + "\r\n" + r.performance_timeline + "\r\n");
      WriteTable("drawdown_curves", head + r.drawdown_curve_summary + "\r\n");
      WriteTable("historical_snapshots", head + r.monthly_heatmap + "\r\n" + r.growth_curve_summary + "\r\n");

      if(m_logger != NULL)
         m_logger.Debug("Database Updated | EPA tables persisted", "EPA");
     }
  };

#endif // GM_CEPA_PORTFOLIO_DATABASE_MQH
//+------------------------------------------------------------------+
