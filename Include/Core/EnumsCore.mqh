//+------------------------------------------------------------------+
//|                                                  EnumsCore.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_ENUMS_CORE_MQH
#define GM_ENUMS_CORE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file EnumsCore.mqh
/// @brief Shared core enumerations for application lifecycle and module state.

enum ENUM_GM_APP_STATE
  {
   GM_APP_STATE_UNINITIALIZED = 0,
   GM_APP_STATE_INITIALIZING,
   GM_APP_STATE_READY,
   GM_APP_STATE_RUNNING,
   GM_APP_STATE_PAUSED,
   GM_APP_STATE_SHUTTING_DOWN,
   GM_APP_STATE_ERROR
  };

enum ENUM_GM_MODULE_STATUS
  {
   GM_MODULE_DISABLED = 0,
   GM_MODULE_IDLE,
   GM_MODULE_READY,
   GM_MODULE_FAULT
  };

/// Isolated engine identifiers (architecture boundary tags).
enum ENUM_GM_ENGINE_ID
  {
   GM_ENGINE_STRATEGY = 0,   ///< Core Strategy Engine
   GM_ENGINE_TRADE_MGMT,     ///< Trade Management Engine
   GM_ENGINE_RISK,           ///< Risk Engine
   GM_ENGINE_RECOVERY,       ///< Recovery Engine
   GM_ENGINE_AI,             ///< AI Intelligence Layer
   GM_ENGINE_ANALYTICS       ///< Analytics Engine
  };

enum ENUM_GM_SESSION_TYPE
  {
   GM_SESSION_UNKNOWN = 0,
   GM_SESSION_ASIAN,
   GM_SESSION_LONDON,
   GM_SESSION_NEWYORK,
   GM_SESSION_OVERLAP,
   GM_SESSION_CLOSED
  };

enum ENUM_GM_ERROR_SEVERITY
  {
   GM_ERROR_SEVERITY_INFO = 0,
   GM_ERROR_SEVERITY_WARNING,
   GM_ERROR_SEVERITY_ERROR,
   GM_ERROR_SEVERITY_CRITICAL
  };

#endif // GM_ENUMS_CORE_MQH
//+------------------------------------------------------------------+
