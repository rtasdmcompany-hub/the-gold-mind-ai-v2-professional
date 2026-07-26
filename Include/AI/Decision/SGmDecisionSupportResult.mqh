//+------------------------------------------------------------------+
//|                                    SGmDecisionSupportResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_DECISION_SUPPORT_RESULT_MQH
#define GM_SGM_DECISION_SUPPORT_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "DecisionAIConstants.mqh"

struct SGmDecisionFactor
  {
   string name;
   double score;
   double weight;
   string note;

   void Reset(void)
     {
      name = note = "";
      score = weight = 0.0;
     }
  };

struct SGmSimilarityHit
  {
   datetime stamped_at;
   double   similarity_pct;
   double   confidence;
   double   success_proxy;
   string   label;
   bool     valid;

   void Reset(void)
     {
      stamped_at = 0;
      similarity_pct = confidence = success_proxy = 0.0;
      label = "";
      valid = false;
     }
  };

struct SGmDecisionSupportResult
  {
   datetime                    stamped_at;
   string                      symbol;
   ulong                       session_id;
   datetime                    h4_bar_time;
   bool                        new_h4_cycle;

   double                      overall_confidence;
   double                      trade_quality;
   double                      market_health;
   double                      risk_environment;
   double                      execution_readiness;
   double                      historical_similarity;
   double                      historical_success_rate;
   double                      environment_score;
   double                      learning_confidence;

   ENUM_GM_DEC_RECO            recommendation;
   ENUM_GM_DEC_STRATEGY_MATCH  strategy_match;
   string                      strategy_stats;

   SGmDecisionFactor           factors[GM_DEC_FACTOR_MAX];
   int                         factor_count;
   string                      reasons[GM_DEC_REASON_MAX];
   int                         reason_count;
   string                      explanation;
   string                      top_factors_summary;

   SGmSimilarityHit            top_matches[5];
   int                         match_count;

   double                      confidence;
   string                      insight;
   bool                        may_execute;          // ALWAYS false
   bool                        may_reject_trades;    // ALWAYS false
   bool                        may_modify_trades;    // ALWAYS false
   bool                        valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = "";
      session_id = 0;
      h4_bar_time = 0;
      new_h4_cycle = false;
      overall_confidence = trade_quality = market_health = 0.0;
      risk_environment = execution_readiness = historical_similarity = 0.0;
      historical_success_rate = environment_score = learning_confidence = 0.0;
      recommendation = GM_DEC_RECO_NONE;
      strategy_match = GM_DEC_MATCH_UNKNOWN;
      strategy_stats = "";
      factor_count = reason_count = match_count = 0;
      for(int i = 0; i < GM_DEC_FACTOR_MAX; i++)
         factors[i].Reset();
      for(int i = 0; i < GM_DEC_REASON_MAX; i++)
         reasons[i] = "";
      for(int i = 0; i < 5; i++)
         top_matches[i].Reset();
      explanation = top_factors_summary = "";
      confidence = 0.0;
      insight = "";
      may_execute = may_reject_trades = may_modify_trades = false;
      valid = false;
     }
  };

#endif // GM_SGM_DECISION_SUPPORT_RESULT_MQH
//+------------------------------------------------------------------+
