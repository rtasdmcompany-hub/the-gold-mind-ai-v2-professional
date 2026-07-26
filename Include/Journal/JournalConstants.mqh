//+------------------------------------------------------------------+
//|                                       JournalConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_JOURNAL_CONSTANTS_MQH
#define GM_JOURNAL_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file JournalConstants.mqh
/// @brief Phase 2 Sprint 5 — Alert Center / Journal limits (READ-ONLY).

#define GM_ALERT_MAX                200
#define GM_TRADE_JOURNAL_MAX        500
#define GM_LEVEL_JOURNAL_MAX        300
#define GM_SESSION_JOURNAL_MAX      200
#define GM_JOURNAL_SYNC_SEC         5
#define GM_REPORT_CACHE_MAX         16
#define GM_SEARCH_RESULT_MAX        100
#define GM_JOURNAL_FILE_PREFIX      "GM_Journal_"
#define GM_ALERT_FILE_PREFIX        "GM_Alerts_"
#define GM_SESSION_JOURNAL_PREFIX   "GM_SessJournal_"
#define GM_REPORT_FILE_PREFIX       "GM_Report_"

enum ENUM_GM_ALERT_CATEGORY
  {
   GM_ALERT_INFO = 0,
   GM_ALERT_SUCCESS,
   GM_ALERT_WARNING,
   GM_ALERT_ERROR,
   GM_ALERT_CRITICAL
  };

enum ENUM_GM_ALERT_STATUS
  {
   GM_ALERT_NEW = 0,
   GM_ALERT_ACKNOWLEDGED,
   GM_ALERT_ARCHIVED
  };

enum ENUM_GM_JOURNAL_FILTER
  {
   GM_JF_ALL = 0,
   GM_JF_BUY,
   GM_JF_SELL,
   GM_JF_WINNING,
   GM_JF_LOSING,
   GM_JF_OPEN,
   GM_JF_CLOSED,
   GM_JF_RECOVERY
  };

enum ENUM_GM_REPORT_TYPE
  {
   GM_RPT_DAILY = 0,
   GM_RPT_WEEKLY,
   GM_RPT_MONTHLY,
   GM_RPT_SESSION,
   GM_RPT_TRADE,
   GM_RPT_PERFORMANCE,
   GM_RPT_RISK,
   GM_RPT_RECOVERY
  };

enum ENUM_GM_REPORT_EXPORT
  {
   GM_REXP_CSV = 0,
   GM_REXP_JSON,
   GM_REXP_XML,
   GM_REXP_PDF,
   GM_REXP_DATABASE,
   GM_REXP_CLOUD,
   GM_REXP_MOBILE,
   GM_REXP_WEB
  };

#endif // GM_JOURNAL_CONSTANTS_MQH
//+------------------------------------------------------------------+
