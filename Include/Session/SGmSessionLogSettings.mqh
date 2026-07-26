//+------------------------------------------------------------------+
//|                                      SGmSessionLogSettings.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_SESSION_LOG_SETTINGS_MQH
#define GM_SGM_SESSION_LOG_SETTINGS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SessionConstants.mqh"

/// @file SGmSessionLogSettings.mqh
/// @brief Configurable session / audit / performance logging (AI-ready).

struct SGmSessionLogSettings
  {
   bool enable_session_logs;
   bool enable_performance_logs;
   bool enable_audit_logs;
   bool enable_recovery_logs;
   int  max_log_size_kb;
   bool automatic_archive;

   void Defaults(void)
     {
      enable_session_logs = GM_SESSION_ENABLE_LOGS_DEFAULT;
      enable_performance_logs = GM_SESSION_ENABLE_PERF_DEFAULT;
      enable_audit_logs = GM_SESSION_ENABLE_AUDIT_DEFAULT;
      enable_recovery_logs = GM_SESSION_ENABLE_RECOVERY_DEFAULT;
      max_log_size_kb = GM_SESSION_LOG_SIZE_DEFAULT_KB;
      automatic_archive = GM_SESSION_AUTO_ARCHIVE_DEFAULT;
     }
  };

#endif // GM_SGM_SESSION_LOG_SETTINGS_MQH
//+------------------------------------------------------------------+
