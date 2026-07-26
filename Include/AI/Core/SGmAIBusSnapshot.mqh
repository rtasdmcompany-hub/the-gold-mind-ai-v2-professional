//+------------------------------------------------------------------+
//|                                           SGmAIBusSnapshot.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_AI_BUS_SNAPSHOT_MQH
#define GM_SGM_AI_BUS_SNAPSHOT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file SGmAIBusSnapshot.mqh
/// @brief Aggregated observation payload for AI Data Bus (no trade handles).

struct SGmAIBusSnapshot
  {
   datetime stamped_at;
   string   symbol;
   long     magic;
   ulong    session_id;
   datetime h4_cycle;
   double   bid;
   double   ask;
   double   spread_points;
   double   atr14;
   double   balance;
   double   equity;
   double   floating_profit;
   double   floating_loss;
   double   current_dd_pct;
   double   maximum_dd_pct;
   double   overall_win_rate;
   double   profit_factor;
   double   recovery_factor;
   double   total_net;
   int      open_positions;
   int      pending_orders;
   int      registry_count;
   bool     broker_connected;
   bool     trade_allowed;
   bool     recovery_ok;
   bool     analytics_valid;
   bool     valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = "";
      magic = 0;
      session_id = 0;
      h4_cycle = 0;
      bid = 0.0;
      ask = 0.0;
      spread_points = 0.0;
      atr14 = 0.0;
      balance = 0.0;
      equity = 0.0;
      floating_profit = 0.0;
      floating_loss = 0.0;
      current_dd_pct = 0.0;
      maximum_dd_pct = 0.0;
      overall_win_rate = 0.0;
      profit_factor = 0.0;
      recovery_factor = 0.0;
      total_net = 0.0;
      open_positions = 0;
      pending_orders = 0;
      registry_count = 0;
      broker_connected = false;
      trade_allowed = false;
      recovery_ok = false;
      analytics_valid = false;
      valid = false;
     }
  };

#endif // GM_SGM_AI_BUS_SNAPSHOT_MQH
//+------------------------------------------------------------------+
