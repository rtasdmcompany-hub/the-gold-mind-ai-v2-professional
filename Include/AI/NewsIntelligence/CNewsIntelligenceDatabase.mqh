//+------------------------------------------------------------------+
//|                                CNewsIntelligenceDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CNEWS_INTELLIGENCE_DATABASE_MQH
#define GM_CNEWS_INTELLIGENCE_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmNewsIntelligenceResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmNewsIntelligenceDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_rows[GM_NI_HIST_MAX];
   int             m_n;
   ulong           m_last_persist_ms;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL) return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmNewsIntelligenceDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_n(0),
                         m_last_persist_ms(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_NI_DB_PREFIX, magic, sym);
      m_n = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("News Intelligence Database Ready | " + m_pfx, "AINI");
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
      string body = "=== news_statistics_index ===\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      m_files.WriteText(m_pfx + "news_statistics.txt", body);
     }

   void Record(const SGmNewsIntelligenceResult &r)
     {
      if(!m_ready || !r.valid) return;

      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s | SessionID=%I64u | Symbol=%s\r\n",
                                       ts, r.session_id, r.symbol);

      WriteTable("economic_events",
                 "=== economic_events ===\r\n" + head +
                 StringFormat("Upcoming=%s | Class=%s | Countdown=%s | Events=%d\r\n%s\r\n",
                              r.upcoming_news, GmNiEventClassName(r.event_class),
                              r.countdown_text, r.event_count, r.calendar_summary));
      WriteTable("forecasts", "=== forecasts ===\r\n" + head + r.forecast_report);
      WriteTable("impact_scores",
                 "=== impact_scores ===\r\n" + head +
                 StringFormat("ImpactScore=%.0f | Class=%s\r\n%s\r\n",
                              r.news_impact_score, GmNiImpactName(r.impact_class),
                              r.impact_report));
      WriteTable("volatility_forecast",
                 "=== volatility_forecast ===\r\n" + head + r.forecast_report);
      WriteTable("gold_sentiment",
                 "=== gold_sentiment ===\r\n" + head + r.gold_report);
      WriteTable("historical_comparisons",
                 "=== historical_comparisons ===\r\n" + head + r.historical_report);

      const string line = StringFormat("%s | %s impact=%.0f gold=%.0f atrF=%.0f sim=%.0f",
                                       ts, r.upcoming_news,
                                       r.news_impact_score, r.gold_sentiment_score,
                                       r.atr_forecast, r.historical_similarity);
      if(m_n < GM_NI_HIST_MAX)
         m_rows[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_NI_HIST_MAX; i++)
            m_rows[i - 1] = m_rows[i];
         m_rows[GM_NI_HIST_MAX - 1] = line;
        }

      const ulong now = GetTickCount();
      if(m_last_persist_ms == 0 || (now - m_last_persist_ms) > 9000)
        {
         Persist();
         m_last_persist_ms = now;
         if(m_logger != NULL)
            m_logger.Info("Database Synchronization Completed | News Intelligence tables", "AINI");
        }
     }
  };

#endif // GM_CNEWS_INTELLIGENCE_DATABASE_MQH
//+------------------------------------------------------------------+
