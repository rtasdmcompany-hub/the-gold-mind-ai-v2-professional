//+------------------------------------------------------------------+
//|                                   SGmTradeJournalRecord.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_TRADE_JOURNAL_RECORD_MQH
#define GM_SGM_TRADE_JOURNAL_RECORD_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

struct SGmTradeJournalRecord
  {
   ulong    trade_id;
   long     magic;
   string   symbol;
   string   side;            // BUY / SELL
   double   lot_size;
   double   entry_price;
   double   stop_loss;
   double   take_profit;
   datetime open_time;
   datetime close_time;
   double   duration_sec;
   double   profit_loss;
   double   pips;
   string   result;          // WIN / LOSS / OPEN
   string   trade_stage;
   int      attempt_number;
   ulong    session_id;
   bool     is_open;
   bool     is_recovery;
   bool     used;

   void Reset(void)
     {
      trade_id = 0;
      magic = 0;
      symbol = "";
      side = "";
      lot_size = 0.0;
      entry_price = 0.0;
      stop_loss = 0.0;
      take_profit = 0.0;
      open_time = 0;
      close_time = 0;
      duration_sec = 0.0;
      profit_loss = 0.0;
      pips = 0.0;
      result = "";
      trade_stage = "";
      attempt_number = 1;
      session_id = 0;
      is_open = false;
      is_recovery = false;
      used = false;
     }
  };

#endif // GM_SGM_TRADE_JOURNAL_RECORD_MQH
//+------------------------------------------------------------------+
