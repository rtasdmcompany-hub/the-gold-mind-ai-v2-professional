//+------------------------------------------------------------------+
//|                                           SessionConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SESSION_CONSTANTS_MQH
#define GM_SESSION_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file SessionConstants.mqh
/// @brief Sprint 7 H4 Session Engine defaults.

#define GM_SESSION_ARCHIVE_MAX           32
#define GM_SESSION_AUDIT_MAX             256
#define GM_SESSION_LOG_SIZE_DEFAULT_KB   2048
#define GM_SESSION_PERF_SLOW_US          750000
#define GM_SESSION_FILE_PREFIX           "GM_Session_"
#define GM_SESSION_AUDIT_PREFIX          "GM_Audit_"
#define GM_SESSION_ENABLE_LOGS_DEFAULT   true
#define GM_SESSION_ENABLE_PERF_DEFAULT   true
#define GM_SESSION_ENABLE_AUDIT_DEFAULT  true
#define GM_SESSION_ENABLE_RECOVERY_DEFAULT true
#define GM_SESSION_AUTO_ARCHIVE_DEFAULT  true

#endif // GM_SESSION_CONSTANTS_MQH
//+------------------------------------------------------------------+
