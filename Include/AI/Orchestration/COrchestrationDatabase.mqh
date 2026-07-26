//+------------------------------------------------------------------+
//|                                    COrchestrationDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CORCHESTRATION_DATABASE_MQH
#define GM_CORCHESTRATION_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmOrchestrationResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmOrchestrationDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_rows[GM_ORCH_HIST_MAX];
   int             m_n;
   ulong           m_last_persist_ms;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL) return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmOrchestrationDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_n(0),
                         m_last_persist_ms(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_ORCH_DB_PREFIX, magic, sym);
      m_n = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Orchestration Database Ready | " + m_pfx, "AIOrch");
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
      string body = "=== ai_fusion_results / index ===\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      m_files.WriteText(m_pfx + "ai_fusion_results.txt", body);
     }

   void Record(const SGmOrchestrationResult &r)
     {
      if(!m_ready || !r.valid) return;

      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s | SessionID=%I64u | Score=%.0f\r\n",
                                       ts, r.session_id, r.intelligence_score);

      WriteTable("ai_decision_reports",
                 "=== ai_decision_reports ===\r\n" + head + r.decision_support_report);
      WriteTable("ai_intelligence_scores",
                 "=== ai_intelligence_scores ===\r\n" + head + r.fusion_report);
      WriteTable("ai_priority_queue",
                 "=== ai_priority_queue ===\r\n" + head + r.priority_queue);
      WriteTable("ai_insight_records",
                 "=== ai_insight_records ===\r\n" + head +
                 StringFormat("Primary=%s\r\nMarket=%s\r\nRisk=%s\r\nPerf=%s\r\nLearn=%s\r\nSys=%s\r\n",
                              r.primary_insight, r.market_insight, r.risk_insight,
                              r.performance_insight, r.learning_insight, r.system_insight));
      WriteTable("ai_knowledge_links",
                 "=== ai_knowledge_links ===\r\n" + head +
                 StringFormat("%s\r\nLinks=%s\r\n", r.knowledge_network, r.knowledge_links));

      const string line = StringFormat("%s | intel=%.0f grade=%s conf=%.0f pri=%d nodes=%d",
                                       ts, r.intelligence_score, GmOrchGradeName(r.intelligence_grade),
                                       r.unified_confidence, r.priority_count, r.graph_nodes);
      if(m_n < GM_ORCH_HIST_MAX)
         m_rows[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_ORCH_HIST_MAX; i++)
            m_rows[i - 1] = m_rows[i];
         m_rows[GM_ORCH_HIST_MAX - 1] = line;
        }

      const ulong now = GetTickCount();
      if(m_last_persist_ms == 0 || (now - m_last_persist_ms) > 9000)
        {
         Persist();
         m_last_persist_ms = now;
         if(m_logger != NULL)
            m_logger.Info("Database Synchronization Completed | Orchestration tables", "AIOrch");
        }
     }
  };

#endif // GM_CORCHESTRATION_DATABASE_MQH
//+------------------------------------------------------------------+
