//+------------------------------------------------------------------+
//|                                    SGmOrchestrationResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_ORCHESTRATION_RESULT_MQH
#define GM_SGM_ORCHESTRATION_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "OrchestrationAIConstants.mqh"

struct SGmOrchestrationResult
  {
   datetime              stamped_at;
   string                symbol;
   ulong                 session_id;
   ENUM_GM_ORCH_STATUS   status;

   // Unified profile
   string                market_status;
   string                risk_status;
   string                learning_status;
   string                system_status;
   double                unified_confidence;
   string                unified_profile;

   // Decision support
   string                observation;
   string                analysis;
   string                advisory;
   string                decision_support_report;

   // Fusion
   double                market_score_in;
   double                risk_score_in;
   double                learning_score_in;
   double                forecast_score_in;
   double                system_score_in;
   double                intelligence_score;
   ENUM_GM_ORCH_GRADE    intelligence_grade;
   string                intelligence_status;
   string                fusion_report;

   // Priority queue
   int                   priority_count;
   string                priorities[GM_ORCH_PRIORITY_MAX];
   string                priority_queue;

   // Insights
   string                market_insight;
   string                risk_insight;
   string                performance_insight;
   string                learning_insight;
   string                system_insight;
   string                primary_insight;

   // Knowledge network
   int                   graph_nodes;
   int                   graph_edges;
   string                knowledge_network;
   string                knowledge_links;

   // Layer snapshots for Command Center
   string                market_intel_panel;
   string                risk_intel_panel;
   string                forecast_intel_panel;
   string                learning_intel_panel;

   string                center_status;
   string                advisory_status;
   string                insight;
   bool                  may_execute;
   bool                  may_modify_strategy;
   bool                  may_modify_risk;
   bool                  from_cache;
   bool                  valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = "";
      session_id = 0;
      status = GM_ORCH_STATUS_IDLE;
      market_status = risk_status = learning_status = system_status = "";
      unified_confidence = 0.0;
      unified_profile = "";
      observation = analysis = advisory = decision_support_report = "";
      market_score_in = risk_score_in = learning_score_in = 0.0;
      forecast_score_in = system_score_in = intelligence_score = 0.0;
      intelligence_grade = GM_ORCH_GRADE_UNKNOWN;
      intelligence_status = fusion_report = "";
      priority_count = 0;
      for(int i = 0; i < GM_ORCH_PRIORITY_MAX; i++)
         priorities[i] = "";
      priority_queue = "";
      market_insight = risk_insight = performance_insight = "";
      learning_insight = system_insight = primary_insight = "";
      graph_nodes = graph_edges = 0;
      knowledge_network = knowledge_links = "";
      market_intel_panel = risk_intel_panel = "";
      forecast_intel_panel = learning_intel_panel = "";
      center_status = "Idle";
      advisory_status = GM_ORCH_ADVISORY;
      insight = "";
      may_execute = false;
      may_modify_strategy = false;
      may_modify_risk = false;
      from_cache = false;
      valid = false;
     }
  };

#endif // GM_SGM_ORCHESTRATION_RESULT_MQH
//+------------------------------------------------------------------+
