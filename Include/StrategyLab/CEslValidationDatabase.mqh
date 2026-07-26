//+------------------------------------------------------------------+
//|                                  CEslValidationDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CESL_VALIDATION_DATABASE_MQH
#define GM_CESL_VALIDATION_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmStrategyLabResult.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"

class CGmEslValidationDatabase
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
                     CGmEslValidationDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_ESL_DB_PREFIX, magic, sym);
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Database Updated | Strategy Lab DB Ready | " + m_pfx, "ESL");
      return true;
     }

   string Prefix(void) const { return m_pfx; }
   void Shutdown(void) { m_ready = false; }

   void Persist(const SGmStrategyLabResult &r)
     {
      if(!m_ready || m_files == NULL || !r.valid)
         return;
      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s\r\n", ts);

      WriteTable("backtest_reports", head + r.backtest_summary + "\r\n");
      WriteTable("simulation_reports", head + r.monte_carlo_summary + "\r\n" + r.probability_report + "\r\n");
      WriteTable("walk_forward_reports", head + r.walk_forward_summary + "\r\n");
      WriteTable("validation_reports", head + r.validation_status + "\r\n" +
                 StringFormat("Institutional=%.1f Robust=%.1f\r\n",
                              r.institutional_score, r.robustness_score));
      WriteTable("optimization_reports", head + r.optimization_report + "\r\n");
      WriteTable("historical_datasets",
                 head + StringFormat("Bars=%d Coverage=%.1f%% Trades=%d\r\n",
                                     r.bars_covered, r.historical_coverage_pct, r.simulated_trades));
      WriteTable("comparison_reports", head + r.comparison_matrix + "\r\n");

      if(m_logger != NULL)
         m_logger.Debug("Database Updated | ESL tables persisted", "ESL");
     }
  };

#endif // GM_CESL_VALIDATION_DATABASE_MQH
//+------------------------------------------------------------------+
