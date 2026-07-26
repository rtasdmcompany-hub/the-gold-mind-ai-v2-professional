//+------------------------------------------------------------------+
//|                                 SGmSessionJournalRecord.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_SESSION_JOURNAL_RECORD_MQH
#define GM_SGM_SESSION_JOURNAL_RECORD_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

struct SGmSessionJournalRecord
  {
   ulong    session_number;
   datetime start_time;
   datetime end_time;
   int      generated_levels;
   int      completed_trades;
   int      winning_trades;
   int      losing_trades;
   double   net_profit;
   double   win_rate;
   double   drawdown;
   long     magic;
   string   symbol;
   bool     used;

   void Reset(void)
     {
      session_number = 0;
      start_time = 0;
      end_time = 0;
      generated_levels = 0;
      completed_trades = 0;
      winning_trades = 0;
      losing_trades = 0;
      net_profit = 0.0;
      win_rate = 0.0;
      drawdown = 0.0;
      magic = 0;
      symbol = "";
      used = false;
     }
  };

#endif // GM_SGM_SESSION_JOURNAL_RECORD_MQH
//+------------------------------------------------------------------+
