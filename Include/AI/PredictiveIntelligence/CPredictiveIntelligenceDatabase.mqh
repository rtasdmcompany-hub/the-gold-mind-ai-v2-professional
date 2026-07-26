//+------------------------------------------------------------------+
//|                            CPredictiveIntelligenceDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CPREDICTIVE_INTELLIGENCE_DATABASE_MQH
#define GM_CPREDICTIVE_INTELLIGENCE_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmPredictiveIntelligenceResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmPredictiveIntelligenceDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_rows[GM_PRED_HIST_MAX];
   int             m_n;
   ulong           m_last_persist_ms;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL) return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmPredictiveIntelligenceDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_n(0),
                         m_last_persist_ms(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_PRED_DB_PREFIX, magic, sym);
      m_n = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Predictive Intelligence Database Ready | " + m_pfx, "AIPRED");
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
      string body = "=== confidence_history_index ===\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      m_files.WriteText(m_pfx + "confidence_history.txt", body);
     }

   void Record(const SGmPredictiveIntelligenceResult &r)
     {
      if(!m_ready || !r.valid) return;

      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s | SessionID=%I64u | Symbol=%s\r\n",
                                       ts, r.session_id, r.symbol);

      WriteTable("predictions", "=== predictions ===\r\n" + head + r.predictive_report);
      WriteTable("scenarios", "=== scenarios ===\r\n" + head + r.scenario_report);
      WriteTable("historical_comparisons", "=== historical_comparisons ===\r\n" + head + r.historical_report);
      WriteTable("probability_reports", "=== probability_reports ===\r\n" + head + r.probability_report);
      WriteTable("forecast_reports", "=== forecast_reports ===\r\n" + head + r.path_report);

      const string line = StringFormat("%s | conf=%.0f rel=%.0f scn=%s(%.0f) bull=%.0f bear=%.0f overall=%.0f",
                                       ts, r.prediction_confidence, r.forecast_reliability,
                                       GmPredScenarioName(r.dominant_scenario), r.scenario_probability,
                                       r.bullish_probability, r.bearish_probability,
                                       r.overall_probability_score);
      if(m_n < GM_PRED_HIST_MAX)
         m_rows[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_PRED_HIST_MAX; i++)
            m_rows[i - 1] = m_rows[i];
         m_rows[GM_PRED_HIST_MAX - 1] = line;
        }

      const ulong now = GetTickCount();
      if(m_last_persist_ms == 0 || (now - m_last_persist_ms) > 9000)
        {
         Persist();
         m_last_persist_ms = now;
         if(m_logger != NULL)
            m_logger.Info("Database Synchronization Completed | Predictive Intelligence tables", "AIPRED");
        }
     }
  };

#endif // GM_CPREDICTIVE_INTELLIGENCE_DATABASE_MQH
//+------------------------------------------------------------------+
