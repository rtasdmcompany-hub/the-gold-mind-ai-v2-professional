//+------------------------------------------------------------------+
//|                      SGmDynamicConfidence.mqh                    |
//|  Multi-factor dynamic confidence snapshot — Phase 11E            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_DYNAMIC_CONFIDENCE_MQH
#define GM_SGM_DYNAMIC_CONFIDENCE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "Phase11EConstants.mqh"

struct SGmDynamicConfidence
  {
   datetime                 stamped_at;
   string                   symbol;
   ulong                    ticket;
   string                   comment;
   int                      level_index;
   bool                     is_buy_side;

   double                   buy_confidence;
   double                   sell_confidence;
   double                   trend_strength;
   double                   momentum_strength;
   double                   liquidity_score;
   double                   spread_health;
   double                   volatility_score;
   double                   news_risk;
   double                   session_strength;
   double                   broker_quality;
   double                   market_structure;
   double                   overall_ai_confidence;
   double                   decision_confidence;

   ENUM_GM_P11E_DECISION_BAND band;
   ENUM_GM_P11E_ACTION        action;
   ENUM_GM_P11E_HEALTH        health;
   ENUM_GM_P11E_PENDING_STATE pending_state;

   double                   original_lot;
   double                   current_lot;
   double                   target_lot;
   double                   lot_multiplier;
   string                   recommendation;
   string                   why;
   string                   market_evidence;
   string                   market_condition;
   double                   current_spread_pts;
   double                   current_atr;
   int                      frozen_count;
   int                      cancelled_count;
   int                      lot_modify_count;
   bool                     valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = "";
      ticket = 0;
      comment = "";
      level_index = 0;
      is_buy_side = true;
      buy_confidence = sell_confidence = 50.0;
      trend_strength = momentum_strength = liquidity_score = 50.0;
      spread_health = volatility_score = news_risk = 50.0;
      session_strength = broker_quality = market_structure = 50.0;
      overall_ai_confidence = decision_confidence = 50.0;
      band = GM_P11E_BAND_STRONG;
      action = GM_P11E_ACT_PASS;
      health = GM_P11E_HEALTH_OK;
      pending_state = GM_P11E_STATE_LIVE;
      original_lot = current_lot = target_lot = 0.0;
      lot_multiplier = 1.0;
      recommendation = "PASS";
      why = "";
      market_evidence = "";
      market_condition = "—";
      current_spread_pts = current_atr = 0.0;
      frozen_count = cancelled_count = lot_modify_count = 0;
      valid = false;
     }
  };

#endif // GM_SGM_DYNAMIC_CONFIDENCE_MQH
//+------------------------------------------------------------------+
