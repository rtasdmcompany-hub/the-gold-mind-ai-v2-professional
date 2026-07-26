//+------------------------------------------------------------------+
//|                                  SGmAIValidationResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_AI_VALIDATION_RESULT_MQH
#define GM_SGM_AI_VALIDATION_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "AIValidationConstants.mqh"

struct SGmAIValidationResult
  {
   datetime                stamped_at;
   string                  symbol;
   ulong                   session_id;
   ENUM_GM_AIVAL_STATUS    status;

   // Component accuracies
   double                  trend_accuracy;
   double                  volatility_accuracy;
   double                  news_accuracy;
   double                  confidence_accuracy;
   double                  market_quality_accuracy;
   double                  strategy_match_accuracy;
   double                  similarity_accuracy;
   double                  recommendation_accuracy;
   double                  pattern_accuracy;
   double                  prediction_accuracy;

   // Aggregate
   double                  ai_accuracy;
   double                  forward_test_score;
   double                  backtest_score;
   double                  certification_score;
   double                  learning_stability;
   double                  ai_health_score;
   double                  historical_correlation;
   double                  model_stability;

   // Backtest / Gold Mind understanding proxies
   int                     h4_sessions_evaluated;
   int                     wins_observed;
   int                     losses_observed;
   double                  first_attempt_proxy;
   double                  second_attempt_proxy;
   double                  recovery_proxy;
   double                  be_proxy;
   double                  sl_model_proxy;

   // Drift
   ENUM_GM_AIVAL_DRIFT     drift_type;
   double                  drift_magnitude;
   bool                    drift_alert;
   string                  drift_message;

   // Certification
   ENUM_GM_AIVAL_GRADE     reliability_grade;
   string                  cert_summary;
   string                  forward_status;
   string                  backtest_status;

   // Reporting stubs
   string                  daily_report_note;
   string                  weekly_report_note;
   string                  monthly_report_note;

   double                  confidence;
   string                  insight;
   bool                    may_modify_strategy; // ALWAYS false
   bool                    valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = "";
      session_id = 0;
      status = GM_AIVAL_STATUS_IDLE;
      trend_accuracy = volatility_accuracy = news_accuracy = 50.0;
      confidence_accuracy = market_quality_accuracy = 50.0;
      strategy_match_accuracy = similarity_accuracy = 50.0;
      recommendation_accuracy = pattern_accuracy = prediction_accuracy = 50.0;
      ai_accuracy = forward_test_score = backtest_score = 0.0;
      certification_score = learning_stability = ai_health_score = 0.0;
      historical_correlation = model_stability = 50.0;
      h4_sessions_evaluated = wins_observed = losses_observed = 0;
      first_attempt_proxy = second_attempt_proxy = recovery_proxy = 50.0;
      be_proxy = sl_model_proxy = 50.0;
      drift_type = GM_AIVAL_DRIFT_NONE;
      drift_magnitude = 0.0;
      drift_alert = false;
      drift_message = "";
      reliability_grade = GM_AIVAL_GRADE_UNKNOWN;
      cert_summary = forward_status = backtest_status = "";
      daily_report_note = weekly_report_note = monthly_report_note = "";
      confidence = 0.0;
      insight = "";
      may_modify_strategy = false;
      valid = false;
     }
  };

#endif // GM_SGM_AI_VALIDATION_RESULT_MQH
//+------------------------------------------------------------------+
