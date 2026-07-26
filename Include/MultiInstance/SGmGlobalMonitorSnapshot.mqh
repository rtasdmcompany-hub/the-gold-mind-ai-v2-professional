//+------------------------------------------------------------------+
//|                                  SGmGlobalMonitorSnapshot.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_GLOBAL_MONITOR_SNAPSHOT_MQH
#define GM_SGM_GLOBAL_MONITOR_SNAPSHOT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file SGmGlobalMonitorSnapshot.mqh
/// @brief Aggregated multi-instance monitor (READ-ONLY).

struct SGmGlobalMonitorSnapshot
  {
   datetime stamped_at;
   int      total_instances;
   int      active_symbols;
   int      total_open_trades;
   int      total_pending_orders;
   double   overall_floating_profit;
   double   overall_floating_loss;
   double   overall_equity;
   double   overall_risk_pct;
   double   overall_drawdown_pct;
   double   global_health;
   string   local_instance_id;
   long     local_chart_id;
   string   local_symbol;
   string   local_timeframe;
   double   local_health;
   string   local_status;
   ulong    sync_us;
   bool     valid;

   void Reset(void)
     {
      stamped_at = 0;
      total_instances = 0;
      active_symbols = 0;
      total_open_trades = 0;
      total_pending_orders = 0;
      overall_floating_profit = 0.0;
      overall_floating_loss = 0.0;
      overall_equity = 0.0;
      overall_risk_pct = 0.0;
      overall_drawdown_pct = 0.0;
      global_health = 0.0;
      local_instance_id = "";
      local_chart_id = 0;
      local_symbol = "";
      local_timeframe = "";
      local_health = 0.0;
      local_status = "—";
      sync_us = 0;
      valid = false;
     }
  };

#endif // GM_SGM_GLOBAL_MONITOR_SNAPSHOT_MQH
//+------------------------------------------------------------------+
