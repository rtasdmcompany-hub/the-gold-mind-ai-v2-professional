//+------------------------------------------------------------------+
//|                              CEifInfrastructureDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEIF_INFRASTRUCTURE_DATABASE_MQH
#define GM_CEIF_INFRASTRUCTURE_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "InfrastructureConstants.mqh"
#include "SGmInfrastructureResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmEifInfrastructureDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_hist[GM_EIF_HIST_MAX];
   int             m_n;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL) return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmEifInfrastructureDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_n(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_EIF_DB_PREFIX, magic, sym);
      m_n = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Infrastructure Database Ready | " + m_pfx, "EIF");
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
      string body = "=== status_history ===\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_hist[i] + "\r\n";
      m_files.WriteText(m_pfx + "status_history.txt", body);
     }

   void Record(const SGmInfrastructureResult &r,
               const string device_registry,
               const string audit)
     {
      if(!m_ready || !r.valid) return;
      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s\r\n", ts);

      WriteTable("device_registry",
                 "=== device_registry ===\r\n" + head + device_registry + "\r\n");

      WriteTable("vps_registry",
                 "=== vps_registry ===\r\n" + head +
                 "OnlineVPS=" + IntegerToString(r.online_vps) + "\r\n" +
                 "OfflineVPS=" + IntegerToString(r.offline_vps) + "\r\n" +
                 "CPU=" + DoubleToString(r.vps_cpu_pct, 1) + "\r\n" +
                 "RAM=" + DoubleToString(r.vps_ram_pct, 1) + "\r\n" +
                 "Disk=" + DoubleToString(r.vps_disk_pct, 1) + "\r\n" +
                 "Status=" + r.vps_online_status + "\r\n");

      WriteTable("heartbeat_history",
                 "=== heartbeat_history ===\r\n" + head +
                 "Heartbeat=" + r.heartbeat_status + "\r\n");

      WriteTable("performance_history",
                 "=== performance_history ===\r\n" + head +
                 "AvgCPU=" + DoubleToString(r.avg_cpu_pct, 1) + "\r\n" +
                 "AvgRAM=" + DoubleToString(r.avg_ram_pct, 1) + "\r\n" +
                 "AvgLatency=" + DoubleToString(r.avg_latency_ms, 1) + "\r\n" +
                 "InfraHealth=" + DoubleToString(r.infra_health, 1) + "\r\n");

      WriteTable("connection_logs",
                 "=== connection_logs ===\r\n" + head +
                 "Cloud=" + r.cloud_connection + "\r\n" +
                 "Connected=" + IntegerToString(r.connected_devices) + "\r\n" +
                 "Online=" + IntegerToString(r.online_devices) + "\r\n" +
                 "Offline=" + IntegerToString(r.offline_devices) + "\r\n");

      WriteTable("synchronization_logs",
                 "=== synchronization_logs ===\r\n" + head +
                 "Sync=" + r.synchronization_status + "\r\n" +
                 "SyncQ=" + IntegerToString(r.sync_queue_depth) + "\r\n" +
                 "NtfQ=" + IntegerToString(r.notification_queue_depth) + "\r\n");

      WriteTable("audit_trail",
                 "=== audit_trail ===\r\n" + head + audit + "\r\n" +
                 "POLICY=" + GM_EIF_POLICY + "\r\n");

      const string line = StringFormat("%s | score=%.0f | online=%d offline=%d | %s",
                                       ts, r.enterprise_score,
                                       r.online_devices, r.offline_devices,
                                       r.enterprise_status);
      if(m_n < GM_EIF_HIST_MAX)
         m_hist[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_EIF_HIST_MAX; i++)
            m_hist[i - 1] = m_hist[i];
         m_hist[GM_EIF_HIST_MAX - 1] = line;
        }
     }
  };

#endif // GM_CEIF_INFRASTRUCTURE_DATABASE_MQH
//+------------------------------------------------------------------+
