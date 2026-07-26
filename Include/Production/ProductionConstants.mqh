//+------------------------------------------------------------------+
//|                                        ProductionConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_PRODUCTION_CONSTANTS_MQH
#define GM_PRODUCTION_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file ProductionConstants.mqh
/// @brief Sprint 9 / RC-1 production hardening defaults.

enum ENUM_GM_RUNTIME_MODE
  {
   GM_MODE_PRODUCTION = 0,
   GM_MODE_DEBUG,
   GM_MODE_DEVELOPMENT
  };

#define GM_PROD_REGISTRY_FLUSH_SEC        5
#define GM_PROD_SESSION_SYNC_SEC          5
#define GM_PROD_FAILSAFE_CHECK_SEC        1
#define GM_PROD_LOW_MARGIN_WARN           50.0   // free margin $
#define GM_PROD_LOW_MEMORY_MB             64
#define GM_PROD_LOG_THROTTLE_MS           1000
#define GM_PROD_ACTION_COOLDOWN_MS        250
#define GM_RC_LABEL                       "RC-1"
#define GM_PROD_REPORT_PREFIX             "GM_Production_"

#endif // GM_PRODUCTION_CONSTANTS_MQH
//+------------------------------------------------------------------+
