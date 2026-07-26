//+------------------------------------------------------------------+
//|                                          EnumsLifecycle.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_ENUMS_LIFECYCLE_MQH
#define GM_ENUMS_LIFECYCLE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file EnumsLifecycle.mqh
/// @brief Level lifecycle states for Sprint 4.

enum ENUM_GM_LEVEL_STATE
  {
   GM_LVL_WAITING = 0,           ///< Created, awaiting pending
   GM_LVL_PENDING_PLACED,        ///< Pending order live
   GM_LVL_TRADE_ACTIVATED,       ///< Pending filled
   GM_LVL_TRADE_RUNNING,         ///< Market trade open
   GM_LVL_TP_HIT,                ///< Take Profit (SUCCESSFUL)
   GM_LVL_SL_FIRST,              ///< Stop Loss first time
   GM_LVL_REACTIVATED,           ///< Same level re-armed (attempt 2)
   GM_LVL_SL_SECOND,             ///< Stop Loss second time
   GM_LVL_COMPLETED,             ///< Terminal success for this H4
   GM_LVL_FAILED,                ///< Terminal fail for this H4
   GM_LVL_EXPIRED                ///< Cycle rolled / expired
  };

enum ENUM_GM_LEVEL_EVENT
  {
   GM_LVL_EVT_CREATED = 0,
   GM_LVL_EVT_PENDING_PLACED,
   GM_LVL_EVT_ACTIVATED,
   GM_LVL_EVT_RUNNING,
   GM_LVL_EVT_SL_FIRST,
   GM_LVL_EVT_REACTIVATED,
   GM_LVL_EVT_SL_SECOND,
   GM_LVL_EVT_TP,
   GM_LVL_EVT_COMPLETED,
   GM_LVL_EVT_FAILED,
   GM_LVL_EVT_EXPIRED,
   GM_LVL_EVT_RECOVERY,
   GM_LVL_EVT_ERROR
  };

#define GM_LEVEL_DB_MAX           6
#define GM_LEVEL_HISTORY_MAX      64
#define GM_LEVEL_DB_FILE_PREFIX   "GM_LevelDB_"
#define GM_LEVEL_MAX_ATTEMPTS     2

#endif // GM_ENUMS_LIFECYCLE_MQH
//+------------------------------------------------------------------+
