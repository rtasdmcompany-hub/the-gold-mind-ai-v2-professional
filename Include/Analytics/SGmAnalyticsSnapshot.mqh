//+------------------------------------------------------------------+
//|                                   SGmAnalyticsSnapshot.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_ANALYTICS_SNAPSHOT_MQH
#define GM_SGM_ANALYTICS_SNAPSHOT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file SGmAnalyticsSnapshot.mqh
/// @brief Full enterprise analytics snapshot — observation only.

struct SGmAnalyticsSnapshot
  {
   datetime stamped_at;
   long     magic;
   string   symbol;

   //--- Trade analytics
   int      total_trades;
   int      running_trades;
   int      pending_orders;
   int      winning_trades;
   int      losing_trades;
   int      buy_trades;          // closed buy outs
   int      sell_trades;         // closed sell outs
   int      buy_open;
   int      sell_open;
   int      cancelled_orders;
   int      expired_orders;
   int      recovery_trades;

   //--- Profit analytics
   double   today_profit;
   double   today_loss;
   double   week_profit;
   double   week_loss;
   double   month_profit;
   double   month_loss;
   double   total_net_profit;
   double   floating_profit;
   double   floating_loss;
   double   avg_profit_per_trade;
   double   avg_loss_per_trade;
   double   largest_win;
   double   largest_loss;

   //--- Win rate
   double   overall_win_rate;
   double   today_win_rate;
   double   week_win_rate;
   double   month_win_rate;
   double   buy_win_rate;
   double   sell_win_rate;
   double   first_attempt_win_rate;
   double   second_attempt_win_rate;
   double   today_loss_rate;

   //--- Risk analytics
   double   current_risk_pct;
   double   average_risk_pct;
   double   maximum_risk_pct;
   double   current_dd_pct;
   double   maximum_dd_pct;
   double   daily_dd_pct;
   double   weekly_dd_pct;
   double   monthly_dd_pct;
   double   recovery_factor;
   double   profit_factor;
   double   risk_reward_ratio;

   //--- History / duration
   double   avg_trade_duration_sec;
   double   fastest_trade_sec;
   double   longest_trade_sec;
   double   avg_pips;
   double   avg_holding_sec;
   double   avg_win_duration_sec;
   double   avg_loss_duration_sec;

   //--- Session
   ulong    current_session_id;
   int      completed_sessions;
   int      winning_sessions;
   int      losing_sessions;
   double   session_profit;
   double   session_loss;
   double   session_win_rate;
   int      session_countdown_sec;

   //--- Market / KPI helpers
   double   balance;
   double   equity;
   double   atr14;
   double   spread_points;

   //--- Performance engine
   ulong    last_collect_us;
   ulong    avg_tick_us;
   ulong    last_tick_us;
   ulong    memory_kb;
   double   cpu_load_pct;        // terminal estimate when available
   ulong    refresh_us;
   string   module_health;

   bool     valid;
   ulong    fingerprint;

   void Reset(void)
     {
      stamped_at = 0;
      magic = 0;
      symbol = "";
      total_trades = 0;
      running_trades = 0;
      pending_orders = 0;
      winning_trades = 0;
      losing_trades = 0;
      buy_trades = 0;
      sell_trades = 0;
      buy_open = 0;
      sell_open = 0;
      cancelled_orders = 0;
      expired_orders = 0;
      recovery_trades = 0;
      today_profit = 0.0;
      today_loss = 0.0;
      week_profit = 0.0;
      week_loss = 0.0;
      month_profit = 0.0;
      month_loss = 0.0;
      total_net_profit = 0.0;
      floating_profit = 0.0;
      floating_loss = 0.0;
      avg_profit_per_trade = 0.0;
      avg_loss_per_trade = 0.0;
      largest_win = 0.0;
      largest_loss = 0.0;
      overall_win_rate = 0.0;
      today_win_rate = 0.0;
      week_win_rate = 0.0;
      month_win_rate = 0.0;
      buy_win_rate = 0.0;
      sell_win_rate = 0.0;
      first_attempt_win_rate = 0.0;
      second_attempt_win_rate = 0.0;
      today_loss_rate = 0.0;
      current_risk_pct = 0.0;
      average_risk_pct = 0.0;
      maximum_risk_pct = 0.0;
      current_dd_pct = 0.0;
      maximum_dd_pct = 0.0;
      daily_dd_pct = 0.0;
      weekly_dd_pct = 0.0;
      monthly_dd_pct = 0.0;
      recovery_factor = 0.0;
      profit_factor = 0.0;
      risk_reward_ratio = 0.0;
      avg_trade_duration_sec = 0.0;
      fastest_trade_sec = 0.0;
      longest_trade_sec = 0.0;
      avg_pips = 0.0;
      avg_holding_sec = 0.0;
      avg_win_duration_sec = 0.0;
      avg_loss_duration_sec = 0.0;
      current_session_id = 0;
      completed_sessions = 0;
      winning_sessions = 0;
      losing_sessions = 0;
      session_profit = 0.0;
      session_loss = 0.0;
      session_win_rate = 0.0;
      session_countdown_sec = 0;
      balance = 0.0;
      equity = 0.0;
      atr14 = 0.0;
      spread_points = 0.0;
      last_collect_us = 0;
      avg_tick_us = 0;
      last_tick_us = 0;
      memory_kb = 0;
      cpu_load_pct = 0.0;
      refresh_us = 0;
      module_health = "OK";
      valid = false;
      fingerprint = 0;
     }

   ulong ComputeFingerprint(void) const
     {
      ulong h = (ulong)total_trades * 31 + (ulong)running_trades * 17 + (ulong)pending_orders;
      h ^= (ulong)((long)(total_net_profit * 100.0));
      h ^= (ulong)((long)(today_profit * 100.0));
      h ^= (ulong)((long)(floating_profit * 100.0));
      h ^= (ulong)((long)(equity * 100.0));
      h ^= (ulong)((long)(current_dd_pct * 100.0));
      h ^= (ulong)current_session_id;
      h ^= (ulong)session_countdown_sec;
      return h;
     }
  };

#endif // GM_SGM_ANALYTICS_SNAPSHOT_MQH
//+------------------------------------------------------------------+
