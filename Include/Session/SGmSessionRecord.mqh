//+------------------------------------------------------------------+
//|                                          SGmSessionRecord.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_SESSION_RECORD_MQH
#define GM_SGM_SESSION_RECORD_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../Calculation/SGmLevels.mqh"

/// @file SGmSessionRecord.mqh
/// @brief One H4 candle = one Trading Session.

enum ENUM_GM_SESSION_STATE
  {
   GM_SESSION_NONE = 0,
   GM_SESSION_ACTIVE,
   GM_SESSION_ARCHIVED,
   GM_SESSION_RECOVERED
  };

struct SGmSessionRecord
  {
   ulong                 session_id;       ///< Unique ID (= candle open time as ulong)
   datetime              session_start;
   datetime              session_end;
   datetime              candle_open;
   datetime              candle_close;
   datetime              h4_bar_time;      ///< Same as candle_open (closed H4 open)
   long                  magic;
   string                symbol;
   ENUM_GM_SESSION_STATE state;
   int                   generated_levels;
   int                   active_levels;
   int                   completed_levels;
   int                   failed_levels;
   int                   pending_orders;
   int                   active_trades;
   bool                  levels_valid;
   SGmLevels             levels;
   bool                  used;

   void Reset(void)
     {
      session_id = 0;
      session_start = 0;
      session_end = 0;
      candle_open = 0;
      candle_close = 0;
      h4_bar_time = 0;
      magic = 0;
      symbol = "";
      state = GM_SESSION_NONE;
      generated_levels = 0;
      active_levels = 0;
      completed_levels = 0;
      failed_levels = 0;
      pending_orders = 0;
      active_trades = 0;
      levels_valid = false;
      levels.Reset();
      used = false;
     }

   void BindFromLevels(const SGmLevels &snap, const long magic_in, const string symbol_in)
     {
      h4_bar_time = snap.h4_bar_time;
      candle_open = snap.h4_bar_time;
      candle_close = snap.h4_bar_time + PeriodSeconds(PERIOD_H4);
      session_id = (ulong)snap.h4_bar_time;
      session_start = TimeCurrent();
      session_end = 0;
      magic = magic_in;
      symbol = symbol_in;
      levels = snap;
      levels_valid = snap.valid;
      generated_levels = snap.valid ? 6 : 0;
      state = GM_SESSION_ACTIVE;
      used = true;
     }
  };

#endif // GM_SGM_SESSION_RECORD_MQH
//+------------------------------------------------------------------+
