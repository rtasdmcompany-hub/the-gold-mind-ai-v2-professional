//+------------------------------------------------------------------+
//|                               SGmOptimizationLabResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_OPTIMIZATION_LAB_RESULT_MQH
#define GM_SGM_OPTIMIZATION_LAB_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "OptimizationLabConstants.mqh"

struct SGmEolProfileScore
  {
   string name;
   double performance;
   double stability;
   double comparison;
   double rank_score;
   bool   used;

   void Reset(void)
     {
      name = "";
      performance = stability = comparison = rank_score = 0.0;
      used = false;
     }
  };

struct SGmOptimizationLabResult
  {
   datetime           stamped_at;
   ENUM_GM_EOL_QUEUE  queue_status;

   int                profiles_compared;
   int                datasets_validated;
   int                active_gm_trades;
   bool               opt_paused;

   double             comparison_score;
   double             optimization_score;
   double             parameter_stability;
   double             parameter_confidence;
   double             market_adaptability;
   double             institutional_score;
   double             historical_rank_top;

   string             best_profile;
   string             safest_profile;
   string             lowest_dd_profile;
   string             best_recovery_profile;
   string             best_news_profile;
   string             best_session_profile;

   string             comparison_summary;
   string             optimization_suggestions;
   string             parameter_report;
   string             adaptability_report;
   string             recommendation_report;
   string             validation_status;
   string             ranking_summary;
   string             export_status;
   string             center_status;
   string             insight;

   bool               may_execute;
   bool               may_modify_risk;
   bool               may_interrupt_trading;
   bool               may_auto_apply_params;
   bool               valid;

   void Reset(void)
     {
      stamped_at = 0;
      queue_status = GM_EOL_Q_IDLE;
      profiles_compared = datasets_validated = 0;
      active_gm_trades = 0;
      opt_paused = false;
      comparison_score = optimization_score = parameter_stability = 0.0;
      parameter_confidence = market_adaptability = institutional_score = 0.0;
      historical_rank_top = 0.0;
      best_profile = safest_profile = lowest_dd_profile = "";
      best_recovery_profile = best_news_profile = best_session_profile = "";
      comparison_summary = optimization_suggestions = parameter_report = "";
      adaptability_report = recommendation_report = validation_status = "";
      ranking_summary = "";
      export_status = "Architecture Ready";
      center_status = insight = "";
      may_execute = false;
      may_modify_risk = false;
      may_interrupt_trading = false;
      may_auto_apply_params = false;
      valid = false;
     }
  };

#endif // GM_SGM_OPTIMIZATION_LAB_RESULT_MQH
//+------------------------------------------------------------------+
