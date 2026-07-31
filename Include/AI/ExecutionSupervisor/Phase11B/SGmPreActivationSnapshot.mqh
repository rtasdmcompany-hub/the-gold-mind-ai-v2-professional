//+------------------------------------------------------------------+
//|                      SGmPreActivationSnapshot.mqh                |
//|     Pre-activation analysis snapshot — READ by supervisor only   |
//+------------------------------------------------------------------+
#ifndef GM_SGM_PRE_ACTIVATION_SNAPSHOT_MQH
#define GM_SGM_PRE_ACTIVATION_SNAPSHOT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "Phase11BConstants.mqh"

struct SGmPreActivationSnapshot
  {
   datetime           stamped_at;
   string             symbol;
   ulong              ticket;
   string             comment;
   int                level_index;

   double             market_confidence;
   double             trend_strength;
   double             momentum;
   double             liquidity;
   double             spread_score;
   double             volatility;
   double             atr_expansion;
   double             atr_compression;
   double             tick_speed;
   double             price_acceleration;
   double             broker_quality;
   double             slippage_probability;
   double             false_breakout_probability;
   double             session_strength;
   double             news_risk;
   double             market_structure;
   double             execution_confidence;
   double             ai_confidence;

   ENUM_GM_P11B_DECISION_BAND band;
   ENUM_GM_P11B_ACTION        action;
   double             lot_multiplier;
   string             recommendation;
   string             why;
   ENUM_GM_P11B_HEALTH health;

   int                frozen_count;
   int                cancelled_count;
   double             current_spread_pts;
   double             current_atr;
   string             market_condition;
   double             execution_score;
   bool               valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = "";
      ticket = 0;
      comment = "";
      level_index = 0;
      market_confidence = trend_strength = momentum = liquidity = 0.0;
      spread_score = volatility = atr_expansion = atr_compression = 0.0;
      tick_speed = price_acceleration = broker_quality = 0.0;
      slippage_probability = false_breakout_probability = 0.0;
      session_strength = news_risk = market_structure = 0.0;
      execution_confidence = ai_confidence = 0.0;
      band = GM_P11B_BAND_STRONG;
      action = GM_P11B_ACT_NORMAL;
      lot_multiplier = 1.0;
      recommendation = "NORMAL";
      why = "";
      health = GM_P11B_HEALTH_OK;
      frozen_count = cancelled_count = 0;
      current_spread_pts = current_atr = 0.0;
      market_condition = "—";
      execution_score = 0.0;
      valid = false;
     }
  };

#endif // GM_SGM_PRE_ACTIVATION_SNAPSHOT_MQH
//+------------------------------------------------------------------+
