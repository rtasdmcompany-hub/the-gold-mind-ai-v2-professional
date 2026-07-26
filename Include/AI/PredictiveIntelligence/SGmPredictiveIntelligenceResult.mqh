//+------------------------------------------------------------------+
//|                            SGmPredictiveIntelligenceResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_PREDICTIVE_INTELLIGENCE_RESULT_MQH
#define GM_SGM_PREDICTIVE_INTELLIGENCE_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "PredictiveIntelligenceConstants.mqh"

struct SGmPredictiveIntelligenceResult
  {
   datetime                 stamped_at;
   string                   symbol;
   ulong                    session_id;
   ENUM_GM_PRED_STATUS      status;

   // Predictive engine
   double                   prediction_confidence;
   double                   forecast_reliability;
   double                   scenario_probability;   // dominant scenario %
   string                   predictive_report;

   // Scenario simulator
   double                   scn_bull_cont;
   double                   scn_bear_cont;
   double                   scn_range;
   double                   scn_breakout;
   double                   scn_false_breakout;
   double                   scn_high_vol;
   double                   scn_low_vol;
   double                   scn_recovery;
   ENUM_GM_PRED_SCENARIO    dominant_scenario;
   string                   scenario_report;

   // Probability engine
   double                   bullish_probability;
   double                   bearish_probability;
   double                   continuation_probability;
   double                   reversal_probability;
   double                   atr_expansion_probability;
   double                   volatility_probability;
   double                   liquidity_probability;
   double                   recovery_probability;
   double                   overall_probability_score;
   double                   confidence_interval_lo;
   double                   confidence_interval_hi;
   string                   probability_report;

   // Market path
   string                   expected_direction;
   double                   expected_range;
   double                   expected_momentum;
   double                   expected_atr;
   double                   expected_energy;
   double                   expected_liquidity;
   string                   expected_session_behaviour;
   string                   expected_recovery_conditions;
   string                   path_report;

   // Historical simulation
   double                   historical_match;
   double                   historical_success_rate;
   double                   historical_failure_rate;
   double                   pattern_frequency;
   double                   historical_probability;
   double                   historical_reliability;
   string                   historical_report;

   string                   ai_prediction_summary;
   string                   center_status;
   string                   advisory_status;
   string                   insight;
   bool                     may_execute;
   bool                     may_modify_risk;
   bool                     from_cache;
   bool                     valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = "";
      session_id = 0;
      status = GM_PRED_STATUS_IDLE;
      prediction_confidence = forecast_reliability = scenario_probability = 0.0;
      predictive_report = "";
      scn_bull_cont = scn_bear_cont = scn_range = scn_breakout = 0.0;
      scn_false_breakout = scn_high_vol = scn_low_vol = scn_recovery = 0.0;
      dominant_scenario = GM_PRED_SCN_UNKNOWN;
      scenario_report = "";
      bullish_probability = bearish_probability = 0.0;
      continuation_probability = reversal_probability = 0.0;
      atr_expansion_probability = volatility_probability = 0.0;
      liquidity_probability = recovery_probability = 0.0;
      overall_probability_score = confidence_interval_lo = confidence_interval_hi = 0.0;
      probability_report = "";
      expected_direction = expected_session_behaviour = expected_recovery_conditions = "";
      expected_range = expected_momentum = expected_atr = 0.0;
      expected_energy = expected_liquidity = 0.0;
      path_report = "";
      historical_match = historical_success_rate = historical_failure_rate = 0.0;
      pattern_frequency = historical_probability = historical_reliability = 0.0;
      historical_report = "";
      ai_prediction_summary = "";
      center_status = "Idle";
      advisory_status = GM_PRED_ADVISORY;
      insight = "";
      may_execute = false;
      may_modify_risk = false;
      from_cache = false;
      valid = false;
     }
  };

#endif // GM_SGM_PREDICTIVE_INTELLIGENCE_RESULT_MQH
//+------------------------------------------------------------------+
