//+------------------------------------------------------------------+
//|                                  CDecisionHistoryDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CDECISION_HISTORY_DATABASE_MQH
#define GM_CDECISION_HISTORY_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmDecisionSupportResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmDecisionHistoryDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_file;
   string          m_rows[GM_DEC_HIST_MAX];
   int             m_n;
   ulong           m_last_persist_ms;
   bool            m_ready;

public:
                     CGmDecisionHistoryDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_file(""), m_n(0),
                         m_last_persist_ms(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_file = StringFormat("%s%I64d_%s.txt", GM_DEC_DB_PREFIX, magic, sym);
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

   void Record(const SGmDecisionSupportResult &r)
     {
      if(!m_ready || !r.valid)
         return;
      string factors = r.top_factors_summary;
      string expl = r.explanation;
      if(StringLen(expl) > 120)
         expl = StringSubstr(expl, 0, 117) + "...";
      const string line = StringFormat(
                             "%s | SID=%I64u | reco=%s | conf=%.0f | sim=%.0f | match=%s | health=%.0f | factors=[%s] | %s | %s",
                             TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS),
                             r.session_id,
                             GmDecRecoName(r.recommendation),
                             r.overall_confidence,
                             r.historical_similarity,
                             GmDecMatchName(r.strategy_match),
                             r.market_health,
                             factors,
                             expl,
                             GM_DEC_ADVISORY_ONLY);
      if(m_n < GM_DEC_HIST_MAX)
         m_rows[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_DEC_HIST_MAX; i++)
            m_rows[i - 1] = m_rows[i];
         m_rows[GM_DEC_HIST_MAX - 1] = line;
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
      string body = "=== AI DECISION HISTORY DATABASE ===\r\n";
      body += "POLICY: ADVISORY ONLY | NO EXECUTION AUTHORITY\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      m_files.WriteText(m_file, body);
     }
  };

#endif // GM_CDECISION_HISTORY_DATABASE_MQH
//+------------------------------------------------------------------+
