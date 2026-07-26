//+------------------------------------------------------------------+
//|                               SGmNotificationCenterResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_NOTIFICATION_CENTER_RESULT_MQH
#define GM_SGM_NOTIFICATION_CENTER_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "NotificationCenterConstants.mqh"

struct SGmNotificationCenterResult
  {
   datetime              stamped_at;
   ENUM_GM_ENC_RULE_MODE rule_mode;

   int                   unread_count;
   int                   critical_count;
   int                   queue_depth;
   int                   delivered_count;
   int                   failed_count;
   int                   history_count;

   string                latest_alert;
   string                critical_alerts;
   string                system_notifications;
   string                trading_notifications;
   string                cloud_notifications;
   string                ai_notifications;
   string                recovery_notifications;
   string                delivery_status;
   string                api_connection_status;
   string                notification_feed;
   string                mobile_api_catalog;
   string                rule_summary;

   string                center_status;
   string                insight;
   bool                  may_execute;
   bool                  may_modify_risk;
   bool                  valid;

   void Reset(void)
     {
      stamped_at = 0;
      rule_mode = GM_ENC_RULE_CUSTOM_ALL;
      unread_count = critical_count = queue_depth = 0;
      delivered_count = failed_count = history_count = 0;
      latest_alert = critical_alerts = system_notifications = "";
      trading_notifications = cloud_notifications = ai_notifications = "";
      recovery_notifications = "";
      delivery_status = "Idle";
      api_connection_status = "Architecture Only";
      notification_feed = "";
      mobile_api_catalog = "";
      rule_summary = "";
      center_status = "Idle";
      insight = "";
      may_execute = false;
      may_modify_risk = false;
      valid = false;
     }
  };

#endif // GM_SGM_NOTIFICATION_CENTER_RESULT_MQH
//+------------------------------------------------------------------+
