//+------------------------------------------------------------------+
//|                                   SGmDashboardSnapshot.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_DASHBOARD_SNAPSHOT_MQH
#define GM_SGM_DASHBOARD_SNAPSHOT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file SGmDashboardSnapshot.mqh
/// @brief Phase 2 Sprint 2 — full live monitor snapshot (READ-ONLY).

struct SGmDashboardSnapshot
  {
   datetime stamped_at;
   //--- Header / EA
   string   ea_status;
   //--- Account
   long     account_login;
   string   broker_name;
   string   server_name;
   string   account_type;
   string   currency;
   int      leverage;
   double   balance;
   double   equity;
   double   free_margin;
   double   margin;
   double   margin_level;
   //--- Risk (display of frozen Core constants + live monitors)
   double   auto_risk_pct;
   double   current_risk_pct;
   double   max_daily_risk_pct;
   double   current_dd_pct;
   double   max_dd_pct;
   string   risk_status;
   //--- Live trade status
   int      running_trades;
   int      pending_orders;
   int      buy_trades;
   int      sell_trades;
   int      winning_open;
   int      losing_open;
   int      active_hedge;       // always 0 in Phase 1/2 until hedge engine
   string   trade_engine_status;
   //--- Today performance
   double   today_profit;
   double   today_loss;
   double   today_net;
   int      today_opened;
   int      today_closed;
   int      today_winners;
   int      today_losers;
   double   today_win_rate;
   double   today_loss_rate;
   //--- Overall performance
   int      total_trades;
   int      total_winners;
   int      total_losers;
   double   overall_win_rate;
   double   profit_factor;
   double   recovery_factor;
   double   avg_win;
   double   avg_loss;
   double   risk_reward;
   double   week_win_rate;
   double   month_win_rate;
   //--- Analytics KPI strip
   int      cancelled_orders;
   int      expired_orders;
   int      trade_counter;
   double   analytics_refresh_us;
   string   analytics_health;
   //--- Sprint 4 Command Center
   double   week_net;
   double   month_net;
   double   total_net;
   double   avg_trade_duration_sec;
   double   trade_success_rate;
   string   clock_local;
   string   clock_server;
   string   ea_module_status;
   string   broker_module_status;
   string   internet_module_status;
   string   market_module_status;
   string   trading_perm_status;
   string   recovery_module_status;
   string   logging_module_status;
   string   analytics_module_status;
   string   dashboard_module_status;
   double   gauge_risk;
   double   gauge_dd;
   double   gauge_wr;
   double   gauge_pf;
   double   gauge_rf;
   double   gauge_speed;
   double   gauge_conn;
   double   gauge_health;
   string   notify_banner;
   string   timeline_line0;
   string   timeline_line1;
   string   timeline_line2;
   string   timeline_line3;
   string   timeline_line4;
   string   timeline_line5;
   string   timeline_line6;
   string   timeline_line7;
   //--- Sprint 5 Report Panel
   string   rpt_today_summary;
   string   rpt_last_win;
   string   rpt_last_loss;
   string   rpt_largest_win;
   string   rpt_largest_loss;
   string   rpt_win_streak;
   string   rpt_loss_streak;
   string   rpt_session_result;
   string   rpt_avg_trade_time;
   int      rpt_alert_count;
   string   rpt_last_alert;
   //--- Sprint 6 AI Decision Center + Market Info
   string   ai_status;
   string   ai_version;
   string   ai_engine;
   string   ai_learning_status;
   string   ai_decision_status;
   string   ai_prediction_status;
   string   ai_confidence_status;
   string   ai_current_mode;
   string   ai_future_score;
   string   ai_market_analyzer;
   string   ai_trend_analyzer;
   string   ai_volatility_analyzer;
   string   ai_news_analyzer;
   string   ai_recovery;
   double   mkt_candle_cur;
   double   mkt_candle_prev;
   double   mkt_daily_range;
   double   mkt_weekly_range;
   string   mkt_volatility;
   string   mkt_activity;
   //--- Sprint 7 Multi-Instance
   string   mi_instance_id;
   long     mi_chart_id;
   int      mi_running_instances;
   string   mi_symbol;
   string   mi_timeframe;
   double   mi_instance_health;
   double   mi_global_health;
   double   mi_global_floating_profit;
   double   mi_global_floating_loss;
   int      mi_global_open_trades;
   int      mi_active_symbols;
   //--- Session
   string   symbol;
   string   timeframe;
   ulong    session_id;
   datetime h4_cycle;
   datetime next_h4;
   int      h4_countdown_sec;
   double   atr14;
   double   spread_points;
   string   market_status;
   //--- System
   bool     internet_ok;
   bool     broker_connected;
   bool     trade_allowed;
   bool     autotrading;
   bool     recovery_ok;
   bool     logging_ok;
   bool     dashboard_ok;
   //--- Live trade monitor
   string   last_trade_result;
   double   last_trade_pnl;
   double   floating_profit;
   double   floating_loss;
   double   floating_pips;
   string   be_status;
   string   trail_status;
   string   hedge_status;
   string   trade_stage;
   //--- Misc
   long     magic;
   int      registry_count;
   bool     core_frozen;
   bool     protection_ready;
   ulong    last_refresh_us;
   ulong    terminal_memory_kb;
   string   notification;
   bool     valid;
   ulong    fingerprint;

   void Reset(void)
     {
      stamped_at = 0;
      ea_status = "INIT";
      account_login = 0;
      broker_name = "";
      server_name = "";
      account_type = "";
      currency = "";
      leverage = 0;
      balance = 0.0;
      equity = 0.0;
      free_margin = 0.0;
      margin = 0.0;
      margin_level = 0.0;
      auto_risk_pct = 0.0;
      current_risk_pct = 0.0;
      max_daily_risk_pct = 0.0;
      current_dd_pct = 0.0;
      max_dd_pct = 0.0;
      risk_status = "—";
      running_trades = 0;
      pending_orders = 0;
      buy_trades = 0;
      sell_trades = 0;
      winning_open = 0;
      losing_open = 0;
      active_hedge = 0;
      trade_engine_status = "—";
      today_profit = 0.0;
      today_loss = 0.0;
      today_net = 0.0;
      today_opened = 0;
      today_closed = 0;
      today_winners = 0;
      today_losers = 0;
      today_win_rate = 0.0;
      today_loss_rate = 0.0;
      total_trades = 0;
      total_winners = 0;
      total_losers = 0;
      overall_win_rate = 0.0;
      profit_factor = 0.0;
      recovery_factor = 0.0;
      avg_win = 0.0;
      avg_loss = 0.0;
      risk_reward = 0.0;
      week_win_rate = 0.0;
      month_win_rate = 0.0;
      cancelled_orders = 0;
      expired_orders = 0;
      trade_counter = 0;
      analytics_refresh_us = 0.0;
      analytics_health = "OK";
      week_net = 0.0;
      month_net = 0.0;
      total_net = 0.0;
      avg_trade_duration_sec = 0.0;
      trade_success_rate = 0.0;
      clock_local = "";
      clock_server = "";
      ea_module_status = "INIT";
      broker_module_status = "—";
      internet_module_status = "—";
      market_module_status = "—";
      trading_perm_status = "—";
      recovery_module_status = "—";
      logging_module_status = "OK";
      analytics_module_status = "—";
      dashboard_module_status = "OK";
      gauge_risk = 0.0;
      gauge_dd = 0.0;
      gauge_wr = 0.0;
      gauge_pf = 0.0;
      gauge_rf = 0.0;
      gauge_speed = 0.0;
      gauge_conn = 0.0;
      gauge_health = 0.0;
      notify_banner = "";
      timeline_line0 = "";
      timeline_line1 = "";
      timeline_line2 = "";
      timeline_line3 = "";
      timeline_line4 = "";
      timeline_line5 = "";
      timeline_line6 = "";
      timeline_line7 = "";
      rpt_today_summary = "—";
      rpt_last_win = "—";
      rpt_last_loss = "—";
      rpt_largest_win = "—";
      rpt_largest_loss = "—";
      rpt_win_streak = "0";
      rpt_loss_streak = "0";
      rpt_session_result = "—";
      rpt_avg_trade_time = "—";
      rpt_alert_count = 0;
      rpt_last_alert = "—";
      ai_status = "NOT INITIALIZED";
      ai_version = "—";
      ai_engine = "—";
      ai_learning_status = "NOT INITIALIZED";
      ai_decision_status = "NOT INITIALIZED";
      ai_prediction_status = "NOT INITIALIZED";
      ai_confidence_status = "NOT INITIALIZED";
      ai_current_mode = "OFFLINE";
      ai_future_score = "Standby";
      ai_market_analyzer = "Standby";
      ai_trend_analyzer = "Standby";
      ai_volatility_analyzer = "Standby";
      ai_news_analyzer = "Standby";
      ai_recovery = "Standby";
      mkt_candle_cur = 0.0;
      mkt_candle_prev = 0.0;
      mkt_daily_range = 0.0;
      mkt_weekly_range = 0.0;
      mkt_volatility = "—";
      mkt_activity = "—";
      mi_instance_id = "—";
      mi_chart_id = 0;
      mi_running_instances = 0;
      mi_symbol = "—";
      mi_timeframe = "—";
      mi_instance_health = 0.0;
      mi_global_health = 0.0;
      mi_global_floating_profit = 0.0;
      mi_global_floating_loss = 0.0;
      mi_global_open_trades = 0;
      mi_active_symbols = 0;
      symbol = "";
      timeframe = "";
      session_id = 0;
      h4_cycle = 0;
      next_h4 = 0;
      h4_countdown_sec = 0;
      atr14 = 0.0;
      spread_points = 0.0;
      market_status = "—";
      internet_ok = false;
      broker_connected = false;
      trade_allowed = false;
      autotrading = false;
      recovery_ok = false;
      logging_ok = true;
      dashboard_ok = true;
      last_trade_result = "—";
      last_trade_pnl = 0.0;
      floating_profit = 0.0;
      floating_loss = 0.0;
      floating_pips = 0.0;
      be_status = "IDLE";
      trail_status = "IDLE";
      hedge_status = "N/A";
      trade_stage = "—";
      magic = 0;
      registry_count = 0;
      core_frozen = false;
      protection_ready = false;
      last_refresh_us = 0;
      terminal_memory_kb = 0;
      notification = "";
      valid = false;
      fingerprint = 0;
     }

   ulong ComputeFingerprint(void) const
     {
      ulong h = (ulong)running_trades * 31 + (ulong)pending_orders * 17;
      h ^= (ulong)((long)(equity * 100.0));
      h ^= (ulong)((long)(balance * 100.0));
      h ^= (ulong)((long)(floating_profit * 100.0));
      h ^= (ulong)((long)(floating_loss * 100.0));
      h ^= (ulong)((long)(today_net * 100.0));
      h ^= (ulong)((long)(current_dd_pct * 100.0));
      h ^= (ulong)((long)(spread_points * 10.0));
      h ^= (ulong)h4_countdown_sec;
      h ^= (ulong)session_id;
      h ^= (ulong)(broker_connected ? 1 : 0);
      h ^= (ulong)(autotrading ? 2 : 0);
      h ^= (ulong)total_trades * 13;
      h ^= (ulong)buy_trades * 7 + (ulong)sell_trades * 5;
      return h;
     }
  };

#endif // GM_SGM_DASHBOARD_SNAPSHOT_MQH
//+------------------------------------------------------------------+
