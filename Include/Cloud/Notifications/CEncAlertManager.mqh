//+------------------------------------------------------------------+
//|                                        CEncAlertManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Intelligent alert generation — REPORT ONLY                  |
//+------------------------------------------------------------------+
#ifndef GM_CENC_ALERT_MANAGER_MQH
#define GM_CENC_ALERT_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "NotificationCenterConstants.mqh"
#include "CEncMessageQueue.mqh"
#include "CEncNotificationRules.mqh"
#include "../SGmCloudStatus.mqh"
#include "../RemoteMonitor/SGmRemoteMonitorResult.mqh"

class CGmEncAlertManager
  {
private:
   CGmEncMessageQueue       *m_queue;
   CGmEncNotificationRules  *m_rules;
   ENUM_GM_CLOUD_STATUS      m_prev_cloud;
   bool                      m_prev_cloud_valid;
   double                    m_prev_health;
   bool                      m_started_emitted;
   bool                      m_ready;

   ENUM_GM_ENC_PRIORITY PriorityFor(const ENUM_GM_ENC_ALERT a) const
     {
      switch(a)
        {
         case GM_ENC_ALERT_CRITICAL_ERROR:
         case GM_ENC_ALERT_DAILY_LOSS:
         case GM_ENC_ALERT_CLOUD_DISCONNECTED:
            return GM_ENC_PRI_CRITICAL;
         case GM_ENC_ALERT_SYSTEM_WARNING:
         case GM_ENC_ALERT_HIGH_SPREAD:
         case GM_ENC_ALERT_HIGH_VOL:
         case GM_ENC_ALERT_RECOVERY_STARTED:
            return GM_ENC_PRI_HIGH;
         case GM_ENC_ALERT_EA_STOPPED:
            return GM_ENC_PRI_HIGH;
         default:
            return GM_ENC_PRI_NORMAL;
        }
     }

   ENUM_GM_ENC_CATEGORY CategoryFor(const ENUM_GM_ENC_ALERT a) const
     {
      switch(a)
        {
         case GM_ENC_ALERT_CLOUD_CONNECTED:
         case GM_ENC_ALERT_CLOUD_DISCONNECTED:
            return GM_ENC_CAT_CLOUD;
         case GM_ENC_ALERT_LICENSE_UPDATED:
            return GM_ENC_CAT_LICENSE;
         case GM_ENC_ALERT_RECOVERY_STARTED:
         case GM_ENC_ALERT_RECOVERY_COMPLETED:
            return GM_ENC_CAT_RECOVERY;
         case GM_ENC_ALERT_NEW_H4:
         case GM_ENC_ALERT_BUY_LEVELS:
         case GM_ENC_ALERT_SELL_LEVELS:
         case GM_ENC_ALERT_PENDING_TRIGGERED:
         case GM_ENC_ALERT_TRADE_OPENED:
         case GM_ENC_ALERT_BREAK_EVEN:
         case GM_ENC_ALERT_PARTIAL_80:
         case GM_ENC_ALERT_TRAIL_20:
         case GM_ENC_ALERT_TRADE_CLOSED:
         case GM_ENC_ALERT_DAILY_TARGET:
         case GM_ENC_ALERT_DAILY_LOSS:
         case GM_ENC_ALERT_HIGH_SPREAD:
            return GM_ENC_CAT_TRADING;
         case GM_ENC_ALERT_HIGH_VOL:
            return GM_ENC_CAT_PERFORMANCE;
         case GM_ENC_ALERT_EA_STARTED:
         case GM_ENC_ALERT_EA_STOPPED:
         case GM_ENC_ALERT_SYSTEM_WARNING:
         case GM_ENC_ALERT_CRITICAL_ERROR:
            return GM_ENC_CAT_SYSTEM;
         default:
            return GM_ENC_CAT_SYSTEM;
        }
     }

   ENUM_GM_ENC_CHANNEL ChannelFor(const ENUM_GM_ENC_PRIORITY pri) const
     {
      if(pri == GM_ENC_PRI_CRITICAL) return GM_ENC_CH_DESKTOP;
      if(pri == GM_ENC_PRI_SILENT)   return GM_ENC_CH_SILENT;
      return GM_ENC_CH_CLOUD;
     }

public:
                     CGmEncAlertManager(void)
                       : m_queue(NULL), m_rules(NULL),
                         m_prev_cloud(GM_CLOUD_STATUS_IDLE),
                         m_prev_cloud_valid(false),
                         m_prev_health(100.0),
                         m_started_emitted(false),
                         m_ready(false) {}

   bool Init(CGmEncMessageQueue *queue, CGmEncNotificationRules *rules)
     {
      m_queue = queue;
      m_rules = rules;
      m_ready = (m_queue != NULL && m_rules != NULL);
      return m_ready;
     }

   bool Emit(const ENUM_GM_ENC_ALERT alert, const string detail = "")
     {
      if(!m_ready || alert == GM_ENC_ALERT_NONE)
         return false;

      const ENUM_GM_ENC_PRIORITY pri = PriorityFor(alert);
      const ENUM_GM_ENC_CATEGORY cat = CategoryFor(alert);
      if(!m_rules.Allows(cat, pri))
         return false;

      const string title = GmEncAlertName(alert);
      const string body = (StringLen(detail) > 0) ? detail : title;
      return m_queue.Enqueue(alert, title, body, ChannelFor(pri), pri, cat);
     }

   void ObserveStartup(void)
     {
      if(!m_started_emitted)
        {
         Emit(GM_ENC_ALERT_EA_STARTED, "Enterprise Notification Center online");
         m_started_emitted = true;
        }
     }

   void ObserveShutdown(void)
     {
      Emit(GM_ENC_ALERT_EA_STOPPED, "Notification Center shutting down");
     }

   void ObserveCloud(const SGmCloudStatus &cloud)
     {
      if(!m_ready || !cloud.valid)
         return;

      if(m_prev_cloud_valid)
        {
         const bool was_up = (m_prev_cloud == GM_CLOUD_STATUS_ONLINE);
         const bool now_up = (cloud.cloud_status == GM_CLOUD_STATUS_ONLINE);
         if(!was_up && now_up)
            Emit(GM_ENC_ALERT_CLOUD_CONNECTED, cloud.server_connection);
         if(was_up && !now_up)
            Emit(GM_ENC_ALERT_CLOUD_DISCONNECTED, cloud.server_connection);
        }
      m_prev_cloud = cloud.cloud_status;
      m_prev_cloud_valid = true;
     }

   void ObserveRemote(const SGmRemoteMonitorResult &rm)
     {
      if(!m_ready || !rm.valid)
         return;

      if(m_prev_health >= 45.0 && rm.overall_health_score < 45.0)
         Emit(GM_ENC_ALERT_SYSTEM_WARNING,
              StringFormat("Health degraded to %.0f", rm.overall_health_score));
      if(rm.overall_health_score < 25.0)
         Emit(GM_ENC_ALERT_CRITICAL_ERROR,
              StringFormat("Critical health %.0f", rm.overall_health_score));
      m_prev_health = rm.overall_health_score;
     }

   // Lifecycle hints from Application (observe only — never trade)
   void ObserveLifecycleHint(const ENUM_GM_ENC_ALERT alert, const string detail)
     {
      Emit(alert, detail);
     }
  };

#endif // GM_CENC_ALERT_MANAGER_MQH
//+------------------------------------------------------------------+
