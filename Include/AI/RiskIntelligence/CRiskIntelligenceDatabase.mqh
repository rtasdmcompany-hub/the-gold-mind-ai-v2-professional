//+------------------------------------------------------------------+
//|                                  CRiskIntelligenceDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CRISK_INTELLIGENCE_DATABASE_MQH
#define GM_CRISK_INTELLIGENCE_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmRiskIntelligenceResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmRiskIntelligenceDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_rows[GM_RISKINT_HIST_MAX];
   int             m_n;
   ulong           m_last_persist_ms;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL) return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmRiskIntelligenceDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_n(0),
                         m_last_persist_ms(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_RISKINT_DB_PREFIX, magic, sym);
      m_n = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Risk Intelligence Database Ready | " + m_pfx, "AIRisk");
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
      string body = "=== risk_trends / indexed history ===\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      m_files.WriteText(m_pfx + "risk_trends.txt", body);
     }

   void Record(const SGmRiskIntelligenceResult &r)
     {
      if(!m_ready || !r.valid) return;

      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s | SessionID=%I64u | Account=%s | Conf=%.0f\r\n",
                                       ts, r.session_id, r.account_id, r.confidence);

      WriteTable("capital_protection_reports",
                 "=== capital_protection_reports ===\r\n" + head + r.capital_report);
      WriteTable("predictive_risk_reports",
                 "=== predictive_risk_reports ===\r\n" + head + r.predictive_report);
      WriteTable("exposure_analysis",
                 "=== exposure_analysis ===\r\n" + head + r.exposure_report);
      WriteTable("drawdown_history",
                 "=== drawdown_history ===\r\n" + head + r.drawdown_report);
      WriteTable("margin_safety_reports",
                 "=== margin_safety_reports ===\r\n" + head + r.margin_report);
      WriteTable("risk_alerts",
                 "=== risk_alerts (ADVISORY ONLY) ===\r\n" + head +
                 StringFormat("Count=%d | %s\r\n%s\r\n", r.alert_count, r.alert_summary,
                              r.risk_explanation));

      const string line = StringFormat("%s | cap=%.0f pred=%.0f exp=%.0f margin=%s dd=%.1f alerts=%d",
                                       ts, r.capital_protection_score, r.risk_probability,
                                       r.exposure_score, GmMarginGradeName(r.margin_grade),
                                       r.current_dd_pct, r.alert_count);
      if(m_n < GM_RISKINT_HIST_MAX)
         m_rows[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_RISKINT_HIST_MAX; i++)
            m_rows[i - 1] = m_rows[i];
         m_rows[GM_RISKINT_HIST_MAX - 1] = line;
        }

      const ulong now = GetTickCount();
      if(m_last_persist_ms == 0 || (now - m_last_persist_ms) > 9000)
        {
         Persist();
         m_last_persist_ms = now;
         if(m_logger != NULL)
            m_logger.Info("Database Synchronization Completed | Risk Intelligence tables", "AIRisk");
        }
     }
  };

#endif // GM_CRISK_INTELLIGENCE_DATABASE_MQH
//+------------------------------------------------------------------+
