//+------------------------------------------------------------------+
//|                                        SGmAccountSnapshot.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_ACCOUNT_SNAPSHOT_MQH
#define GM_SGM_ACCOUNT_SNAPSHOT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file SGmAccountSnapshot.mqh
/// @brief Real-time account metrics for Capital Protection.

struct SGmAccountSnapshot
  {
   datetime stamped_at;
   double   balance;
   double   equity;
   double   free_margin;
   double   margin;
   double   margin_level;
   double   floating_profit;
   double   floating_loss;
   double   floating_pnl;
   double   daily_profit;
   double   daily_loss;
   double   daily_pnl;
   bool     valid;

   void Reset(void)
     {
      stamped_at = 0;
      balance = 0.0;
      equity = 0.0;
      free_margin = 0.0;
      margin = 0.0;
      margin_level = 0.0;
      floating_profit = 0.0;
      floating_loss = 0.0;
      floating_pnl = 0.0;
      daily_profit = 0.0;
      daily_loss = 0.0;
      daily_pnl = 0.0;
      valid = false;
     }
  };

#endif // GM_SGM_ACCOUNT_SNAPSHOT_MQH
//+------------------------------------------------------------------+
