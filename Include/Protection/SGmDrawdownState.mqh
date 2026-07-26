//+------------------------------------------------------------------+
//|                                         SGmDrawdownState.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_DRAWDOWN_STATE_MQH
#define GM_SGM_DRAWDOWN_STATE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file SGmDrawdownState.mqh
/// @brief Drawdown metrics — monitor & warn only (Sprint 6).

struct SGmDrawdownState
  {
   datetime stamped_at;
   double   peak_equity;
   double   day_start_equity;
   double   week_start_equity;
   double   month_start_equity;
   double   current_dd_pct;
   double   max_dd_pct;
   double   daily_dd_pct;
   double   weekly_dd_pct;
   double   monthly_dd_pct;
   int      day_key;     // YYYYMMDD
   int      week_key;    // YYYYWW
   int      month_key;   // YYYYMM
   bool     warn_dd;
   bool     warn_daily;
   bool     valid;

   void Reset(void)
     {
      stamped_at = 0;
      peak_equity = 0.0;
      day_start_equity = 0.0;
      week_start_equity = 0.0;
      month_start_equity = 0.0;
      current_dd_pct = 0.0;
      max_dd_pct = 0.0;
      daily_dd_pct = 0.0;
      weekly_dd_pct = 0.0;
      monthly_dd_pct = 0.0;
      day_key = 0;
      week_key = 0;
      month_key = 0;
      warn_dd = false;
      warn_daily = false;
      valid = false;
     }
  };

#endif // GM_SGM_DRAWDOWN_STATE_MQH
//+------------------------------------------------------------------+
