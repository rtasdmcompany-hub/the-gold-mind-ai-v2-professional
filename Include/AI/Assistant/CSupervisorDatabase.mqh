//+------------------------------------------------------------------+
//|                                      CSupervisorDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CSUPERVISOR_DATABASE_MQH
#define GM_CSUPERVISOR_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmAssistantResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

/// @brief Persists supervisor reports (FileManager) — read/write analytics only.
class CGmSupervisorDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_file;
   string          m_rows[GM_ASSIST_HIST_MAX];
   int             m_n;
   ulong           m_last_persist_ms;
   bool            m_ready;

   void Persist(void)
     {
      if(!m_ready || m_files == NULL || StringLen(m_file) == 0)
         return;
      string body = "=== AI SUPERVISOR DATABASE ===\r\n";
      body += "POLICY=" + GM_ASSIST_ANALYSIS_ONLY + " | " + GM_ASSIST_ADVISORY + "\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      m_files.WriteText(m_file, body);
     }

public:
                     CGmSupervisorDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_file(""), m_n(0),
                         m_last_persist_ms(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_file = StringFormat("%sHIST_%I64d_%s.txt", GM_ASSIST_DB_PREFIX, magic, sym);
      m_n = 0;
      m_last_persist_ms = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Supervisor Database Ready | " + m_file, "AISup");
      return true;
     }

   void Shutdown(void)
     {
      Persist();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }

   void Record(const SGmAssistantResult &r)
     {
      if(!m_ready || !r.valid)
         return;
      const string line = StringFormat(
                             "%s | SID=%I64u | cap=%.0f | env=%s(%.0f) | health=%.0f | overall=%.0f | warn=%d | %s | %s",
                             TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS),
                             r.session_id,
                             r.capital_protection_score,
                             GmEnvGradeName(r.environment_grade),
                             r.environment_score,
                             r.system_health_score,
                             r.overall_health_score,
                             r.warning_count,
                             r.warning_center,
                             GM_ASSIST_ANALYSIS_ONLY);
      if(m_n < GM_ASSIST_HIST_MAX)
         m_rows[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_ASSIST_HIST_MAX; i++)
            m_rows[i - 1] = m_rows[i];
         m_rows[GM_ASSIST_HIST_MAX - 1] = line;
        }

      // Also write latest report snapshot
      if(m_files != NULL)
        {
         string rpt = StringFormat("%sRPT_%I64u.txt", GM_ASSIST_DB_PREFIX, r.session_id);
         string body = "=== SUPERVISOR REPORT ===\r\n";
         body += StringFormat("Timestamp=%s\r\nSessionID=%I64u\r\nSymbol=%s\r\n",
                              TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS),
                              r.session_id, r.symbol);
         body += StringFormat("CapitalProtection=%.1f\r\nEnvironmentGrade=%s\r\nEnvironmentScore=%.1f\r\n",
                              r.capital_protection_score,
                              GmEnvGradeName(r.environment_grade),
                              r.environment_score);
         body += StringFormat("SystemHealth=%.1f\r\nOverallHealth=%.1f\r\nRiskExposure=%.1f\r\n",
                              r.system_health_score, r.overall_health_score, r.risk_exposure_pct);
         body += StringFormat("Warnings=%d | %s\r\nRecovery=%s\r\n",
                              r.warning_count, r.warning_center, r.recovery_status);
         body += "Advisory=" + r.advisory_status + "\r\n";
         body += "MayExecute=false\r\nMayModifyRisk=false\r\n";
         m_files.WriteText(rpt, body);
        }

      const ulong now = GetTickCount();
      if(m_last_persist_ms == 0 || (now - m_last_persist_ms) > 6000)
        {
         Persist();
         m_last_persist_ms = now;
        }
     }
  };

#endif // GM_CSUPERVISOR_DATABASE_MQH
//+------------------------------------------------------------------+
