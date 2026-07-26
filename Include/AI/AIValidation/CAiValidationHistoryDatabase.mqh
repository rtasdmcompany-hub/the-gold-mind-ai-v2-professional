//+------------------------------------------------------------------+
//|                                CAiValidationHistoryDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CAI_VALIDATION_HISTORY_DATABASE_MQH
#define GM_CAI_VALIDATION_HISTORY_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmAIValidationResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmAiValidationHistoryDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_file;
   string          m_rows[GM_AIVAL_HIST_MAX];
   int             m_n;
   ulong           m_last_persist_ms;
   bool            m_ready;

public:
                     CGmAiValidationHistoryDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_file(""), m_n(0),
                         m_last_persist_ms(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_file = StringFormat("%sHIST_%I64d_%s.txt", GM_AIVAL_DB_PREFIX, magic, sym);
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

   void Record(const SGmAIValidationResult &r)
     {
      if(!m_ready || !r.valid)
         return;
      const string line = StringFormat(
                             "%s | SID=%I64u | acc=%.0f | pred=%.0f | confAcc=%.0f | cert=%.0f | fwd=%.0f | bkt=%.0f | drift=%s | grade=%s | %s",
                             TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS),
                             r.session_id,
                             r.ai_accuracy,
                             r.prediction_accuracy,
                             r.confidence_accuracy,
                             r.certification_score,
                             r.forward_test_score,
                             r.backtest_score,
                             r.drift_alert ? GmAiValDriftName(r.drift_type) : "OK",
                             GmAiValGradeName(r.reliability_grade),
                             GM_AIVAL_ANALYSIS_ONLY);
      if(m_n < GM_AIVAL_HIST_MAX)
         m_rows[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_AIVAL_HIST_MAX; i++)
            m_rows[i - 1] = m_rows[i];
         m_rows[GM_AIVAL_HIST_MAX - 1] = line;
        }
      const ulong now = GetTickCount();
      if(m_last_persist_ms == 0 || (now - m_last_persist_ms) > 8000)
        {
         Persist();
         m_last_persist_ms = now;
        }
     }

   void Persist(void)
     {
      if(!m_ready || m_files == NULL)
         return;
      string body = "=== AI VALIDATION HISTORY DATABASE ===\r\n";
      body += "POLICY: VALIDATION ONLY | NEVER MODIFY STRATEGY\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      m_files.WriteText(m_file, body);
     }
  };

#endif // GM_CAI_VALIDATION_HISTORY_DATABASE_MQH
//+------------------------------------------------------------------+
