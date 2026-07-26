//+------------------------------------------------------------------+
//|                             CRecoveryIntelligenceDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CRECOVERY_INTELLIGENCE_DATABASE_MQH
#define GM_CRECOVERY_INTELLIGENCE_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmRecoveryIntelligenceResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmRecoveryIntelligenceDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_rows[GM_RI_HIST_MAX];
   int             m_n;
   ulong           m_last_persist_ms;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL) return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmRecoveryIntelligenceDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_n(0),
                         m_last_persist_ms(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_RI_DB_PREFIX, magic, sym);
      m_n = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Recovery Intelligence Database Ready | " + m_pfx, "AIRI");
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
      string body = "=== recovery_statistics_index ===\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      m_files.WriteText(m_pfx + "historical_recovery.txt", body);
     }

   void Record(const SGmRecoveryIntelligenceResult &r)
     {
      if(!m_ready || !r.valid) return;

      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s | SessionID=%I64u | Symbol=%s\r\n",
                                       ts, r.session_id, r.symbol);

      WriteTable("recovery_reports", "=== recovery_reports ===\r\n" + head + r.recovery_report);
      WriteTable("hedge_reports", "=== hedge_reports ===\r\n" + head + r.hedge_report);
      WriteTable("loss_statistics", "=== loss_statistics ===\r\n" + head + r.loss_report);
      WriteTable("recovery_patterns", "=== recovery_patterns ===\r\n" + head + r.pattern_report);
      WriteTable("second_attempt",
                 "=== second_attempt ===\r\n" + head + r.second_attempt_report);

      const string line = StringFormat("%s | score=%.0f health=%.0f success=%.0f hedge=%.0f loss=%.0f pat=%s",
                                       ts, r.recovery_intelligence_score,
                                       r.recovery_health_index, r.recovery_success_rate,
                                       r.hedge_effectiveness, r.loss_control_score,
                                       GmRiPatternName(r.primary_pattern));
      if(m_n < GM_RI_HIST_MAX)
         m_rows[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_RI_HIST_MAX; i++)
            m_rows[i - 1] = m_rows[i];
         m_rows[GM_RI_HIST_MAX - 1] = line;
        }

      const ulong now = GetTickCount();
      if(m_last_persist_ms == 0 || (now - m_last_persist_ms) > 9000)
        {
         Persist();
         m_last_persist_ms = now;
         if(m_logger != NULL)
            m_logger.Info("Database Synchronization Completed | Recovery Intelligence tables", "AIRI");
        }
     }
  };

#endif // GM_CRECOVERY_INTELLIGENCE_DATABASE_MQH
//+------------------------------------------------------------------+
