//+------------------------------------------------------------------+
//|                                    CTrendHistoryDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CTREND_HISTORY_DATABASE_MQH
#define GM_CTREND_HISTORY_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmTrendAnalysisResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmTrendHistoryDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_file;
   string          m_rows[GM_TREND_HIST_MAX];
   int             m_n;
   bool            m_ready;

public:
                     CGmTrendHistoryDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_file(""), m_n(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_file = StringFormat("%s%I64d_%s.txt", GM_TREND_DB_PREFIX, magic, sym);
      m_n = 0;
      m_ready = true;
      return true;
     }

   void Shutdown(void)
     {
      Persist();
      m_ready = false;
     }

   void Record(const SGmTrendAnalysisResult &r)
     {
      if(!m_ready || !r.valid)
         return;
      const string line = StringFormat(
                             "%s | SID=%I64u | dir=%s | str=%.0f | phase=%s | struct=%s | conf=%.0f | dur=%d",
                             TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS),
                             r.session_id,
                             GmTrendDirName(r.primary),
                             r.strength_score,
                             GmTrendPhaseName(r.phase),
                             GmTrendStructName(r.structure),
                             r.confidence,
                             r.trend_duration_bars);
      if(m_n < GM_TREND_HIST_MAX)
         m_rows[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_TREND_HIST_MAX; i++)
            m_rows[i - 1] = m_rows[i];
         m_rows[GM_TREND_HIST_MAX - 1] = line;
        }
     }

   void Persist(void)
     {
      if(!m_ready || m_files == NULL)
         return;
      string body = "=== AI TREND HISTORY DATABASE ===\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      body += "ANALYSIS ONLY\r\n";
      m_files.WriteText(m_file, body);
     }
  };

#endif // GM_CTREND_HISTORY_DATABASE_MQH
//+------------------------------------------------------------------+
