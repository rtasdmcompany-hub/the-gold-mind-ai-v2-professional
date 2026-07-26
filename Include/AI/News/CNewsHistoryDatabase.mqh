//+------------------------------------------------------------------+
//|                                    CNewsHistoryDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CNEWS_HISTORY_DATABASE_MQH
#define GM_CNEWS_HISTORY_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmNewsAnalysisResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmNewsHistoryDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_file;
   string          m_rows[GM_NEWS_HIST_MAX];
   int             m_n;
   ulong           m_last_persist_ms;
   bool            m_ready;

public:
                     CGmNewsHistoryDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_file(""), m_n(0),
                         m_last_persist_ms(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_file = StringFormat("%s%I64d_%s.txt", GM_NEWS_DB_PREFIX, magic, sym);
      m_n = 0;
      m_last_persist_ms = 0;
      m_ready = true;
      return true;
     }

   void Shutdown(void)
     {
      Persist();
      m_ready = false;
     }

   void Record(const SGmNewsAnalysisResult &r)
     {
      if(!m_ready || !r.valid)
         return;
      const string line = StringFormat(
                             "%s | SID=%I64u | next=%s | high=%s | impact=%s | risk=%.0f | react=%s | atrΔ=%.0f | spread=%.0f | conf=%.0f | %s",
                             TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS),
                             r.session_id,
                             r.upcoming.valid ? r.upcoming.name : "-",
                             r.next_high_impact.valid ? r.next_high_impact.name : "-",
                             GmNewsImpactName(r.current_impact),
                             r.news_risk_score,
                             GmNewsReactionName(r.reaction_status),
                             r.reaction.atr_change_pct,
                             r.reaction.spread_after,
                             r.confidence,
                             GM_NEWS_NO_TRADE_BLOCK);
      if(m_n < GM_NEWS_HIST_MAX)
         m_rows[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_NEWS_HIST_MAX; i++)
            m_rows[i - 1] = m_rows[i];
         m_rows[GM_NEWS_HIST_MAX - 1] = line;
        }

      const ulong now = GetTickCount();
      if(m_last_persist_ms == 0 || (now - m_last_persist_ms) > 5000)
        {
         Persist();
         m_last_persist_ms = now;
         if(m_logger != NULL)
            m_logger.Info("Database Updated | " + m_file, "NewsDB");
        }
     }

   /// @brief Historical statistics helper for Decision API consumers.
   int Count(void) const { return m_n; }

   void Persist(void)
     {
      if(!m_ready || m_files == NULL)
         return;
      string body = "=== AI NEWS HISTORY DATABASE ===\r\n";
      body += "POLICY: ANALYSIS ONLY | NEVER BLOCK TRADES\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      m_files.WriteText(m_file, body);
     }
  };

#endif // GM_CNEWS_HISTORY_DATABASE_MQH
//+------------------------------------------------------------------+
