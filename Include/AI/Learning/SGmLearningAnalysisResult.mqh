//+------------------------------------------------------------------+
//|                                   SGmLearningAnalysisResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_LEARNING_ANALYSIS_RESULT_MQH
#define GM_SGM_LEARNING_ANALYSIS_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "LearningAIConstants.mqh"

struct SGmLearningCalibration
  {
   double confidence_bias;      // advisory calibration only
   double env_caution_bias;
   double reco_quality_bias;
   int    cycles;

   void Reset(void)
     {
      confidence_bias = env_caution_bias = reco_quality_bias = 0.0;
      cycles = 0;
     }
  };

struct SGmLearningAnalysisResult
  {
   datetime                   stamped_at;
   string                     symbol;
   ulong                      session_id;
   ENUM_GM_LEARN_STATUS       status;

   // Study inputs (counts)
   int                        trades_studied;
   int                        wins_studied;
   int                        losses_studied;
   int                        h4_sessions_studied;
   int                        patterns_detected;
   int                        knowledge_entries;
   int                        learning_cycles;

   // Accuracies / progress
   double                     learning_progress;
   double                     prediction_accuracy;
   double                     confidence_accuracy;
   double                     pattern_accuracy;
   double                     recommendation_accuracy;
   double                     historical_success_rate;
   double                     learning_progress_pct;
   double                     historical_correlation;
   double                     knowledge_growth;
   double                     knowledge_score;

   ENUM_GM_LEARN_EXPERIENCE   experience;
   string                     knowledge_version;
   string                     last_pattern;
   datetime                   last_cycle_at;
   SGmLearningCalibration     calibration;

   // Gold Mind specific observations (analytical)
   int                        sl_events_observed;
   int                        be_events_proxy;
   int                        recovery_proxy;
   int                        second_attempt_proxy;

   double                     confidence;
   string                     insight;
   bool                       may_modify_strategy; // ALWAYS false
   bool                       valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = "";
      session_id = 0;
      status = GM_LEARN_STATUS_IDLE;
      trades_studied = wins_studied = losses_studied = 0;
      h4_sessions_studied = patterns_detected = knowledge_entries = 0;
      learning_cycles = 0;
      learning_progress = prediction_accuracy = confidence_accuracy = 0.0;
      pattern_accuracy = recommendation_accuracy = historical_success_rate = 0.0;
      learning_progress_pct = historical_correlation = knowledge_growth = 0.0;
      knowledge_score = 0.0;
      experience = GM_LEARN_XP_NOVICE;
      knowledge_version = GM_LEARN_KB_VERSION;
      last_pattern = "";
      last_cycle_at = 0;
      calibration.Reset();
      sl_events_observed = be_events_proxy = 0;
      recovery_proxy = second_attempt_proxy = 0;
      confidence = 0.0;
      insight = "";
      may_modify_strategy = false;
      valid = false;
     }
  };

#endif // GM_SGM_LEARNING_ANALYSIS_RESULT_MQH
//+------------------------------------------------------------------+
