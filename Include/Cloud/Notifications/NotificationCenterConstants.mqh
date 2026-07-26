//+------------------------------------------------------------------+
//|                                NotificationCenterConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 6 Sprint 3 — Enterprise Notification / Alerts / API   |
//|     COMMUNICATION ONLY — NEVER executes or modifies trades      |
//+------------------------------------------------------------------+
#ifndef GM_NOTIFICATION_CENTER_CONSTANTS_MQH
#define GM_NOTIFICATION_CENTER_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_ENC_VERSION              "1.0.0-notification-center"
#define GM_ENC_DB_PREFIX            "GM_CLOUD_ENC_"
#define GM_ENC_THROTTLE_MS          10000
#define GM_ENC_QUEUE_MAX            64
#define GM_ENC_HIST_MAX             64
#define GM_ENC_FEED_MAX             24
#define GM_ENC_POLICY               "NOTIFICATION SERVICE ONLY — NO TRADING AUTHORITY"
#define GM_ENC_SAFE                 "ASYNC NOTIFY — TRADING NEVER INTERRUPTED"

enum ENUM_GM_ENC_CHANNEL
  {
   GM_ENC_CH_DESKTOP = 0,
   GM_ENC_CH_MOBILE,
   GM_ENC_CH_EMAIL,
   GM_ENC_CH_PUSH,
   GM_ENC_CH_CLOUD,
   GM_ENC_CH_WEBHOOK,
   GM_ENC_CH_API,
   GM_ENC_CH_SILENT
  };

enum ENUM_GM_ENC_PRIORITY
  {
   GM_ENC_PRI_SILENT = 0,
   GM_ENC_PRI_NORMAL,
   GM_ENC_PRI_HIGH,
   GM_ENC_PRI_CRITICAL
  };

enum ENUM_GM_ENC_CATEGORY
  {
   GM_ENC_CAT_SYSTEM = 0,
   GM_ENC_CAT_TRADING,
   GM_ENC_CAT_AI,
   GM_ENC_CAT_CLOUD,
   GM_ENC_CAT_PERFORMANCE,
   GM_ENC_CAT_SECURITY,
   GM_ENC_CAT_RECOVERY,
   GM_ENC_CAT_LICENSE
  };

enum ENUM_GM_ENC_RULE_MODE
  {
   GM_ENC_RULE_CRITICAL_ONLY = 0,
   GM_ENC_RULE_TRADING_ONLY,
   GM_ENC_RULE_AI_ONLY,
   GM_ENC_RULE_CLOUD_ONLY,
   GM_ENC_RULE_SYSTEM_ONLY,
   GM_ENC_RULE_PERFORMANCE_ONLY,
   GM_ENC_RULE_SECURITY_ONLY,
   GM_ENC_RULE_CUSTOM_ALL
  };

enum ENUM_GM_ENC_ALERT
  {
   GM_ENC_ALERT_NONE = 0,
   GM_ENC_ALERT_EA_STARTED,
   GM_ENC_ALERT_EA_STOPPED,
   GM_ENC_ALERT_NEW_H4,
   GM_ENC_ALERT_BUY_LEVELS,
   GM_ENC_ALERT_SELL_LEVELS,
   GM_ENC_ALERT_PENDING_TRIGGERED,
   GM_ENC_ALERT_TRADE_OPENED,
   GM_ENC_ALERT_BREAK_EVEN,
   GM_ENC_ALERT_PARTIAL_80,
   GM_ENC_ALERT_TRAIL_20,
   GM_ENC_ALERT_RECOVERY_STARTED,
   GM_ENC_ALERT_RECOVERY_COMPLETED,
   GM_ENC_ALERT_TRADE_CLOSED,
   GM_ENC_ALERT_DAILY_TARGET,
   GM_ENC_ALERT_DAILY_LOSS,
   GM_ENC_ALERT_HIGH_SPREAD,
   GM_ENC_ALERT_HIGH_VOL,
   GM_ENC_ALERT_CLOUD_CONNECTED,
   GM_ENC_ALERT_CLOUD_DISCONNECTED,
   GM_ENC_ALERT_LICENSE_UPDATED,
   GM_ENC_ALERT_SYSTEM_WARNING,
   GM_ENC_ALERT_CRITICAL_ERROR
  };

