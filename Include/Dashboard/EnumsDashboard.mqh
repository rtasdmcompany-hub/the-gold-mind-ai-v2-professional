//+------------------------------------------------------------------+
//|                                         EnumsDashboard.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_ENUMS_DASHBOARD_MQH
#define GM_ENUMS_DASHBOARD_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file EnumsDashboard.mqh
/// @brief Dashboard themes, sections, events, and smart notifications.

enum ENUM_GM_DASH_THEME
  {
   GM_DASH_THEME_DARK = 0,          ///< Dark Gray
   GM_DASH_THEME_GOLD = 1,          ///< Professional Black Gold (default)
   GM_DASH_THEME_FUTURE = 2,        ///< Dark Blue
   GM_DASH_THEME_MIDNIGHT = 3,      ///< Midnight Black
   GM_DASH_THEME_LIGHT = 4,         ///< Light Theme
   GM_DASH_THEME_CUSTOM = 5         ///< Custom user colors
  };

enum ENUM_GM_FONT_PRESET
  {
   GM_FONT_SMALL = 0,
   GM_FONT_MEDIUM,
   GM_FONT_LARGE,
   GM_FONT_XLARGE
  };

enum ENUM_GM_VIEW_MODE
  {
   GM_VIEW_COMPACT = 0,
   GM_VIEW_STANDARD,
   GM_VIEW_PROFESSIONAL
  };

enum ENUM_GM_UI_LANG
  {
   GM_LANG_EN = 0,
   GM_LANG_UR,
   GM_LANG_AR
  };

enum ENUM_GM_DASH_SECTION
  {
   GM_DASH_SEC_HEADER = 0,
   GM_DASH_SEC_ACCOUNT,
   GM_DASH_SEC_TRADING,
   GM_DASH_SEC_RISK,
   GM_DASH_SEC_PERFORMANCE,
   GM_DASH_SEC_SYSTEM,
   GM_DASH_SEC_AI,
   GM_DASH_SEC_STATS,
   GM_DASH_SEC_NOTIFICATIONS,
   GM_DASH_SEC_FOOTER,
   GM_DASH_SEC_COUNT
  };

enum ENUM_GM_DASH_EVENT
  {
   GM_DASH_EVT_NONE = 0,
   GM_DASH_EVT_TRADE_OPENED,
   GM_DASH_EVT_TRADE_CLOSED,
   GM_DASH_EVT_PENDING_ADDED,
   GM_DASH_EVT_PENDING_DELETED,
   GM_DASH_EVT_BREAK_EVEN,
   GM_DASH_EVT_TRAILING,
   GM_DASH_EVT_NEW_H4,
   GM_DASH_EVT_SESSION_CHANGED,
   GM_DASH_EVT_RISK_UPDATED,
   GM_DASH_EVT_DASHBOARD_REFRESH,
   GM_DASH_EVT_AI_FUTURE,
   GM_DASH_EVT_LOADED,
   GM_DASH_EVT_HIDDEN,
   GM_DASH_EVT_ERROR
  };

enum ENUM_GM_NOTIFY_TYPE
  {
   GM_NOTIFY_NONE = 0,
   GM_NOTIFY_NEW_H4_SESSION,
   GM_NOTIFY_PENDING_CREATED,
   GM_NOTIFY_TRADE_ACTIVATED,
   GM_NOTIFY_TP_HIT,
   GM_NOTIFY_SL_HIT,
   GM_NOTIFY_BREAK_EVEN,
   GM_NOTIFY_PARTIAL_CLOSE,
   GM_NOTIFY_TRAILING,
   GM_NOTIFY_LEVEL_REACTIVATED,
   GM_NOTIFY_RECOVERY_STARTED,
   GM_NOTIFY_RECOVERY_COMPLETED,
   GM_NOTIFY_BROKER_WARNING,
   GM_NOTIFY_SPREAD_WARNING,
   GM_NOTIFY_CONNECTION_LOST,
   GM_NOTIFY_CONNECTION_RESTORED,
   GM_NOTIFY_DAILY_PROFIT_TARGET,
   GM_NOTIFY_DAILY_LOSS_WARNING,
   GM_NOTIFY_INFO
  };

enum ENUM_GM_NOTIFY_SEVERITY
  {
   GM_SEV_INFO = 0,
   GM_SEV_OK,
   GM_SEV_WARN,
   GM_SEV_PAUSE,
   GM_SEV_ERROR
  };

#endif // GM_ENUMS_DASHBOARD_MQH
//+------------------------------------------------------------------+
