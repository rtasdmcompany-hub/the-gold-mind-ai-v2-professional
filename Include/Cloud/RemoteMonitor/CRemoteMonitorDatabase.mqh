//+------------------------------------------------------------------+
//|                                   CRemoteMonitorDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CREMOTE_MONITOR_DATABASE_MQH
#define GM_CREMOTE_MONITOR_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmRemoteMonitorResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmRemoteMonitorDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_rows[GM_RM_HIST_MAX];
   int             m_n;
   ulong           m_last_persist_ms;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL) return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmRemoteMonitorDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_n(0),
                         m_last_persist_ms(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_RM_DB_PREFIX, magic, sym);
      m_n = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Remote Monitor Database Ready | " + m_pfx, "RM");
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
      string body = "=== remote_monitor_history ===\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      m_files.WriteText(m_pfx + "monitor_history.txt", body);
     }

   void Record(const SGmRemoteMonitorResult &r, const string events_body)
     {
      if(!m_ready || !r.valid) return;
      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s\r\n", ts);

      WriteTable("health_reports",
                 "=== health_reports ===\r\n" + head +
                 StringFormat("Overall=%.1f CPU=%.1f RAM=%.1f Stab=%.1f DB=%.1f AI=%.1f\r\n",
                              r.overall_health_score, r.cpu_usage_pct, r.ram_usage_pct,
                              r.system_stability, r.database_health, r.ai_processing_score));
      WriteTable("telemetry_history",
                 "=== telemetry_history ===\r\n" + head +
                 StringFormat("Status=%s Samples=%d Hash=%s\r\n",
                              r.telemetry_status, r.telemetry_samples, r.encrypted_telemetry_hash));
      WriteTable("system_events", events_body);
      WriteTable("performance_logs",
                 "=== performance_logs ===\r\n" + head +
                 StringFormat("Tick=%.0f Order=%.0f Chart=%.0f Term=%.0f Net=%.0f Lat=%.0f\r\n",
                              r.tick_processing_score, r.order_processing_score,
                              r.chart_refresh_score, r.terminal_performance,
                              r.network_quality, r.cloud_latency_ms));
      WriteTable("heartbeat_history",
                 "=== heartbeat_history ===\r\n" + head + r.heartbeat_status + "\r\n");
      WriteTable("recovery_logs",
                 "=== recovery_logs ===\r\n" + head +
                 StringFormat("Actions=%d | %s\r\n", r.recovery_actions, r.recovery_log));
      WriteTable("connection_history",
                 "=== connection_history ===\r\n" + head +
                 StringFormat("Cloud=%s Conn=%s Sync=%s\r\n",
                              r.cloud_status, r.connection_status, r.sync_status));

      const string line = StringFormat("%s | health=%.0f cpu=%.0f ram=%.0f lat=%.0f evt=%s",
                                       ts, r.overall_health_score, r.cpu_usage_pct,
                                       r.ram_usage_pct, r.cloud_latency_ms, r.latest_event);
      if(m_n < GM_RM_HIST_MAX)
         m_rows[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_RM_HIST_MAX; i++)
            m_rows[i - 1] = m_rows[i];
         m_rows[GM_RM_HIST_MAX - 1] = line;
        }

      const ulong now = GetTickCount();
      if(m_last_persist_ms == 0 || (now - m_last_persist_ms) > 18000)
        {
         Persist();
         m_last_persist_ms = now;
        }
     }
  };

#endif // GM_CREMOTE_MONITOR_DATABASE_MQH
//+------------------------------------------------------------------+
