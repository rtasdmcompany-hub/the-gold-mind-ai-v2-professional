//+------------------------------------------------------------------+
//|                                      SGmEtjTradeRecord.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_ETJ_TRADE_RECORD_MQH
#define GM_SGM_ETJ_TRADE_RECORD_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "TradeJournalConstants.mqh"

struct SGmEtjTradeRecord
  {
   ulong              trade_id;
   ulong              ticket;
   ulong              position_id;
   long               magic;
   string             symbol;
   string             level_tag;
   ENUM_GM_ETJ_SIDE   side;
   ENUM_GM_ETJ_STATUS status;
   datetime           h4_candle_time;
   datetime           open_time;
   datetime           close_time;
   double             entry_price;
   double             exit_price;
   double             atr_value;
   double             stop_loss;
   double             take_profit;
   double             risk_pct;
   double             lot_size;
   int                duration_sec;
   double             spread;
   double             commission;
   double             swap;
   double             profit_loss;
   string             recovery_status;
   bool               break_even;
   bool               partial_close;
   bool               trailing;
   string             market_session;
   string             news_environment;
   double             ai_confidence;
   string             screenshot_ref;   // future architecture
   bool               used;

   void Reset(void)
     {
      trade_id = ticket = position_id = 0;
      magic = 0;
      symbol = level_tag = "";
      side = GM_ETJ_SIDE_BUY;
      status = GM_ETJ_ST_OPEN;
      h4_candle_time = open_time = close_time = 0;
      entry_price = exit_price = atr_value = 0.0;
      stop_loss = take_profit = risk_pct = lot_size = 0.0;
      duration_sec = 0;
      spread = commission = swap = profit_loss = 0.0;
      recovery_status = "None";
      break_even = partial_close = trailing = false;
      market_session = "—";
      news_environment = "Normal";
      ai_confidence = 0.0;
      screenshot_ref = GM_ETJ_SCREENSHOT_ARCH;
      used = false;
     }
  };

struct SGmEtjTimelineEvent
  {
   ulong            trade_id;
   ENUM_GM_ETJ_EVENT event_type;
   datetime         stamped_at;
   string           detail;
   double           price;
   bool             used;

   void Reset(void)
     {
      trade_id = 0;
      event_type = GM_ETJ_EV_NOTE;
      stamped_at = 0;
      detail = "";
      price = 0.0;
      used = false;
     }
  };

#endif // GM_SGM_ETJ_TRADE_RECORD_MQH
//+------------------------------------------------------------------+
