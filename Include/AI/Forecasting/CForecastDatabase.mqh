//+------------------------------------------------------------------+
//|                                         CForecastDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CFORECAST_DATABASE_MQH
#define GM_CFORECAST_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmForecastResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmForecastDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_rows[GM_FCST_HIST_MAX];
   int             m_n;
   ulong           m_last_persist_ms;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL) return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmForecastDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_n(0),
                         m_last_persist_ms(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_FCST_DB_PREFIX, magic, sym);
      m_n = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Forecast Database Ready | " + m_pfx, "AIFcst");
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
      string body = "=== forecast_accuracy_history / index ===\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      m_files.WriteText(m_pfx + "forecast_accuracy_history.txt", body);
     }

   void Record(const SGmForecastResult &r)
     {
      if(!m_ready || !r.valid) return;

      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("ForecastID=%s | Timestamp=%s | SessionID=%I64u | Conf=%.0f\r\n",
                                       r.forecast_id, ts, r.session_id, r.forecast_confidence);

      WriteTable("ai_market_forecasts",
                 "=== ai_market_forecasts ===\r\n" + head + r.market_forecast_report);
      WriteTable("scenario_predictions",
                 "=== scenario_predictions ===\r\n" + head + r.scenario_report);
      WriteTable("probability_reports",
                 "=== probability_reports ===\r\n" + head + r.probability_matrix);
      WriteTable("market_transitions",
                 "=== market_transitions ===\r\n" + head + r.transition_alert);
      WriteTable("scenario_results",
                 "=== scenario_results ===\r\n" + head +
                 StringFormat("Dominant=%s | Accuracy=%.0f | ActualOutcome=PENDING (observe-only)\r\n%s\r\n%s\r\n",
                              GmFcstScenarioName(r.dominant_scenario), r.accuracy_score,
                              r.technical_summary, r.ai_explanation));

      const string line = StringFormat("%s | id=%s out=%s scn=%s acc=%.0f conf=%.0f",
                                       ts, r.forecast_id, GmFcstOutlookName(r.outlook),
                                       GmFcstScenarioName(r.dominant_scenario),
                                       r.accuracy_score, r.forecast_confidence);
      if(m_n < GM_FCST_HIST_MAX)
         m_rows[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_FCST_HIST_MAX; i++)
            m_rows[i - 1] = m_rows[i];
         m_rows[GM_FCST_HIST_MAX - 1] = line;
        }

      const ulong now = GetTickCount();
      if(m_last_persist_ms == 0 || (now - m_last_persist_ms) > 9000)
        {
         Persist();
         m_last_persist_ms = now;
         if(m_logger != NULL)
            m_logger.Info("Database Synchronization Completed | Forecast tables", "AIFcst");
        }
     }
  };

#endif // GM_CFORECAST_DATABASE_MQH
//+------------------------------------------------------------------+
