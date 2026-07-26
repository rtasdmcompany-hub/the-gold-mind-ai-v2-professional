//+------------------------------------------------------------------+
//|                                      CReportingDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CREPORTING_DATABASE_MQH
#define GM_CREPORTING_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmReportingResult.mqh"
#include "CAIAuditTrailSystem.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmReportingDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_rows[GM_RPT_HIST_MAX];
   int             m_n;
   ulong           m_last_persist_ms;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL) return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmReportingDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_n(0),
                         m_last_persist_ms(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_RPT_DB_PREFIX, magic, sym);
      m_n = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Reporting Database Ready | " + m_pfx, "AIRpt");
      return true;
     }

   void Shutdown(void)
     {
      PersistHistory();
      m_ready = false;
     }

   void PersistHistory(void)
     {
      if(!m_ready || m_files == NULL) return;
      string body = "=== report_history ===\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      m_files.WriteText(m_pfx + "report_history.txt", body);
     }

   void Record(const SGmReportingResult &r, CGmAIAuditTrailSystem &audit)
     {
      if(!m_ready || !r.valid) return;

      const string head = StringFormat(
                             "ReportID=%s | SessionID=%I64u | Timestamp=%s | Type=%s | Conf=%.0f | Version=%s\r\n",
                             r.report_id, r.session_id,
                             TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS),
                             GmRptTypeName(r.primary_type),
                             r.exec_confidence, GM_RPT_VERSION);

      WriteTable("ai_reports", "=== ai_reports ===\r\n" + head + r.daily_report + "\r\n" +
                 r.weekly_report + "\r\n" + r.monthly_report + "\r\n");
      WriteTable("executive_summaries", "=== executive_summaries ===\r\n" + head + r.executive_brief);
      WriteTable("session_reports", "=== session_reports ===\r\n" + head + r.session_report);
      WriteTable("performance_scorecards",
                 "=== performance_scorecards ===\r\n" + head +
                 StringFormat("Score=%.0f Grade=%s Pred=%.0f Warn=%.0f Pat=%.0f ConfAcc=%.0f Learn=%.0f Quality=%.0f\r\n",
                              r.performance_score, GmRptGradeName(r.performance_grade),
                              r.prediction_accuracy, r.warning_accuracy, r.pattern_accuracy,
                              r.confidence_accuracy, r.learning_improvement, r.report_quality));
      WriteTable("enterprise_analytics",
                 "=== enterprise_analytics ===\r\n" + head + r.enterprise_analytics);
      WriteTable("audit_reports", audit.Export());

      const string line = StringFormat("%s | %s | score=%.0f/%s | %s",
                                       TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS),
                                       r.report_id, r.performance_score,
                                       GmRptGradeName(r.performance_grade),
                                       r.latest_report_headline);
      if(m_n < GM_RPT_HIST_MAX)
         m_rows[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_RPT_HIST_MAX; i++)
            m_rows[i - 1] = m_rows[i];
         m_rows[GM_RPT_HIST_MAX - 1] = line;
        }

      const ulong now = GetTickCount();
      if(m_last_persist_ms == 0 || (now - m_last_persist_ms) > 9000)
        {
         PersistHistory();
         m_last_persist_ms = now;
         if(m_logger != NULL)
            m_logger.Info("Database Sync Completed | Reporting tables", "AIRpt");
        }
     }
  };

#endif // GM_CREPORTING_DATABASE_MQH
//+------------------------------------------------------------------+