string GmEncChannelName(const ENUM_GM_ENC_CHANNEL c)
  {
   switch(c)
     {
      case GM_ENC_CH_DESKTOP: return "Desktop";
      case GM_ENC_CH_MOBILE:  return "Mobile";
      case GM_ENC_CH_EMAIL:   return "Email";
      case GM_ENC_CH_PUSH:    return "Push";
      case GM_ENC_CH_CLOUD:   return "Cloud";
      case GM_ENC_CH_WEBHOOK: return "Webhook";
      case GM_ENC_CH_API:     return "API";
      case GM_ENC_CH_SILENT:  return "Silent";
     }
   return "Unknown";
  }

string GmEncPriorityName(const ENUM_GM_ENC_PRIORITY p)
  {
   switch(p)
     {
      case GM_ENC_PRI_SILENT:   return "Silent";
      case GM_ENC_PRI_NORMAL:   return "Normal";
      case GM_ENC_PRI_HIGH:     return "High";
      case GM_ENC_PRI_CRITICAL: return "Critical";
     }
   return "Normal";
  }

string GmEncCategoryName(const ENUM_GM_ENC_CATEGORY c)
  {
   switch(c)
     {
      case GM_ENC_CAT_SYSTEM:      return "System";
      case GM_ENC_CAT_TRADING:     return "Trading";
      case GM_ENC_CAT_AI:          return "AI";
      case GM_ENC_CAT_CLOUD:       return "Cloud";
      case GM_ENC_CAT_PERFORMANCE: return "Performance";
      case GM_ENC_CAT_SECURITY:    return "Security";
      case GM_ENC_CAT_RECOVERY:    return "Recovery";
      case GM_ENC_CAT_LICENSE:     return "License";
     }
   return "System";
  }

string GmEncRuleModeName(const ENUM_GM_ENC_RULE_MODE m)
  {
   switch(m)
     {
      case GM_ENC_RULE_CRITICAL_ONLY:     return "Critical Only";
      case GM_ENC_RULE_TRADING_ONLY:      return "Trading Only";
      case GM_ENC_RULE_AI_ONLY:           return "AI Only";
      case GM_ENC_RULE_CLOUD_ONLY:        return "Cloud Only";
      case GM_ENC_RULE_SYSTEM_ONLY:       return "System Only";
      case GM_ENC_RULE_PERFORMANCE_ONLY:  return "Performance Only";
      case GM_ENC_RULE_SECURITY_ONLY:     return "Security Only";
      case GM_ENC_RULE_CUSTOM_ALL:        return "Custom / All";
     }
   return "Custom / All";
  }

string GmEncAlertName(const ENUM_GM_ENC_ALERT a)
  {
   switch(a)
     {
      case GM_ENC_ALERT_EA_STARTED:          return "EA Started";
      case GM_ENC_ALERT_EA_STOPPED:          return "EA Stopped";
      case GM_ENC_ALERT_NEW_H4:              return "New H4 Cycle";
      case GM_ENC_ALERT_BUY_LEVELS:          return "New Buy Levels Created";
      case GM_ENC_ALERT_SELL_LEVELS:         return "New Sell Levels Created";
      case GM_ENC_ALERT_PENDING_TRIGGERED:   return "Pending Order Triggered";
      case GM_ENC_ALERT_TRADE_OPENED:        return "Trade Opened";
      case GM_ENC_ALERT_BREAK_EVEN:          return "Break Even Activated";
      case GM_ENC_ALERT_PARTIAL_80:          return "80% Partial Close";
      case GM_ENC_ALERT_TRAIL_20:            return "20% Trailing Started";
      case GM_ENC_ALERT_RECOVERY_STARTED:    return "Recovery Started";
      case GM_ENC_ALERT_RECOVERY_COMPLETED:  return "Recovery Completed";
      case GM_ENC_ALERT_TRADE_CLOSED:        return "Trade Closed";
      case GM_ENC_ALERT_DAILY_TARGET:        return "Daily Target Reached";
      case GM_ENC_ALERT_DAILY_LOSS:          return "Daily Loss Limit Reached";
      case GM_ENC_ALERT_HIGH_SPREAD:         return "High Spread";
      case GM_ENC_ALERT_HIGH_VOL:            return "High Volatility";
      case GM_ENC_ALERT_CLOUD_CONNECTED:     return "Cloud Connected";
      case GM_ENC_ALERT_CLOUD_DISCONNECTED:  return "Cloud Disconnected";
      case GM_ENC_ALERT_LICENSE_UPDATED:     return "License Updated";
      case GM_ENC_ALERT_SYSTEM_WARNING:      return "System Warning";
      case GM_ENC_ALERT_CRITICAL_ERROR:      return "Critical Error";
     }
   return "None";
  }

#endif // GM_NOTIFICATION_CENTER_CONSTANTS_MQH
//+------------------------------------------------------------------+
