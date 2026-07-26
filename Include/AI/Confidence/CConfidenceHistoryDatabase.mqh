//+------------------------------------------------------------------+
//|                               CConfidenceHistoryDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CCONFIDENCE_HISTORY_DATABASE_MQH
#define GM_CCONFIDENCE_HISTORY_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmConfidenceAnalysisResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmConfidenceHistoryDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_file;
   string          m_rows[GM_CONF_HIST_MAX];
   double          m_scores[GM_CONF_HIST_MAX];
   int             m_n;
   ulong           m_last_persist_ms;
   bool            m_ready;

public:
                     CGmConfidenceHistoryDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_file(""), m_n(0),
                         m_last_persist_ms(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_file = StringFormat("%s%I64d_%s.txt", GM_CONF_DB_PREFIX, magic, sym);
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

   int Count(void) const { return m_n; }

   double AverageConfidence(void) const
     {
      if(m_n <= 0)
         return 0.0;
      double s = 0.0;
      for(int i = 0; i < m_n; i++)
         s += m_scores[i];
      return s / (double)m_n;
     }

   string RecentSnippet(const int max_items = 3) const
     {
      if(m_n <= 0)
         return "—";
      string out = "";
      const int start = MathMax(0, m_n - max_items);
      for(int i = start; i < m_n; i++)
        {
         if(StringLen(out) > 0)
            out += " / ";
         out += StringFormat("%.0f", m_scores[i]);
        }
      return out;
     }

   double PrevScore(void) const
     {
      if(m_n < 2)
         return (m_n == 1) ? m_scores[0] : 0.0;
      return m_scores[m_n - 2];
     }

   void Record(const SGmConfidenceAnalysisResult &r)
     {
      if(!m_ready || !r.valid)
         return;
      const string line = StringFormat(
                             "%s | SID=%I64u | conf=%.0f | TQ=%.0f | MQ=%.0f | env=%s | reco=%s | ATR=%.5f | trend=%s | vol=%.0f | news=%.0f | %s",
                             TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS),
                             r.session_id,
                             r.overall_confidence,
                             r.trade_quality,
                             r.market_quality,
                             GmConfEnvName(r.environment),
                             GmConfRecoName(r.recommendation),
                             r.atr14,
                             r.trend_label,
                             r.volatility_score,
                             r.news_risk,
                             GM_CONF_ADVISOR_ONLY);

      if(m_n < GM_CONF_HIST_MAX)
        {
         m_rows[m_n] = line;
         m_scores[m_n] = r.overall_confidence;
         m_n++;
        }
      else
        {
         for(int i = 1; i < GM_CONF_HIST_MAX; i++)
           {
            m_rows[i - 1] = m_rows[i];
            m_scores[i - 1] = m_scores[i];
           }
         m_rows[GM_CONF_HIST_MAX - 1] = line;
         m_scores[GM_CONF_HIST_MAX - 1] = r.overall_confidence;
        }

      const ulong now = GetTickCount();
      if(m_last_persist_ms == 0 || (now - m_last_persist_ms) > 5000)
        {
         Persist();
         m_last_persist_ms = now;
        }
     }

   void Persist(void)
     {
      if(!m_ready || m_files == NULL)
         return;
      string body = "=== AI CONFIDENCE HISTORY DATABASE ===\r\n";
      body += "POLICY: ADVISOR ONLY | NO EXECUTION AUTHORITY\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      m_files.WriteText(m_file, body);
     }
  };

#endif // GM_CCONFIDENCE_HISTORY_DATABASE_MQH
//+------------------------------------------------------------------+
