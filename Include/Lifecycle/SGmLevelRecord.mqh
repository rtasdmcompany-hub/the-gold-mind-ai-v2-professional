//+------------------------------------------------------------------+
//|                                             SGmLevelRecord.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_LEVEL_RECORD_MQH
#define GM_SGM_LEVEL_RECORD_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "EnumsLifecycle.mqh"
#include "../Calculation/EnumsLevels.mqh"

/// @file SGmLevelRecord.mqh
/// @brief Persistent per-level lifecycle record.

struct SGmLevelHistoryEntry
  {
   datetime             time;
   ENUM_GM_LEVEL_EVENT  event_id;
   ENUM_GM_LEVEL_STATE  state_after;
   string               note;
  };

struct SGmLevelRecord
  {
   ulong                 level_id;
   ulong                 trade_id;
   ulong                 order_ticket;
   ulong                 position_ticket;
   long                  magic;
   string                symbol;
   string                level_tag;
   ENUM_GM_LEVEL_TAG     tag;
   ENUM_GM_LEVEL_SIDE    direction;
   datetime              h4_cycle_id;
   double                entry_price;
   int                   attempt;
   ENUM_GM_LEVEL_STATE   state;
   datetime              open_time;
   datetime              close_time;
   double                profit;
   double                loss;
   bool                  used;
   bool                  active_for_cycle;   ///< false when COMPLETED/FAILED/EXPIRED
   int                   history_count;
   SGmLevelHistoryEntry  history[GM_LEVEL_HISTORY_MAX];

   void Reset(void)
     {
      level_id = 0;
      trade_id = 0;
      order_ticket = 0;
      position_ticket = 0;
      magic = 0;
      symbol = "";
      level_tag = "";
      tag = GM_TAG_BL1;
      direction = GM_LEVEL_SIDE_BUY;
      h4_cycle_id = 0;
      entry_price = 0.0;
      attempt = 0;
      state = GM_LVL_WAITING;
      open_time = 0;
      close_time = 0;
      profit = 0.0;
      loss = 0.0;
      used = false;
      active_for_cycle = false;
      history_count = 0;
     }

   static string StateToString(const ENUM_GM_LEVEL_STATE st)
     {
      switch(st)
        {
         case GM_LVL_WAITING:         return "WAITING";
         case GM_LVL_PENDING_PLACED:  return "PENDING_PLACED";
         case GM_LVL_TRADE_ACTIVATED: return "TRADE_ACTIVATED";
         case GM_LVL_TRADE_RUNNING:   return "TRADE_RUNNING";
         case GM_LVL_TP_HIT:          return "TP_HIT";
         case GM_LVL_SL_FIRST:        return "SL_FIRST";
         case GM_LVL_REACTIVATED:     return "REACTIVATED";
         case GM_LVL_SL_SECOND:       return "SL_SECOND";
         case GM_LVL_COMPLETED:       return "COMPLETED";
         case GM_LVL_FAILED:          return "FAILED";
         case GM_LVL_EXPIRED:         return "EXPIRED";
        }
      return "UNKNOWN";
     }
  };

#endif // GM_SGM_LEVEL_RECORD_MQH
//+------------------------------------------------------------------+
