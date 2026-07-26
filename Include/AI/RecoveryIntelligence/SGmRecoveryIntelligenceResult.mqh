//+------------------------------------------------------------------+
//|                            SGmRecoveryIntelligenceResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_RECOVERY_INTELLIGENCE_RESULT_MQH
#define GM_SGM_RECOVERY_INTELLIGENCE_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "RecoveryIntelligenceConstants.mqh"

struct SGmRecoveryIntelligenceResult
  {
   datetime              stamped_at;
   string                symbol;
   ulong                 session_id;
   ENUM_GM_RI_STATUS     status;

   // Recovery intelligence
   double                recovery_attempts;
   double                recovery_success_rate;
   double                recovery_duration;
   double                recovery_efficiency;
   double                recovery_drawdown;
   double                recovery_cost;
   double                recovery_probability;
   double                recovery_intelligence_score;
   double                recovery_confidence;
   double                recovery_health_index;
   ENUM_GM_RI_HEALTH     recovery_health;
   string                recovery_report;

   // Hedge intelligence
   double                hedge_frequency;
   double                hedge_success;
   double                hedge_duration;
   double                net_recovery;
   double                gross_recovery;
   double                recovery_stability;
   double                hedge_quality_score;
   double                hedge_effectiveness;
   string                hedge_report;

   // Loss minimization
   double                average_loss;
   double                maximum_loss;
   double                average_recovery;
   double                recovery_speed;
   double                drawdown_stability;
   double                capital_preservation;
   double                loss_control_score;
   double                capital_protection_rating;
   string                loss_report;

   // Second attempt
   double                first_sl_rate;
   double                second_attempt_rate;
   double                second_attempt_success;
   double                final_failure_rate;
   double                historical_recovery_pct;
   double                recovery_time_sec;
   string                recovery_conditions;
   string                second_attempt_report;

   // Patterns
   ENUM_GM_RI_PATTERN    primary_pattern;
   string                pattern_library;
   string                pattern_report;

   // Recommendation
   string                ai_recovery_recommendation;
   string                center_status;
   string                advisory_status;
   string                insight;
   bool                  may_execute;
   bool                  may_modify_risk;
   bool                  from_cache;
   bool                  valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = "";
      session_id = 0;
      status = GM_RI_STATUS_IDLE;
      recovery_attempts = recovery_success_rate = recovery_duration = 0.0;
      recovery_efficiency = recovery_drawdown = recovery_cost = 0.0;
      recovery_probability = recovery_intelligence_score = 0.0;
      recovery_confidence = recovery_health_index = 0.0;
      recovery_health = GM_RI_HEALTH_UNKNOWN;
      recovery_report = "";
      hedge_frequency = hedge_success = hedge_duration = 0.0;
      net_recovery = gross_recovery = recovery_stability = 0.0;
      hedge_quality_score = hedge_effectiveness = 0.0;
      hedge_report = "";
      average_loss = maximum_loss = average_recovery = 0.0;
      recovery_speed = drawdown_stability = capital_preservation = 0.0;
      loss_control_score = capital_protection_rating = 0.0;
      loss_report = "";
      first_sl_rate = second_attempt_rate = second_attempt_success = 0.0;
      final_failure_rate = historical_recovery_pct = recovery_time_sec = 0.0;
      recovery_conditions = second_attempt_report = "";
      primary_pattern = GM_RI_PAT_UNKNOWN;
      pattern_library = pattern_report = "";
      ai_recovery_recommendation = "";
      center_status = "Idle";
      advisory_status = GM_RI_ADVISORY;
      insight = "";
      may_execute = false;
      may_modify_risk = false;
      from_cache = false;
      valid = false;
     }
  };

#endif // GM_SGM_RECOVERY_INTELLIGENCE_RESULT_MQH
//+------------------------------------------------------------------+
