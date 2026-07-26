//+------------------------------------------------------------------+
//|                                              EnumsLogging.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|                        Copyright 2026, RTAS Softwear            |
//+------------------------------------------------------------------+
#ifndef GM_ENUMS_LOGGING_MQH
#define GM_ENUMS_LOGGING_MQH
#property copyright "Copyright 2026, RTAS Softwear"
#property link      "https://rtas.softwear"
#property strict

/// @file EnumsLogging.mqh
/// @brief Logging level and destination enumerations.

/// Log severity levels (ordered from most verbose to most severe).
enum ENUM_GM_LOG_LEVEL
  {
   GM_LOG_DEBUG   = 0, ///< Diagnostic detail for development
   GM_LOG_INFO    = 1, ///< Normal operational messages
   GM_LOG_SUCCESS = 2, ///< Positive confirmation events
   GM_LOG_WARNING = 3, ///< Recoverable issues
   GM_LOG_ERROR   = 4  ///< Failures requiring attention
  };

/// Where log output is written.
enum ENUM_GM_LOG_DESTINATION
  {
   GM_LOG_DEST_TERMINAL = 1, ///< Experts / Journal terminal
   GM_LOG_DEST_FILE     = 2, ///< Common/Files or terminal Files
   GM_LOG_DEST_BOTH     = 3  ///< Terminal + file
  };

#endif // GM_ENUMS_LOGGING_MQH
//+------------------------------------------------------------------+
