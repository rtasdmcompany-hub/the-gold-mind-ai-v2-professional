//+------------------------------------------------------------------+
//|                                         SGmForecastResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_FORECAST_RESULT_MQH
#define GM_SGM_FORECAST_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ForecastingAIConstants.mqh"

struct SGmForecastResult
  {
   datetime               stamped_at;
   string                 symbol;
   ulong                  session_id;
   string                 forecast_id;
   ENUM_GM_FCST_STATUS    status;

   // Market forecast
   ENUM_GM_FCST_OUTLOOK   outlook;
   double                 trend_probability;
   string                 volatility_expectation;
   double                 forecast_confidence;
   string                 market_forecast_report;

   // Scenarios
   double                 scn_continuation;
   double                 scn_range;
   double                 scn_vol_expansion;
   double                 scn_reversal;
   ENUM_GM_FCST_SCENARIO  dominant_scenario;
   string                 scenario_report;

   // Probability matrix
   double                 prob_trend;
   double                 prob_volatility;
   double                 prob_recovery;
   double                 prob_risk;
   double                 prob_stability;
   string                 probability_matrix;

   // Transition
   ENUM_GM_FCST_REGIME    regime_from;
   ENUM_GM_FCST_REGIME    regime_to;
   bool                   transition_detected;
   double                 transition_confidence;
   string                 transition_alert;

   // Accuracy
   double                 accuracy_score;
   double                 accuracy_improvement;
   int                    correct_forecasts;
   int                    incorrect_forecasts;
   string                 accuracy_report;

   // Explanation / match
   string                 technical_summary;
   string                 ai_explanation;
   string                 historical_match;
   string                 scenario_probability_map;

   string                 center_status;
   string                 advisory_status;
   string                 insight;
   bool                   may_execute;
   bool                   may_modify_strategy;
   bool                   from_cache;
   bool                   valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = forecast_id = "";
      session_id = 0;
      status = GM_FCST_STATUS_IDLE;
      outlook = GM_FCST_OUTLOOK_UNKNOWN;
      trend_probability = forecast_confidence = 0.0;
      volatility_expectation = market_forecast_report = "";
      scn_continuation = scn_range = scn_vol_expansion = scn_reversal = 0.0;
      dominant_scenario = GM_FCST_SCN_UNKNOWN;
      scenario_report = "";
      prob_trend = prob_volatility = prob_recovery = prob_risk = prob_stability = 0.0;
      probability_matrix = "";
      regime_from = regime_to = GM_FCST_REGIME_UNKNOWN;
      transition_detected = false;
      transition_confidence = 0.0;
      transition_alert = "";
      accuracy_score = accuracy_improvement = 0.0;
      correct_forecasts = incorrect_forecasts = 0;
      accuracy_report = "";
      technical_summary = ai_explanation = historical_match = scenario_probability_map = "";
      center_status = "Idle";
      advisory_status = GM_FCST_ADVISORY;
      insight = "";
      may_execute = false;
      may_modify_strategy = false;
      from_cache = false;
      valid = false;
     }
  };

#endif // GM_SGM_FORECAST_RESULT_MQH
//+------------------------------------------------------------------+
