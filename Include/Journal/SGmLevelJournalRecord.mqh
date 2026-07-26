//+------------------------------------------------------------------+
//|                                   SGmLevelJournalRecord.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_LEVEL_JOURNAL_RECORD_MQH
#define GM_SGM_LEVEL_JOURNAL_RECORD_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

struct SGmLevelJournalRecord
  {
   string   level_id;
   string   side;
   double   calculated_price;
   datetime activation_time;
   bool     first_sl;
   bool     second_sl;
   bool     take_profit;
   bool     completed;
   bool     failed;
   bool     expired;
   ulong    session_id;
   long     magic;
   string   symbol;
   bool     used;

   void Reset(void)
     {
      level_id = "";
      side = "";
      calculated_price = 0.0;
      activation_time = 0;
      first_sl = false;
      second_sl = false;
      take_profit = false;
      completed = false;
      failed = false;
      expired = false;
      session_id = 0;
      magic = 0;
      symbol = "";
      used = false;
     }
  };

#endif // GM_SGM_LEVEL_JOURNAL_RECORD_MQH
//+------------------------------------------------------------------+
