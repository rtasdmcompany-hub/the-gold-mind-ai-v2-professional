//+------------------------------------------------------------------+
//|                                          CCloudDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CCLOUD_DATABASE_MQH
#define GM_CCLOUD_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmCloudStatus.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"

class CGmCloudDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_rows[GM_CLOUD_HIST_MAX];
   int             m_n;
   ulong           m_last_persist_ms;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL) return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmCloudDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_n(0),
                         m_last_persist_ms(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_CLOUD_DB_PREFIX, magic, sym);
      m_n = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Cloud Database Ready | " + m_pfx, "CLOUD");
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
      string body = "=== cloud_history_index ===\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      m_files.WriteText(m_pfx + "cloud_history.txt", body);
     }

   void RecordDevice(const string encrypted_device)
     {
      if(!m_ready) return;
      WriteTable("device_information",
                 "=== device_information (encrypted) ===\r\n" + encrypted_device + "\r\n");
     }

   void Record(const SGmCloudStatus &s, const string license_session)
     {
      if(!m_ready || !s.valid) return;
      const string ts = TimeToString(s.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s\r\n", ts);

      WriteTable("cloud_sessions",
                 "=== cloud_sessions ===\r\n" + head +
                 StringFormat("Status=%s Offline=%d Endpoint=%s Token=%s\r\n",
                              GmCloudStatusName(s.cloud_status),
                              (int)s.offline_mode, s.server_endpoint, s.session_token_hash));
      WriteTable("heartbeat_history",
                 "=== heartbeat_history ===\r\n" + head +
                 StringFormat("OK=%d Last=%s Latency=%dms\r\n",
                              (int)s.heartbeat_ok,
                              TimeToString(s.last_heartbeat_at, TIME_DATE | TIME_SECONDS),
                              s.latency_ms));
      WriteTable("synchronization_history",
                 "=== synchronization_history ===\r\n" + head +
                 StringFormat("LastSync=%s Queue=%d\r\n",
                              TimeToString(s.last_sync_at, TIME_DATE | TIME_SECONDS),
                              s.sync_queue_depth));
      WriteTable("license_session",
                 "=== license_session ===\r\n" + head + license_session + "\r\n");
      WriteTable("connection_statistics",
                 "=== connection_statistics ===\r\n" + head +
                 StringFormat("Connection=%s Latency=%d Version=%s\r\n",
                              s.server_connection, s.latency_ms, s.cloud_version));

      const string line = StringFormat("%s | %s lic=%s offline=%d q=%d lat=%d",
                                       ts, GmCloudStatusName(s.cloud_status),
                                       s.license_status, (int)s.offline_mode,
                                       s.sync_queue_depth, s.latency_ms);
      if(m_n < GM_CLOUD_HIST_MAX)
         m_rows[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_CLOUD_HIST_MAX; i++)
            m_rows[i - 1] = m_rows[i];
         m_rows[GM_CLOUD_HIST_MAX - 1] = line;
        }

      const ulong now = GetTickCount();
      if(m_last_persist_ms == 0 || (now - m_last_persist_ms) > 20000)
        {
         Persist();
         m_last_persist_ms = now;
        }
     }
  };

#endif // GM_CCLOUD_DATABASE_MQH
//+------------------------------------------------------------------+
