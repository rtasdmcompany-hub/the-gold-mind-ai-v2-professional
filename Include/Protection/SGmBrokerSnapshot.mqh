//+------------------------------------------------------------------+
//|                                          SGmBrokerSnapshot.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_BROKER_SNAPSHOT_MQH
#define GM_SGM_BROKER_SNAPSHOT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file SGmBrokerSnapshot.mqh
/// @brief Broker / symbol trading constraints snapshot.

struct SGmBrokerSnapshot
  {
   string   symbol;
   datetime stamped_at;
   long     stops_level;
   long     freeze_level;
   long     spread;
   double   tick_size;
   double   tick_value;
   double   point;
   int      digits;
   double   lot_step;
   double   lot_min;
   double   lot_max;
   bool     valid;

   void Reset(void)
     {
      symbol = "";
      stamped_at = 0;
      stops_level = 0;
      freeze_level = 0;
      spread = 0;
      tick_size = 0.0;
      tick_value = 0.0;
      point = 0.0;
      digits = 0;
      lot_step = 0.0;
      lot_min = 0.0;
      lot_max = 0.0;
      valid = false;
     }
  };

#endif // GM_SGM_BROKER_SNAPSHOT_MQH
//+------------------------------------------------------------------+
