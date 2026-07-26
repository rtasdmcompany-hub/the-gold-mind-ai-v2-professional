//+------------------------------------------------------------------+
//|                               SGmMarketIntelligenceResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_MARKET_INTELLIGENCE_RESULT_MQH
#define GM_SGM_MARKET_INTELLIGENCE_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "MarketIntelligenceConstants.mqh"

struct SGmMarketIntelligenceResult
  {
   datetime               stamped_at;
   string                 symbol;
   ulong                  session_id;
   ENUM_GM_MI_STATUS      status;

   // Market intelligence core
   double                 market_structure_score;
   double                 trend_strength;
   double                 momentum_index;
   double                 liquidity_score;
   double                 volatility_score;
   double                 atr_expansion_score;
   double                 compression_score;
   double                 breakout_probability;
   double                 reversal_probability;
   double                 market_energy;
   string                 market_intelligence_report;

   // Institutional
   ENUM_GM_MI_INST_PHASE  institutional_phase;
   double                 institutional_bias;       // -100..100
   double                 accumulation_score;
   double                 distribution_score;
   double                 stop_hunt_probability;
   double                 liquidity_grab_probability;
   double                 false_breakout_probability;
   double                 institutional_momentum;
   string                 institutional_report;

   // Smart structure
   ENUM_GM_MI_STRUCTURE   structure_type;
   bool                   higher_highs;
   bool                   higher_lows;
   bool                   lower_highs;
   bool                   lower_lows;
   bool                   trend_continuation;
   bool                   trend_weakness;
   bool                   range_formation;
   bool                   break_of_structure;
   bool                   change_of_character;
   double                 swing_strength;
   double                 structure_quality;
   string                 structure_report;

   // Momentum detail
   double                 momentum_strength;
   double                 momentum_direction;       // -100..100
   double                 momentum_acceleration;
   double                 momentum_exhaustion;
   double                 momentum_stability;
   double                 momentum_confidence;
   string                 momentum_report;

   // Liquidity detail
   double                 high_liquidity_score;
   double                 low_liquidity_score;
   bool                   liquidity_sweep;
   double                 liquidity_void_score;
   double                 session_liquidity;
   double                 spread_stability;
   double                 market_participation;
   string                 liquidity_report;

   // Dashboard / status
   string                 institutional_activity;
   string                 intelligence_status;
   string                 advisory_status;
   string                 insight;
   bool                   may_execute;
   bool                   may_modify_risk;
   bool                   from_cache;
   bool                   valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = "";
      session_id = 0;
      status = GM_MI_STATUS_IDLE;
      market_structure_score = trend_strength = momentum_index = 0.0;
      liquidity_score = volatility_score = atr_expansion_score = 0.0;
      compression_score = breakout_probability = reversal_probability = 0.0;
      market_energy = 0.0;
      market_intelligence_report = "";
      institutional_phase = GM_MI_INST_UNKNOWN;
      institutional_bias = accumulation_score = distribution_score = 0.0;
      stop_hunt_probability = liquidity_grab_probability = 0.0;
      false_breakout_probability = institutional_momentum = 0.0;
      institutional_report = "";
      structure_type = GM_MI_STRUCT_UNKNOWN;
      higher_highs = higher_lows = lower_highs = lower_lows = false;
      trend_continuation = trend_weakness = range_formation = false;
      break_of_structure = change_of_character = false;
      swing_strength = structure_quality = 0.0;
      structure_report = "";
      momentum_strength = momentum_direction = momentum_acceleration = 0.0;
      momentum_exhaustion = momentum_stability = momentum_confidence = 0.0;
      momentum_report = "";
      high_liquidity_score = low_liquidity_score = 0.0;
      liquidity_sweep = false;
      liquidity_void_score = session_liquidity = 0.0;
      spread_stability = market_participation = 0.0;
      liquidity_report = "";
      institutional_activity = intelligence_status = "";
      advisory_status = GM_MI_ADVISORY;
      insight = "";
      may_execute = false;
      may_modify_risk = false;
      from_cache = false;
      valid = false;
     }
  };

#endif // GM_SGM_MARKET_INTELLIGENCE_RESULT_MQH
//+------------------------------------------------------------------+
