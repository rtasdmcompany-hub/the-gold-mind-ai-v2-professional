//+------------------------------------------------------------------+
//|                                  CLearningHistoryDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CLEARNING_HISTORY_DATABASE_MQH
#define GM_CLEARNING_HISTORY_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmLearningAnalysisResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmLearningHistoryDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_file;
   string          m_rows[GM_LEARN_HIST_MAX];
   int             m_n;
   ulong           m_last_persist_ms;
   bool            m_ready;

public:
                     CGmLearningHistoryDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_file(""), m_n(0),
                         m_last_persist_ms(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_file = StringFormat("%sHIST_%I64d_%s.txt", GM_LEARN_DB_PREFIX, magic, sym);
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

   void Record(const SGmLearningAnalysisResult &r)
     {
      if(!m_ready || !r.valid)
         return;
      const string line = StringFormat(
                             "%s | SID=%I64u | prog=%.0f | pred=%.0f | confAcc=%.0f | pat=%.0f | reco=%.0f | kb=%d | xp=%s | %s",
                             TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS),
                             r.session_id,
                             r.learning_progress,
                             r.prediction_accuracy,
                             r.confidence_accuracy,
                             r.pattern_accuracy,
                             r.recommendation_accuracy,
                             r.knowledge_entries,
                             GmLearnXpName(r.experience),
                             GM_LEARN_ADVISOR_ONLY);
      if(m_n < GM_LEARN_HIST_MAX)
         m_rows[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_LEARN_HIST_MAX; i++)
            m_rows[i - 1] = m_rows[i];
         m_rows[GM_LEARN_HIST_MAX - 1] = line;
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
      string body = "=== AI LEARNING HISTORY DATABASE ===\r\n";
      body += "POLICY: ANALYTICAL ONLY | NEVER MODIFY STRATEGY\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      m_files.WriteText(m_file, body);
     }
  };

#endif // GM_CLEARNING_HISTORY_DATABASE_MQH
//+------------------------------------------------------------------+
