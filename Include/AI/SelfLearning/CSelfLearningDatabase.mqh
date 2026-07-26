//+------------------------------------------------------------------+
//|                                   CSelfLearningDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CSELF_LEARNING_DATABASE_MQH
#define GM_CSELF_LEARNING_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmSelfLearningResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmSelfLearningDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_rows[GM_SL_HIST_MAX];
   int             m_n;
   ulong           m_last_persist_ms;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL) return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmSelfLearningDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_n(0),
                         m_last_persist_ms(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_SL_DB_PREFIX, magic, sym);
      m_n = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Self-Learning Knowledge Database Ready | " + m_pfx, "AISL");
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
      string body = "=== knowledge_history_index ===\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      m_files.WriteText(m_pfx + "knowledge_history.txt", body);
     }

   void Record(const SGmSelfLearningResult &r)
     {
      if(!m_ready || !r.valid) return;

      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s | SessionID=%I64u | Symbol=%s\r\n",
                                       ts, r.session_id, r.symbol);

      WriteTable("learning_reports", "=== learning_reports ===\r\n" + head + r.learning_report);
      WriteTable("knowledge_reports", "=== knowledge_reports ===\r\n" + head + r.knowledge_report);
      WriteTable("recommendations", "=== recommendations ===\r\n" + head + r.recommendation_report);
      WriteTable("optimization_reports", "=== optimization_reports ===\r\n" + head + r.optimization_report);
      WriteTable("pattern_library", "=== pattern_library ===\r\n" + head + r.pattern_library);
      WriteTable("historical_intelligence", "=== historical_intelligence ===\r\n" + head + r.historical_intelligence);
      WriteTable("validation_reports", "=== validation_reports ===\r\n" + head + r.validation_report);

      const string line = StringFormat("%s | conf=%.0f idx=%.0f growth=%.0f stab=%.0f opt=%.0f cert=%s pats=%d",
                                       ts, r.learning_confidence, r.knowledge_index,
                                       r.knowledge_growth, r.learning_stability,
                                       r.optimization_score, GmSlCertName(r.learning_certification),
                                       r.patterns_discovered);
      if(m_n < GM_SL_HIST_MAX)
         m_rows[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_SL_HIST_MAX; i++)
            m_rows[i - 1] = m_rows[i];
         m_rows[GM_SL_HIST_MAX - 1] = line;
        }

      const ulong now = GetTickCount();
      if(m_last_persist_ms == 0 || (now - m_last_persist_ms) > 9000)
        {
         Persist();
         m_last_persist_ms = now;
         if(m_logger != NULL)
            m_logger.Info("Knowledge Updated | Self-Learning tables persisted", "AISL");
        }
     }
  };

#endif // GM_CSELF_LEARNING_DATABASE_MQH
//+------------------------------------------------------------------+
