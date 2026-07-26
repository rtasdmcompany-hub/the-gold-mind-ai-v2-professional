//+------------------------------------------------------------------+
//|                         CEnterpriseNotificationEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 6 Sprint 3 — Notification Center facade               |
//|     COMMUNICATION ONLY — NEVER executes or modifies trades      |
//+------------------------------------------------------------------+
#ifndef GM_CENTERPRISE_NOTIFICATION_ENGINE_MQH
#define GM_CENTERPRISE_NOTIFICATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "NotificationCenterConstants.mqh"
#include "SGmNotificationCenterResult.mqh"
#include "CEncNotificationSecurity.mqh"
#include "CEncNotificationRules.mqh"
#include "CEncMessageQueue.mqh"
#include "CEncAlertManager.mqh"
#include "CEncNotificationEngine.mqh"
#include "CEncMobileCompanionApi.mqh"
#include "CEncNotificationDatabase.mqh"
#include "../CEnterpriseCloudEngine.mqh"
#include "../RemoteMonitor/CEnterpriseRemoteMonitorEngine.mqh"
#include "../CCloudSecurity.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../../AI/SGmAISnapshot.mqh"

class CGmEnterpriseNotificationEngine
  {
private:
   CGmLogger                        *m_logger;
   CGmEnterpriseCloudEngine         *m_cloud;
   CGmEnterpriseRemoteMonitorEngine *m_remote;
   CGmCloudSecurity                  m_sec_core;
   CGmEncNotificationSecurity        m_sec;
   CGmEncNotificationRules           m_rules;
   CGmEncMessageQueue                m_queue;
   CGmEncAlertManager                m_alerts;
   CGmEncNotificationEngine          m_engine;
   CGmEncMobileCompanionApi          m_api;
   CGmEncNotificationDatabase        m_db;
   SGmNotificationCenterResult       m_last;
   string                            m_feed[GM_ENC_FEED_MAX];
   int                               m_feed_n;
   int                               m_unread;
   int                               m_critical;
   string                            m_latest;
   string                            m_sys_line;
   string                            m_trade_line;
   string                            m_cloud_line;
   string                            m_ai_line;
   string                            m_rec_line;
   string                            m_crit_line;
   ulong                             m_last_ms;
   ulong                             m_cycle_us;
   bool                              m_ready;

   void PushFeed(const string line)
     {
      if(m_feed_n < GM_ENC_FEED_MAX)
         m_feed[m_feed_n++] = line;
      else
        {
         for(int i = 1; i < GM_ENC_FEED_MAX; i++)
            m_feed[i - 1] = m_feed[i];
         m_feed[GM_ENC_FEED_MAX - 1] = line;
        }
     }

   string FeedJoined(void) const
     {
      string out = "";
      const int start = MathMax(0, m_feed_n - 5);
      for(int i = start; i < m_feed_n; i++)
        {
         if(StringLen(out) > 0) out += " | ";
         out += m_feed[i];
        }
      return out;
     }

   void ClassifyLine(const ENUM_GM_ENC_CATEGORY cat, const string title)
     {
      m_latest = title;
      m_unread++;
      PushFeed(title);
      if(cat == GM_ENC_CAT_SYSTEM)      m_sys_line = title;
      if(cat == GM_ENC_CAT_TRADING)     m_trade_line = title;
      if(cat == GM_ENC_CAT_CLOUD || cat == GM_ENC_CAT_LICENSE) m_cloud_line = title;
      if(cat == GM_ENC_CAT_AI)          m_ai_line = title;
      if(cat == GM_ENC_CAT_RECOVERY)    m_rec_line = title;
     }

public:
                     CGmEnterpriseNotificationEngine(void)
                       : m_logger(NULL), m_cloud(NULL), m_remote(NULL),
                         m_feed_n(0), m_unread(0), m_critical(0),
                         m_latest(""), m_sys_line(""), m_trade_line(""),
                         m_cloud_line(""), m_ai_line(""), m_rec_line(""),
                         m_crit_line(""), m_last_ms(0), m_cycle_us(0), m_ready(false)
     {
      m_last.Reset();
     }

   bool Init(CGmLogger *logger,
             CGmFileManager *files,
             const long magic,
             const string symbol)
     {
      m_logger = logger;
      m_db.Init(logger, files, magic, symbol);
      const string seed = StringFormat("ENC|%I64d|%s|%s", magic, symbol, GM_ENC_VERSION);
      m_sec_core.Init(seed);
      m_sec.Init(GetPointer(m_sec_core));
      m_rules.Init(GM_ENC_RULE_CUSTOM_ALL);
      m_queue.Init(GetPointer(m_sec));
      m_alerts.Init(GetPointer(m_queue), GetPointer(m_rules));
      m_engine.Init(GetPointer(m_queue));
      m_api.Init(GetPointer(m_sec), seed);
      m_last.Reset();
      m_ready = true;
      m_alerts.ObserveStartup();
      if(m_logger != NULL)
        {
         m_logger.Success("Notification Engine Started | " + GM_ENC_VERSION, "ENC");
         m_logger.Info("POLICY | " + GM_ENC_POLICY, "ENC");
         m_logger.Info("SAFE | " + GM_ENC_SAFE, "ENC");
         m_logger.Info("Notification Created | EA Started", "ENC");
        }
      return true;
     }

   void BindCloud(CGmEnterpriseCloudEngine *cloud)
     {
      m_cloud = cloud;
      if(m_logger != NULL && cloud != NULL)
         m_logger.Info("Notification Center bound to Cloud (observe only)", "ENC");
     }

   void BindRemote(CGmEnterpriseRemoteMonitorEngine *remote)
     {
      m_remote = remote;
      if(m_logger != NULL && remote != NULL)
         m_logger.Info("Notification Center bound to Remote Monitor (observe only)", "ENC");
     }

   void SetRuleMode(const ENUM_GM_ENC_RULE_MODE mode)
     {
      m_rules.SetMode(mode);
     }

   /// Observe-only lifecycle hints from Application (never trade)
   void Hint(const ENUM_GM_ENC_ALERT alert, const string detail = "")
     {
      if(!m_ready) return;
      if(m_alerts.Emit(alert, detail))
        {
         ClassifyLine(GM_ENC_CAT_SYSTEM, GmEncAlertName(alert));
         if(m_logger != NULL)
            m_logger.Info("Notification Created | " + GmEncAlertName(alert), "ENC");
        }
     }

   void Shutdown(void)
     {
      if(m_ready)
         m_alerts.ObserveShutdown();
      m_engine.DrainOne(false);
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmNotificationCenterResult Last(void) const { return m_last; }

   bool Process(const bool force = false)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(!force && m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_ENC_THROTTLE_MS)
         return true;

      const ulong t0 = GetMicrosecondCount();
      m_last_ms = now;

      SGmCloudStatus cloud_st;
      cloud_st.Reset();
      if(m_cloud != NULL && m_cloud.IsReady())
         cloud_st = m_cloud.Last();

      SGmRemoteMonitorResult rm_st;
      rm_st.Reset();
      if(m_remote != NULL && m_remote.IsReady())
         rm_st = m_remote.Last();

      const int q_before = m_queue.Depth();
      m_alerts.ObserveCloud(cloud_st);
      m_alerts.ObserveRemote(rm_st);

      if(m_queue.Depth() > q_before)
        {
         const string peek = m_queue.PeekLatestTitle();
         if(StringLen(peek) > 0)
           {
            m_latest = peek;
            PushFeed(peek);
            m_unread++;
           }
         if(m_logger != NULL)
            m_logger.Info("Notification Created | " + m_latest, "ENC");
        }

      const bool online = (cloud_st.valid && cloud_st.cloud_status == GM_CLOUD_STATUS_ONLINE);
      if(m_engine.DrainOne(online))
        {
         if(m_logger != NULL)
           {
            m_logger.Info("Queue Processed | depth=" + IntegerToString(m_queue.Depth()), "ENC");
            m_logger.Info("Notification Sent | " + m_engine.ChannelSummary(), "ENC");
            if(m_queue.Delivered() > 0)
               m_logger.Info("Notification Delivered | count=" + IntegerToString(m_queue.Delivered()), "ENC");
            if(m_queue.Failed() > 0)
               m_logger.Warning("Notification Failed | count=" + IntegerToString(m_queue.Failed()), "ENC");
           }
        }

      if(rm_st.valid && rm_st.overall_health_score < 25.0)
        {
         m_critical++;
         m_crit_line = "Critical health";
        }

      SGmNotificationCenterResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.rule_mode = m_rules.Mode();
      r.unread_count = m_unread;
      r.critical_count = m_critical;
      r.queue_depth = m_queue.Depth();
      r.delivered_count = m_queue.Delivered();
      r.failed_count = m_queue.Failed();
      r.history_count = m_db.HistoryCount();
      r.latest_alert = (StringLen(m_latest) > 0) ? m_latest : "None";
      r.critical_alerts = (StringLen(m_crit_line) > 0) ? m_crit_line : "None";
      r.system_notifications = (StringLen(m_sys_line) > 0) ? m_sys_line : "EA Started";
      r.trading_notifications = (StringLen(m_trade_line) > 0) ? m_trade_line : "Observe";
      r.cloud_notifications = (StringLen(m_cloud_line) > 0) ? m_cloud_line
                              : (cloud_st.valid ? GmCloudStatusName(cloud_st.cloud_status) : "n/a");
      r.ai_notifications = (StringLen(m_ai_line) > 0) ? m_ai_line : "Advisory observe";
      r.recovery_notifications = (StringLen(m_rec_line) > 0) ? m_rec_line : "None";
      r.delivery_status = StringFormat("OK D=%d F=%d Q=%d | %s",
                                       r.delivered_count, r.failed_count, r.queue_depth,
                                       m_engine.ChannelSummary());
      r.api_connection_status = m_api.ConnectionStatus();
      r.notification_feed = FeedJoined();
      r.mobile_api_catalog = m_api.Catalog();
      r.rule_summary = m_rules.Summary();
      r.center_status = "NOTIFICATION CENTER READY";
      r.insight = StringFormat("%s | unread=%d | %s | %s",
                               r.center_status, r.unread_count, GM_ENC_POLICY, GM_ENC_SAFE);
      r.may_execute = false;
      r.may_modify_risk = false;
      r.valid = true;

      const string api_resp = m_api.HandleReadOnly("/v1/notifications/feed", r, cloud_st, rm_st);
      if(m_logger != NULL)
         m_logger.Debug("API Request Completed | /v1/notifications/feed", "ENC");

      const string device_id = (cloud_st.valid && StringLen(cloud_st.device_id_hash) > 0)
                               ? cloud_st.device_id_hash : "local";
      const string devices = "device=" + device_id + " | token=hashed";
      const string audit = "signed_api_len=" + IntegerToString(StringLen(api_resp)) +
                           " | may_execute=false | may_modify_risk=false";
      m_db.Record(r, r.rule_summary, devices, audit);
      m_last = r;
      m_cycle_us = GetMicrosecondCount() - t0;

      if(m_logger != NULL)
        {
         m_logger.Info("Dashboard Updated | " + r.center_status, "ENC");
         m_logger.Debug(StringFormat("Performance Statistics | cycle=%I64u us (<1%% target)", m_cycle_us), "ENC");
        }
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = m_last.center_status;
      s.ai_engine = "GoldMind Enterprise Notification Center";
      s.current_mode = "CLOUD_NOTIFICATION_CENTER";
      s.confidence_pct = (double)MathMin(100, m_last.delivered_count);
      s.confidence_status = IntegerToString(m_last.unread_count);

      // Phase 6 Sprint 3 widgets
      s.w_trend_detector = m_last.latest_alert;                          // Latest Alerts
      s.future_ai_score = IntegerToString(m_last.unread_count);          // Unread Count
      s.w_recovery_ai = m_last.critical_alerts;                          // Critical Alerts
      s.prediction_status = m_last.trading_notifications;                // Trading
      s.learning_status = m_last.recovery_notifications;                 // Recovery
      s.w_volatility_scanner = m_last.cloud_notifications;               // Cloud
      s.w_market_analyzer = m_last.system_notifications;                 // System
      s.w_news_analyzer = m_last.ai_notifications;                       // AI
      s.w_trade_confidence = m_last.delivery_status;                     // Delivery Status
      s.ai_version = m_last.api_connection_status;                       // API Connection
      s.decision_status = GM_ENC_POLICY;
      s.valid = true;
     }
  };

#endif // GM_CENTERPRISE_NOTIFICATION_ENGINE_MQH
//+------------------------------------------------------------------+
