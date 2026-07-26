//+------------------------------------------------------------------+
//|                                    CIntelligenceDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CINTELLIGENCE_DATABASE_MQH
#define GM_CINTELLIGENCE_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmIntelligenceResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

/// @brief Expands supervisor persistence with intelligence report tables (file-backed).
class CGmIntelligenceDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_hist_file;
   string          m_rows[GM_INTEL_HIST_MAX];
   int             m_n;
   ulong           m_last_persist_ms;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL)
         return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

   void PersistHist(void)
     {
      if(!m_ready || m_files == NULL)
         return;
      string body = "=== market_scores / intelligence history ===\r\n";
      body += "POLICY=" + GM_INTEL_ANALYSIS_ONLY + "\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      m_files.WriteText(m_hist_file, body);
     }

public:
                     CGmIntelligenceDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_hist_file(""),
                         m_n(0), m_last_persist_ms(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_INTEL_DB_PREFIX, magic, sym);
      m_hist_file = m_pfx + "market_scores.txt";
      m_n = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Intelligence Database Ready | prefix=" + m_pfx, "AIIntel");
      return true;
     }

   void Shutdown(void)
     {
      PersistHist();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }

   void Record(const SGmIntelligenceResult &r)
     {
      if(!m_ready || !r.valid)
         return;

      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s | SessionID=%I64u | Symbol=%s | Confidence=%.0f | Advisory=%s\r\n",
                                       ts, r.session_id, r.symbol, r.ai_confidence, r.advisory_status);

      WriteTable("market_intelligence_reports",
                 "=== market_intelligence_reports ===\r\n" + head +
                 StringFormat("Condition=%s | Trend=%s | Vol=%s | Liq=%s | ATR=%.0f | Advisory=%s\r\n",
                              GmMktConditionName(r.market_condition),
                              r.trend_strength_label, r.volatility_label, r.liquidity_label,
                              r.atr_condition, r.market_advisory));

      WriteTable("historical_patterns",
                 "=== historical_patterns ===\r\n" + head +
                 StringFormat("Similarity=%.0f | Date=%s | Outcome=%s | %s\r\n",
                              r.historical_similarity, r.similar_pattern_date,
                              r.historical_outcome, r.pattern_insight));

      WriteTable("strategy_performance_reports",
                 "=== strategy_performance_reports ===\r\n" + head +
                 r.performance_report + "\r\n" +
                 StringFormat("Score=%.0f\r\n", r.strategy_performance_score));

      WriteTable("risk_advisory_reports",
                 "=== risk_advisory_reports ===\r\n" + head +
                 r.risk_explanation + "\r\n" +
                 "MayModifyRisk=false\r\n");

      WriteTable("ai_explanations",
                 "=== ai_explanations ===\r\n" + head +
                 r.explanation + "\r\n");

      WriteTable("market_scores",
                 "=== market_scores ===\r\n" + head +
                 StringFormat("Score=%.0f/100 | Grade=%s | %s\r\n",
                              r.market_score, GmIntelGradeName(r.market_grade),
                              r.market_score_condition));

      const string line = StringFormat(
                             "%s | SID=%I64u | mkt=%.0f/%s | strat=%.0f | hist=%.0f | risk=%s | conf=%.0f | %s",
                             ts, r.session_id, r.market_score, GmIntelGradeName(r.market_grade),
                             r.strategy_performance_score, r.historical_similarity,
                             GmRiskAdvName(r.risk_advisory), r.ai_confidence,
                             GM_INTEL_ANALYSIS_ONLY);
      if(m_n < GM_INTEL_HIST_MAX)
         m_rows[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_INTEL_HIST_MAX; i++)
            m_rows[i - 1] = m_rows[i];
         m_rows[GM_INTEL_HIST_MAX - 1] = line;
        }

      const ulong now = GetTickCount();
      if(m_last_persist_ms == 0 || (now - m_last_persist_ms) > 7000)
        {
         PersistHist();
         m_last_persist_ms = now;
         if(m_logger != NULL)
            m_logger.Info("Database Sync Completed | Intelligence tables", "AIIntel");
        }
     }
  };

#endif // GM_CINTELLIGENCE_DATABASE_MQH
//+------------------------------------------------------------------+
