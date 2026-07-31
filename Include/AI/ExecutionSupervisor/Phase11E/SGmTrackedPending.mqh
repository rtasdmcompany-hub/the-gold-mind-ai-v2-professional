//+------------------------------------------------------------------+
//|                       SGmTrackedPending.mqh                      |
//|  Live pending registry for continuous Phase 11E monitoring       |
//|  Price / SL / TP are immutable once captured from Engine         |
//+------------------------------------------------------------------+
#ifndef GM_SGM_TRACKED_PENDING_MQH
#define GM_SGM_TRACKED_PENDING_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "Phase11EConstants.mqh"

struct SGmTrackedPending
  {
   bool                     used;
   ulong                    ticket;
   string                   comment;
   int                      level_index;
   ENUM_ORDER_TYPE          order_type;
   bool                     is_buy_side;

   // Immutable Engine geometry — AI MUST NEVER change these
   double                   frozen_price;
   double                   frozen_sl;
   double                   frozen_tp;

   double                   original_lot;
   double                   current_lot;
   double                   last_target_lot;

   double                   last_decision_confidence;
   double                   last_overall_confidence;
   ENUM_GM_P11E_ACTION      last_action;
   ENUM_GM_P11E_PENDING_STATE state;
   string                   last_why;

   datetime                 placed_at;
   datetime                 last_eval_at;
   datetime                 frozen_at;
   int                      lot_modify_count;
   bool                     activated_readonly;

   void Reset(void)
     {
      used = false;
      ticket = 0;
      comment = "";
      level_index = 0;
      order_type = ORDER_TYPE_BUY_LIMIT;
      is_buy_side = true;
      frozen_price = frozen_sl = frozen_tp = 0.0;
      original_lot = current_lot = last_target_lot = 0.0;
      last_decision_confidence = last_overall_confidence = 0.0;
      last_action = GM_P11E_ACT_PASS;
      state = GM_P11E_STATE_LIVE;
      last_why = "";
      placed_at = last_eval_at = frozen_at = 0;
      lot_modify_count = 0;
      activated_readonly = false;
     }
  };

#endif // GM_SGM_TRACKED_PENDING_MQH
//+------------------------------------------------------------------+
