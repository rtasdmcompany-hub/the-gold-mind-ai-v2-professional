//+------------------------------------------------------------------+
//|                                     SGmIntelligenceResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_INTELLIGENCE_RESULT_MQH
#define GM_SGM_INTELLIGENCE_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "IntelligenceAIConstants.mqh"

struct SGmIntelligenceResult
  {
   datetime                 stamped_at;
   string                   symbol;
   ulong                    session_id;
   ENUM_GM_INTEL_STATUS     status;

   // Market Intelligence
   ENUM_GM_MKT_CONDITION    market_condition;
   string                   trend_strength_label;   // Strong/Medium/Weak
   string                   volatility_label;
   string                   liquidity_label;
   double                   trend_strength;
   double                   volatility_state;
   double                   atr_condition;
   double                   liquidity_condition;
   double                   momentum;
   double                   expansion_score;
   double                   compression_score;
   double                   market_confidence;
   string                   market_advisory;

   // Historical Pattern
   double                   historical_similarity;
   string                   similar_pattern_date;
   string                   historical_outcome;
   string                   pattern_insight;

   // Strategy Performance
   double                   strategy_performance_score;
   int                      total_sessions;
   int                      winning_sessions;
   int                      losing_sessions;
   double                   recovery_success_rate;
   double                   average_drawdown;
   string                   monthly_stability;
   string                   recovery_efficiency_label;
   string                   risk_behavior_label;
   string                   best_conditions;
   string                   worst_conditions;
   string                   performance_report;

   // Risk Advisory
   ENUM_GM_RISK_ADVISORY    risk_advisory;
   double                   risk_score;
   double                   exposure_pct;
   double                   equity;
   double                   margin_safety;
   double                   drawdown_level;
   string                   recovery_status;
   string                   risk_explanation;

   // Market Score
   double                   market_score;
   ENUM_GM_INTEL_GRADE      market_grade;
   string                   market_score_condition;

   // Explanation
   string                   explanation;
   string                   explanation_short;

   // Overall
   double                   ai_confidence;
   double                   strategy_health;
   double                   recovery_intelligence;
   string                   intelligence_status;
   string                   advisory_status;
   string                   insight;
   bool                     may_execute;       // ALWAYS false
   bool                     may_modify_risk;   // ALWAYS false
   bool                     from_cache;
   bool                     valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = "";
      session_id = 0;
      status = GM_INTEL_STATUS_IDLE;
      market_condition = GM_MKT_COND_UNCERTAIN;
      trend_strength_label = volatility_label = liquidity_label = "—";
      trend_strength = volatility_state = atr_condition = liquidity_condition = 0.0;
      momentum = expansion_score = compression_score = market_confidence = 0.0;
      market_advisory = "";
      historical_similarity = 0.0;
      similar_pattern_date = historical_outcome = pattern_insight = "";
      strategy_performance_score = 0.0;
      total_sessions = winning_sessions = losing_sessions = 0;
      recovery_success_rate = average_drawdown = 0.0;
      monthly_stability = recovery_efficiency_label = risk_behavior_label = "—";
      best_conditions = worst_conditions = performance_report = "";
      risk_advisory = GM_RISK_ADV_UNKNOWN;
      risk_score = exposure_pct = equity = margin_safety = drawdown_level = 0.0;
      recovery_status = risk_explanation = "";
      market_score = 0.0;
      market_grade = GM_INTEL_GRADE_UNKNOWN;
      market_score_condition = "";
      explanation = explanation_short = "";
      ai_confidence = strategy_health = recovery_intelligence = 0.0;
      intelligence_status = "Idle";
      advisory_status = GM_INTEL_ADVISORY;
      insight = "";
      may_execute = false;
      may_modify_risk = false;
      from_cache = false;
      valid = false;
     }
  };

#endif // GM_SGM_INTELLIGENCE_RESULT_MQH
//+------------------------------------------------------------------+
