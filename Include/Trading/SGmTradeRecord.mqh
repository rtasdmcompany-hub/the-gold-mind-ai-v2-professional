//+------------------------------------------------------------------+
//|                                             SGmTradeRecord.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_TRADE_RECORD_MQH
#define GM_SGM_TRADE_RECORD_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../Calculation/EnumsLevels.mqh"

/// @file SGmTradeRecord.mqh
/// @brief Persistent trade registry — Sprint 5 management flags included.

enum ENUM_GM_TRADE_STATUS
  {
   GM_TRADE_STATUS_NONE = 0,
   GM_TRADE_STATUS_PENDING,
   GM_TRADE_STATUS_ACTIVE,
   GM_TRADE_STATUS_CLOSED,
   GM_TRADE_STATUS_CANCELLED
  };

/// Sprint 5 professional trade stages.
enum ENUM_GM_TRADE_STAGE
  {
   GM_TRADE_STAGE_OPENED = 0,       ///< Stage 1 — Trade Opened
   GM_TRADE_STAGE_RUNNING = 1,      ///< Stage 2 — Trade Running
   GM_TRADE_STAGE_PROFIT_50 = 2,    ///< Stage 3 — +50 Pip Profit
   GM_TRADE_STAGE_BREAK_EVEN = 3,   ///< Stage 4 — Break Even Activated
   GM_TRADE_STAGE_PARTIAL_DONE = 4, ///< Stage 5 — 80% Partial Close
   GM_TRADE_STAGE_TRAILING = 5,     ///< Stage 6 — Trailing Stop Active
   GM_TRADE_STAGE_CLOSED = 6        ///< Stage 7 — Trade Closed
  };

// Legacy name aliases (pre-Sprint-5)
#define GM_TRADE_STAGE_NEW       GM_TRADE_STAGE_OPENED
#define GM_TRADE_STAGE_PROTECTED GM_TRADE_STAGE_RUNNING
#define GM_TRADE_STAGE_MANAGED   GM_TRADE_STAGE_TRAILING
#define GM_TRADE_STAGE_DONE      GM_TRADE_STAGE_CLOSED

enum ENUM_GM_LIFECYCLE
  {
   GM_LIFE_UNKNOWN = 0,
   GM_LIFE_OPEN,
   GM_LIFE_CLOSED
  };

struct SGmTradeRecord
  {
   ulong                 trade_id;
   ulong                 ticket;
   ulong                 order_ticket;
   long                  magic;
   string                symbol;
   string                level_tag;
   ENUM_GM_LEVEL_SIDE    direction;
   datetime              h4_cycle_id;
   datetime              open_time;
   double                entry_price;
   double                stop_loss;
   double                take_profit;
   double                volume;            ///< current / last known volume
   double                original_volume;   ///< volume at activation
   double                current_profit;
   double                current_loss;
   double                profit_pips;
   int                   trade_attempts;
   ENUM_GM_TRADE_STATUS  status;
   ENUM_GM_TRADE_STAGE   stage;
   ENUM_GM_LIFECYCLE     lifecycle;
   int                   ai_status;
   bool                  be_done;
   bool                  partial_done;
   bool                  trailing_active;
   bool                  used;

   void Reset(void)
     {
      trade_id = 0;
      ticket = 0;
      order_ticket = 0;
      magic = 0;
      symbol = "";
      level_tag = "";
      direction = GM_LEVEL_SIDE_BUY;
      h4_cycle_id = 0;
      open_time = 0;
      entry_price = 0.0;
      stop_loss = 0.0;
      take_profit = 0.0;
      volume = 0.0;
      original_volume = 0.0;
      current_profit = 0.0;
      current_loss = 0.0;
      profit_pips = 0.0;
      trade_attempts = 0;
      status = GM_TRADE_STATUS_NONE;
      stage = GM_TRADE_STAGE_OPENED;
      lifecycle = GM_LIFE_UNKNOWN;
      ai_status = 0;
      be_done = false;
      partial_done = false;
      trailing_active = false;
      used = false;
     }
  };

#endif // GM_SGM_TRADE_RECORD_MQH
//+------------------------------------------------------------------+
