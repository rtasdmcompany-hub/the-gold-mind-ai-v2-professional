//+------------------------------------------------------------------+
//|                                  SGmMemoryLearningResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_MEMORY_LEARNING_RESULT_MQH
#define GM_SGM_MEMORY_LEARNING_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "MemoryAIConstants.mqh"

struct SGmDiscoveredPattern
  {
   string name;
   int    occurrences;
   double success_rate;
   bool   active;

   void Reset(void)
     {
      name = "";
      occurrences = 0;
      success_rate = 0.0;
      active = false;
     }
  };

struct SGmMemoryLearningResult
  {
   datetime              stamped_at;
   string                symbol;
   ulong                 session_id;
   ENUM_GM_MEM_STATUS    status;

   // Memory Profile
   int                   total_analyzed_sessions;
   int                   market_patterns_stored;
   int                   recovery_patterns;
   double                confidence_improvement_pct;
   string                memory_profile;

   // Adaptive Learning
   double                learning_accuracy;
   double                analysis_improvement_pct;
   double                false_warning_rate;
   double                advisory_success_rate;
   string                learning_report;

   // Market Behavior
   ENUM_GM_BEHAVIOR_TYPE behavior_type;
   string                behavior_label;
   double                behavior_match_pct;
   string                behavior_map;

   // Pattern Discovery
   SGmDiscoveredPattern  top_pattern;
   int                   patterns_discovered;
   string                pattern_report;

   // Confidence Calibration
   double                previous_confidence;
   double                calibrated_confidence;
   string                calibration_reason;

   // Knowledge Graph (counts only — architecture foundation)
   int                   graph_nodes;
   int                   graph_relationships;
   string                graph_status;

   // Dashboard composites
   double                knowledge_growth;
   double                historical_intelligence;
   double                improvement_score;
   string                memory_status;
   string                advisory_status;
   string                insight;
   bool                  may_execute;
   bool                  may_modify_strategy;
   bool                  from_cache;
   bool                  valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = "";
      session_id = 0;
      status = GM_MEM_STATUS_IDLE;
      total_analyzed_sessions = market_patterns_stored = recovery_patterns = 0;
      confidence_improvement_pct = 0.0;
      memory_profile = "";
      learning_accuracy = analysis_improvement_pct = 0.0;
      false_warning_rate = advisory_success_rate = 0.0;
      learning_report = "";
      behavior_type = GM_BEH_UNKNOWN;
      behavior_label = "—";
      behavior_match_pct = 0.0;
      behavior_map = "";
      top_pattern.Reset();
      patterns_discovered = 0;
      pattern_report = "";
      previous_confidence = calibrated_confidence = 0.0;
      calibration_reason = "";
      graph_nodes = graph_relationships = 0;
      graph_status = "INACTIVE foundation";
      knowledge_growth = historical_intelligence = improvement_score = 0.0;
      memory_status = "Idle";
      advisory_status = GM_MEM_ADVISORY;
      insight = "";
      may_execute = false;
      may_modify_strategy = false;
      from_cache = false;
      valid = false;
     }
  };

#endif // GM_SGM_MEMORY_LEARNING_RESULT_MQH
//+------------------------------------------------------------------+
