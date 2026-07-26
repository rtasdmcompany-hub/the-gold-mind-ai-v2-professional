//+------------------------------------------------------------------+
//|                                  CLearningMemoryDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CLEARNING_MEMORY_DATABASE_MQH
#define GM_CLEARNING_MEMORY_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMemoryLearningResult.mqh"
#include "CAIKnowledgeGraph.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmLearningMemoryDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_rows[GM_MEM_HIST_MAX];
   int             m_n;
   ulong           m_last_persist_ms;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL)
         return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmLearningMemoryDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_n(0),
                         m_last_persist_ms(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_MEM_DB_PREFIX, magic, sym);
      m_n = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Learning Memory Database Ready | " + m_pfx, "AIMem");
      return true;
     }

   void Shutdown(void)
     {
      PersistIndex();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }

   void PersistIndex(void)
     {
      if(!m_ready || m_files == NULL)
         return;
      string body = "=== ai_learning_results index ===\r\n";
      body += "POLICY=" + GM_MEM_ANALYSIS_ONLY + "\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      m_files.WriteText(m_pfx + "ai_learning_results.txt", body);
     }

   void Record(const SGmMemoryLearningResult &r, CGmAIKnowledgeGraph &graph)
     {
      if(!m_ready || !r.valid)
         return;

      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat(
                             "Timestamp=%s | SessionID=%I64u | Symbol=%s | Learn=%.0f | Conf=%.0f | %s\r\n",
                             ts, r.session_id, r.symbol, r.learning_accuracy,
                             r.calibrated_confidence, r.advisory_status);

      WriteTable("ai_memory_records",
                 "=== ai_memory_records ===\r\n" + head + r.memory_profile + "\r\n");
      WriteTable("ai_learning_results",
                 "=== ai_learning_results ===\r\n" + head + r.learning_report + "\r\n");
      WriteTable("market_behavior_patterns",
                 "=== market_behavior_patterns ===\r\n" + head + r.behavior_map + "\r\n");
      WriteTable("discovered_patterns",
                 "=== discovered_patterns ===\r\n" + head + r.pattern_report + "\r\n");
      WriteTable("confidence_history",
                 "=== confidence_history ===\r\n" + head +
                 StringFormat("Prev=%.0f Adj=%.0f Reason=%s\r\n",
                              r.previous_confidence, r.calibrated_confidence,
                              r.calibration_reason));
      WriteTable("knowledge_graph_nodes", graph.ExportNodes());
      WriteTable("knowledge_graph_relationships", graph.ExportEdges());

      const string line = StringFormat(
                             "%s | SID=%I64u | acc=%.0f | cal=%.0f | beh=%s | improve=%.0f | %s",
                             ts, r.session_id, r.learning_accuracy, r.calibrated_confidence,
                             r.behavior_label, r.improvement_score, GM_MEM_ANALYSIS_ONLY);
      if(m_n < GM_MEM_HIST_MAX)
         m_rows[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_MEM_HIST_MAX; i++)
            m_rows[i - 1] = m_rows[i];
         m_rows[GM_MEM_HIST_MAX - 1] = line;
        }

      const ulong now = GetTickCount();
      if(m_last_persist_ms == 0 || (now - m_last_persist_ms) > 8000)
        {
         PersistIndex();
         m_last_persist_ms = now;
         if(m_logger != NULL)
            m_logger.Info("Database Synchronization Completed | Memory tables", "AIMem");
        }
     }
  };

#endif // GM_CLEARNING_MEMORY_DATABASE_MQH
//+------------------------------------------------------------------+
