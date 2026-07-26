//+------------------------------------------------------------------+
//|                                  SGmSelfLearningResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_SELF_LEARNING_RESULT_MQH
#define GM_SGM_SELF_LEARNING_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SelfLearningConstants.mqh"

struct SGmSelfLearningResult
  {
   datetime          stamped_at;
   string            symbol;
   ulong             session_id;
   ENUM_GM_SL_STATUS status;

   // Learning engine
   double            learning_confidence;
   double            knowledge_growth;
   double            learning_stability;
   int               sessions_studied;
   int               winning_trades_studied;
   int               losing_trades_studied;
   int               recovery_trades_studied;
   string            learning_report;

   // Knowledge evolution
   double            knowledge_index;
   double            learning_score;
   double            knowledge_quality;
   int               patterns_discovered;
   double            pattern_frequency;
   string            pattern_library;
   string            knowledge_report;

   // Recommendations
   int               recommendation_count;
   string            recommendations[GM_SL_REC_MAX];
   string            recommendation_center;
   string            recommendation_report;

   // Optimization
   double            optimization_score;
   double            system_efficiency_rating;
   double            analysis_speed_score;
   double            memory_efficiency;
   double            dashboard_performance;
   string            optimization_report;

   // Validation
   double            learning_accuracy;
   double            pattern_recognition_score;
   double            historical_matching;
   double            prediction_quality;
   double            knowledge_stability;
   double            recommendation_quality;
   double            knowledge_reliability;
   ENUM_GM_SL_CERT   learning_certification;
   string            validation_report;

   // Summary
   string            ai_evolution_status;
   string            ai_evolution_summary;
   string            historical_intelligence;
   string            center_status;
   string            advisory_status;
   string            insight;
   bool              may_execute;
   bool              may_modify_strategy;
   bool              may_modify_risk;
   bool              from_cache;
   bool              valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = "";
      session_id = 0;
      status = GM_SL_STATUS_IDLE;
      learning_confidence = knowledge_growth = learning_stability = 0.0;
      sessions_studied = winning_trades_studied = losing_trades_studied = 0;
      recovery_trades_studied = 0;
      learning_report = "";
      knowledge_index = learning_score = knowledge_quality = 0.0;
      patterns_discovered = 0;
      pattern_frequency = 0.0;
      pattern_library = knowledge_report = "";
      recommendation_count = 0;
      for(int i = 0; i < GM_SL_REC_MAX; i++)
         recommendations[i] = "";
      recommendation_center = recommendation_report = "";
      optimization_score = system_efficiency_rating = 0.0;
      analysis_speed_score = memory_efficiency = dashboard_performance = 0.0;
      optimization_report = "";
      learning_accuracy = pattern_recognition_score = historical_matching = 0.0;
      prediction_quality = knowledge_stability = recommendation_quality = 0.0;
      knowledge_reliability = 0.0;
      learning_certification = GM_SL_CERT_UNKNOWN;
      validation_report = "";
      ai_evolution_status = "Idle";
      ai_evolution_summary = historical_intelligence = "";
      center_status = "Idle";
      advisory_status = GM_SL_ADVISORY;
      insight = "";
      may_execute = false;
      may_modify_strategy = false;
      may_modify_risk = false;
      from_cache = false;
      valid = false;
     }
  };

#endif // GM_SGM_SELF_LEARNING_RESULT_MQH
//+------------------------------------------------------------------+
