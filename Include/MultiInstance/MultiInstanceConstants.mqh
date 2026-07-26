//+------------------------------------------------------------------+
//|                                    MultiInstanceConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_MULTI_INSTANCE_CONSTANTS_MQH
#define GM_MULTI_INSTANCE_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file MultiInstanceConstants.mqh
/// @brief Phase 2 Sprint 7 — multi-instance management (monitoring only).

#define GM_INSTANCE_MAX             64
#define GM_INSTANCE_STALE_SEC       45
#define GM_INSTANCE_SYNC_SEC        5
#define GM_INSTANCE_HB_PREFIX       "GM_INST_"
#define GM_INSTANCE_INDEX_FILE      "GM_INST_INDEX.txt"

enum ENUM_GM_INSTANCE_STATUS
  {
   GM_INST_STARTING = 0,
   GM_INST_RUNNING,
   GM_INST_PAUSED,
   GM_INST_ERROR,
   GM_INST_CLOSED
  };

enum ENUM_GM_MI_API_TARGET
  {
   GM_MI_API_CENTRAL_DASH = 0,
   GM_MI_API_DESKTOP,
   GM_MI_API_CLOUD,
   GM_MI_API_MOBILE,
   GM_MI_API_WEB,
   GM_MI_API_AI_SUPERVISOR,
   GM_MI_API_REMOTE
  };

#endif // GM_MULTI_INSTANCE_CONSTANTS_MQH
//+------------------------------------------------------------------+
