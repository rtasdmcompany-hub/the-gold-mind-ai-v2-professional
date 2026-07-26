//+------------------------------------------------------------------+
//|                               SGmMultiTimeframeResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_MULTI_TIMEFRAME_RESULT_MQH
#define GM_SGM_MULTI_TIMEFRAME_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "MultiTimeframeConstants.mqh"
#include "../Trend/TrendAIConstants.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"

struct SGmMultiTimeframeResult
  {
   datetime              stamped_at;
   string                symbol;
   ulong                 session_id;
   ENUM_GM_MTF_STATUS    status;

   // Per-TF snapshots (analysis)
   SGmTrendTFState       m5;
   SGmTrendTFState       m15;
   SGmTrendTFState       m30;
   SGmTrendTFState       h1;
   SGmTrendTFState       h4;
   SGmTrendTFState       d1;
   SGmTrendTFState       w1;
   SGmTrendTFState       mn;

   // Task 1 biases
   ENUM_GM_MTF_BIAS      higher_tf_bias;
   ENUM_GM_MTF_BIAS      lower_tf_bias;
   ENUM_GM_MTF_BIAS      overall_market_bias;
   double                timeframe_agreement;
   double                timeframe_conflict;
   string                mtf_report;

   // Task 2 sync
   double                trend_agreement;
   double                trend_conflict;
   double                momentum_alignment;
   double                atr_alignment;
   double                volatility_alignment;
   double                structure_alignment;
   double                synchronization_score;
   double                alignment_confidence;
   double                trend_stability;
   string                sync_report;

   // Task 3 H4 context
   double                h4_structure_score;
   double                htf_support;
   double                ltf_confirmation;
   double                historical_similarity;
   double                liquidity_context;
   double                news_context;
   double                volatility_context;
   double                recovery_context;
   double                execution_context_score;
   ENUM_GM_MTF_GRADE     market_context_grade;
   string                context_report;

   // Task 4 correlation
   double                corr_trend;
   double                corr_momentum;
   double                corr_volatility;
   double                corr_atr;
   double                corr_structure;
   double                corr_historical;
   double                correlation_index;
   double                correlation_confidence;
   string                correlation_matrix;
   string                correlation_report;

   // Task 5 confluence
   double                confluence_score;
   double                strength_rating;
   double                confluence_confidence;
   string                confluence_report;

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
      status = GM_MTF_STATUS_IDLE;
      m5.Reset(); m15.Reset(); m30.Reset(); h1.Reset();
      h4.Reset(); d1.Reset(); w1.Reset(); mn.Reset();
      m5.tf = PERIOD_M5; m15.tf = PERIOD_M15; m30.tf = PERIOD_M30; h1.tf = PERIOD_H1;
      h4.tf = PERIOD_H4; d1.tf = PERIOD_D1; w1.tf = PERIOD_W1; mn.tf = PERIOD_MN1;
      higher_tf_bias = lower_tf_bias = overall_market_bias = GM_MTF_BIAS_UNKNOWN;
      timeframe_agreement = timeframe_conflict = 0.0;
      mtf_report = "";
      trend_agreement = trend_conflict = momentum_alignment = 0.0;
      atr_alignment = volatility_alignment = structure_alignment = 0.0;
      synchronization_score = alignment_confidence = trend_stability = 0.0;
      sync_report = "";
      h4_structure_score = htf_support = ltf_confirmation = 0.0;
      historical_similarity = liquidity_context = news_context = 0.0;
      volatility_context = recovery_context = execution_context_score = 0.0;
      market_context_grade = GM_MTF_GRADE_UNKNOWN;
      context_report = "";
      corr_trend = corr_momentum = corr_volatility = corr_atr = 0.0;
      corr_structure = corr_historical = correlation_index = 0.0;
      correlation_confidence = 0.0;
      correlation_matrix = correlation_report = "";
      confluence_score = strength_rating = confluence_confidence = 0.0;
      confluence_report = "";
      center_status = "Idle";
      advisory_status = GM_MTF_ADVISORY;
      insight = "";
      may_execute = false;
      may_modify_risk = false;
      from_cache = false;
      valid = false;
     }
  };

#endif // GM_SGM_MULTI_TIMEFRAME_RESULT_MQH
//+------------------------------------------------------------------+
