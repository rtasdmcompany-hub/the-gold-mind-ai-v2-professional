//+------------------------------------------------------------------+
//|                                      COrderFlowDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CORDER_FLOW_DATABASE_MQH
#define GM_CORDER_FLOW_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmOrderFlowResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmOrderFlowDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_rows[GM_OF_HIST_MAX];
   int             m_n;
   ulong           m_last_persist_ms;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL) return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmOrderFlowDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_n(0),
                         m_last_persist_ms(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_OF_DB_PREFIX, magic, sym);
      m_n = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Order Flow Database Ready | " + m_pfx, "AIOF");
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
      string body = "=== session_statistics_index ===\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      m_files.WriteText(m_pfx + "session_statistics.txt", body);
     }

   void Record(const SGmOrderFlowResult &r)
     {
      if(!m_ready || !r.valid) return;

      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s | SessionID=%I64u | Symbol=%s\r\n",
                                       ts, r.session_id, r.symbol);

      WriteTable("session_analysis", "=== session_analysis ===\r\n" + head + r.session_report);
      WriteTable("order_flow_analysis", "=== order_flow_analysis ===\r\n" + head + r.order_flow_report);
      WriteTable("market_energy", "=== market_energy ===\r\n" + head + r.energy_report);
      WriteTable("temperature_index", "=== temperature_index ===\r\n" + head + r.temperature_report);
      WriteTable("institutional_activity",
                 "=== institutional_activity ===\r\n" + head +
                 StringFormat("InstActIndex=%.0f | OrderFlow=%.0f\r\n",
                              r.institutional_activity_index, r.order_flow_score));
      WriteTable("historical_session_data",
                 "=== historical_session_data ===\r\n" + head +
                 StringFormat("Session=%s HistSuccess=%.0f Personality=%s Best=%s Worst=%s\r\n%s\r\n",
                              GmOfSessionName(r.active_session), r.historical_session_success,
                              GmOfPersonalityName(r.session_personality),
                              (r.best_goldmind_session ? "Y" : "N"),
                              (r.worst_goldmind_session ? "Y" : "N"),
                              r.personality_report));

      const string line = StringFormat("%s | sess=%s of=%.0f energy=%.0f temp=%.0f hist=%.0f",
                                       ts, GmOfSessionName(r.active_session),
                                       r.order_flow_score, r.energy_score,
                                       r.temperature_index, r.historical_session_success);
      if(m_n < GM_OF_HIST_MAX)
         m_rows[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_OF_HIST_MAX; i++)
            m_rows[i - 1] = m_rows[i];
         m_rows[GM_OF_HIST_MAX - 1] = line;
        }

      const ulong now = GetTickCount();
      if(m_last_persist_ms == 0 || (now - m_last_persist_ms) > 9000)
        {
         Persist();
         m_last_persist_ms = now;
         if(m_logger != NULL)
            m_logger.Info("Database Synchronization Completed | Order Flow tables", "AIOF");
        }
     }
  };

#endif // GM_CORDER_FLOW_DATABASE_MQH
//+------------------------------------------------------------------+
