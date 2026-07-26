//+------------------------------------------------------------------+
//|                                        SGmOrderFlowResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_ORDER_FLOW_RESULT_MQH
#define GM_SGM_ORDER_FLOW_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "OrderFlowAIConstants.mqh"

struct SGmOrderFlowResult
  {
   datetime                stamped_at;
   string                  symbol;
   ulong                   session_id;
   ENUM_GM_OF_STATUS       status;

   // Order flow
   double                  order_flow_score;
   double                  participation_score;
   double                  directional_strength;
   double                  institutional_activity_index;
   double                  price_velocity;
   double                  tick_activity;
   double                  market_speed;
   string                  order_flow_report;

   // Global session
   ENUM_GM_OF_SESSION      active_session;
   bool                    session_open_flag;
   bool                    session_close_flag;
   bool                    overlap_active;
   double                  session_strength;
   double                  session_volatility;
   double                  session_liquidity;
   double                  session_momentum;
   double                  historical_session_success;
   string                  session_report;

   // Market energy
   double                  energy_score;
   double                  buying_energy;
   double                  selling_energy;
   double                  expansion_energy;
   double                  compression_energy;
   double                  momentum_energy;
   double                  trend_energy;
   string                  energy_direction;
   double                  energy_stability;
   string                  energy_report;

   // Personality
   ENUM_GM_OF_PERSONALITY  session_personality;
   bool                    best_goldmind_session;
   bool                    worst_goldmind_session;
   string                  personality_report;

   // Temperature
   ENUM_GM_OF_TEMPERATURE  market_temperature;
   double                  temperature_index;
   string                  temperature_explanation;
   string                  temperature_report;

   string                  center_status;
   string                  advisory_status;
   string                  insight;
   bool                    may_execute;
   bool                    may_modify_risk;
   bool                    from_cache;
   bool                    valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = "";
      session_id = 0;
      status = GM_OF_STATUS_IDLE;
      order_flow_score = participation_score = directional_strength = 0.0;
      institutional_activity_index = price_velocity = tick_activity = 0.0;
      market_speed = 0.0;
      order_flow_report = "";
      active_session = GM_OF_SESSION_UNKNOWN;
      session_open_flag = session_close_flag = overlap_active = false;
      session_strength = session_volatility = session_liquidity = 0.0;
      session_momentum = historical_session_success = 0.0;
      session_report = "";
      energy_score = buying_energy = selling_energy = 0.0;
      expansion_energy = compression_energy = momentum_energy = trend_energy = 0.0;
      energy_direction = energy_report = "";
      energy_stability = 0.0;
      session_personality = GM_OF_PERS_UNKNOWN;
      best_goldmind_session = worst_goldmind_session = false;
      personality_report = "";
      market_temperature = GM_OF_TEMP_UNKNOWN;
      temperature_index = 0.0;
      temperature_explanation = temperature_report = "";
      center_status = "Idle";
      advisory_status = GM_OF_ADVISORY;
      insight = "";
      may_execute = false;
      may_modify_risk = false;
      from_cache = false;
      valid = false;
     }
  };

#endif // GM_SGM_ORDER_FLOW_RESULT_MQH
//+------------------------------------------------------------------+
