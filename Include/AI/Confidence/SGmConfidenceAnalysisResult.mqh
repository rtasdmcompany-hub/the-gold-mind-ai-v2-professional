//+------------------------------------------------------------------+
//|                                SGmConfidenceAnalysisResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_CONFIDENCE_ANALYSIS_RESULT_MQH
#define GM_SGM_CONFIDENCE_ANALYSIS_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ConfidenceAIConstants.mqh"

struct SGmMarketQualityScores
  {
   double trend_quality;
   double range_quality;
   double volatility_quality;
   double liquidity_quality;
   double spread_stability;
   double momentum_quality;
   double price_action_quality;

   void Reset(void)
     {
      trend_quality = range_quality = volatility_quality = 50.0;
      liquidity_quality = spread_stability = 50.0;
      momentum_quality = price_action_quality = 50.0;
     }

   double Average(void) const
     {
      return (trend_quality + range_quality + volatility_quality +
              liquidity_quality + spread_stability + momentum_quality +
              price_action_quality) / 7.0;
     }
  };

struct SGmConfidenceFactorScores
  {
   double trend;
   double volatility;
   double atr;
   double news;
   double structure;
   double momentum;
   double spread;
   double session;
   double history;

   void Reset(void)
     {
      trend = volatility = atr = news = structure = 50.0;
      momentum = spread = session = history = 50.0;
     }
  };

struct SGmConfidenceAnalysisResult
  {
   datetime                    stamped_at;
   string                      symbol;
   ulong                       session_id;
   datetime                    h4_bar_time;
   bool                        new_h4_cycle;

   double                      overall_confidence;
   double                      trade_quality;
   double                      market_quality;
   double                      execution_readiness;
   double                      risk_environment;

   SGmConfidenceFactorScores   factors;
   SGmMarketQualityScores      quality;
   SGmConfidenceWeights        weights_used;

   ENUM_GM_CONF_ENV            environment;
   string                      environment_explain;
   ENUM_GM_CONF_RECO           recommendation;
   ENUM_GM_CONF_TREND          confidence_trend;

   // Context snapshots for DB / ML
   double                      atr14;
   string                      trend_label;
   double                      trend_score;
   double                      volatility_score;
   double                      news_risk;
   double                      structure_score;
   double                      liquidity_score;
   string                      session_rating;

   double                      confidence;
   string                      insight;
   bool                        may_reject_trades;   // ALWAYS false
   bool                        may_modify_trades;   // ALWAYS false
   bool                        valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = "";
      session_id = 0;
      h4_bar_time = 0;
      new_h4_cycle = false;
      overall_confidence = trade_quality = market_quality = 0.0;
      execution_readiness = risk_environment = 0.0;
      factors.Reset();
      quality.Reset();
      weights_used.Defaults();
      environment = GM_CONF_ENV_UNKNOWN;
      environment_explain = "";
      recommendation = GM_CONF_RECO_NONE;
      confidence_trend = GM_CONF_TREND_FLAT;
      atr14 = 0.0;
      trend_label = "";
      trend_score = volatility_score = news_risk = 0.0;
      structure_score = liquidity_score = 0.0;
      session_rating = "";
      confidence = 0.0;
      insight = "";
      may_reject_trades = false;
      may_modify_trades = false;
      valid = false;
     }
  };

#endif // GM_SGM_CONFIDENCE_ANALYSIS_RESULT_MQH
//+------------------------------------------------------------------+
