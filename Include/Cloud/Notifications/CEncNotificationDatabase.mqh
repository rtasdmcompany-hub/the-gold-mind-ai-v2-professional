//+------------------------------------------------------------------+
//|                               CEncNotificationDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CENC_NOTIFICATION_DATABASE_MQH
#define GM_CENC_NOTIFICATION_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "NotificationCenterConstants.mqh"
#include "SGmNotificationCenterResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmEncNotificationDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_hist[GM_ENC_HIST_MAX];
   int             m_n;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL) return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmEncNotificationDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_n(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_ENC_DB_PREFIX, magic, sym);
      m_n = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Notification Database Ready | " + m_pfx, "ENC");
      return true;
     }

   void Shutdown(void)
     {
      Persist();
      m_ready = false;
     }

   int HistoryCount(void) const { return m_n; }

   void AppendHistory(const string line)
     {
      if(!m_ready) return;
      if(m_n < GM_ENC_HIST_MAX)
         m_hist[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_ENC_HIST_MAX; i++)
            m_hist[i - 1] = m_hist[i];
         m_hist[GM_ENC_HIST_MAX - 1] = line;
        }
     }

   void Persist(void)
     {
      if(!m_ready || m_files == NULL) return;
      string body = "=== notification_history ===\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_hist[i] + "\r\n";
      m_files.WriteText(m_pfx + "notification_history.txt", body);
     }

   void Record(const SGmNotificationCenterResult &r,
               const string rules,
               const string devices,
               const string audit)
     {
      if(!m_ready || !r.valid) return;
      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s\r\n", ts);

      WriteTable("notification_history",
                 "=== notification_history ===\r\n" + head +
                 "Latest=" + r.latest_alert + "\r\n" +
                 "Unread=" + IntegerToString(r.unread_count) + "\r\n" +
                 "Feed=" + r.notification_feed + "\r\n");

      WriteTable("alert_history",
                 "=== alert_history ===\r\n" + head +
                 "Critical=" + r.critical_alerts + "\r\n" +
                 "Trading=" + r.trading_notifications + "\r\n" +
                 "Cloud=" + r.cloud_notifications + "\r\n" +
                 "AI=" + r.ai_notifications + "\r\n" +
                 "Recovery=" + r.recovery_notifications + "\r\n" +
                 "System=" + r.system_notifications + "\r\n");

      WriteTable("delivery_reports",
                 "=== delivery_reports ===\r\n" + head +
                 "Status=" + r.delivery_status + "\r\n" +
                 "Delivered=" + IntegerToString(r.delivered_count) + "\r\n" +
                 "Failed=" + IntegerToString(r.failed_count) + "\r\n" +
                 "Queue=" + IntegerToString(r.queue_depth) + "\r\n");

      WriteTable("read_status",
                 "=== read_status ===\r\n" + head +
                 "Unread=" + IntegerToString(r.unread_count) + "\r\n" +
                 "Critical=" + IntegerToString(r.critical_count) + "\r\n");

      WriteTable("notification_rules",
                 "=== notification_rules ===\r\n" + head + rules + "\r\n");

      WriteTable("device_registration",
                 "=== device_registration ===\r\n" + head + devices + "\r\n");

      WriteTable("audit_log",
                 "=== audit_log ===\r\n" + head + audit + "\r\n" +
                 "POLICY=" + GM_ENC_POLICY + "\r\n");

      AppendHistory(StringFormat("%s | %s | unread=%d | delivered=%d",
                                 ts, r.latest_alert, r.unread_count, r.delivered_count));
     }
  };

#endif // GM_CENC_NOTIFICATION_DATABASE_MQH
//+------------------------------------------------------------------+
