//+------------------------------------------------------------------+
//|                               CVolatilityHistoryDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CVOLATILITY_HISTORY_DATABASE_MQH
#define GM_CVOLATILITY_HISTORY_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmVolatilityAnalysisResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmVolatilityHistoryDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_file;
   string          m_rows[GM_VOL_HIST_MAX];
   int             m_n;
   ulong           m_last_persist_ms;
   bool            m_ready;

public:
                     CGmVolatilityHistoryDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_file(""), m_n(0),
                         m_last_persist_ms(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_file = StringFormat("%s%I64d_%s.txt", GM_VOL_DB_PREFIX, magic, sym);
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

   void Record(const SGmVolatilityAnalysisResult &r)
     {
      if(!m_ready || !r.valid)
         return;
      const string line = StringFormat(
                             "%s | SID=%I64u | ATR=%.5f | energy=%s(%.0f) | phase=%s | large=%.0f | conf=%.0f",
                             TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS),
                             r.session_id,
                             r.atr14,
                             GmEnergyName(r.energy),
                             r.energy_score,
                             GmVolPhaseName(r.phase),
                             r.prob_large_move,
                             r.confidence);
      if(m_n < GM_VOL_HIST_MAX)
         m_rows[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_VOL_HIST_MAX; i++)
            m_rows[i - 1] = m_rows[i];
         m_rows[GM_VOL_HIST_MAX - 1] = line;
        }

      // Throttle disk writes
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
      string body = "=== AI VOLATILITY HISTORY DATABASE ===\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      body += "ANALYSIS ONLY\r\n";
      m_files.WriteText(m_file, body);
     }
  };

#endif // GM_CVOLATILITY_HISTORY_DATABASE_MQH
//+------------------------------------------------------------------+
