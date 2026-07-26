//+------------------------------------------------------------------+
//|                                CEolOptimizationDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEOL_OPTIMIZATION_DATABASE_MQH
#define GM_CEOL_OPTIMIZATION_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmOptimizationLabResult.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"

class CGmEolOptimizationDatabase
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
                     CGmEolOptimizationDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_EOL_DB_PREFIX, magic, sym);
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Database Updated | Optimization Lab DB Ready | " + m_pfx, "EOL");
      return true;
     }

   string Prefix(void) const { return m_pfx; }
   void Shutdown(void) { m_ready = false; }

   void Persist(const SGmOptimizationLabResult &r)
     {
      if(!m_ready || m_files == NULL || !r.valid)
         return;
      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s\r\n", ts);

      WriteTable("comparison_reports", head + r.comparison_summary + "\r\n" + r.ranking_summary);
      WriteTable("optimization_reports", head + r.optimization_suggestions + "\r\n");
      WriteTable("recommendation_reports", head + r.recommendation_report + "\r\n");
      WriteTable("validation_reports", head + r.adaptability_report + "\r\n" + r.validation_status);
      WriteTable("parameter_history", head + r.parameter_report + "\r\n");
      WriteTable("historical_rankings", head + r.ranking_summary + "\r\n" +
                 StringFormat("TopRank=%.1f Best=%s\r\n", r.historical_rank_top, r.best_profile));

      if(m_logger != NULL)
         m_logger.Debug("Database Updated | EOL tables persisted", "EOL");
     }
  };

#endif // GM_CEOL_OPTIMIZATION_DATABASE_MQH
//+------------------------------------------------------------------+
