//+------------------------------------------------------------------+
//|                                          CConfidenceMlApi.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CCONFIDENCE_ML_API_MQH
#define GM_CCONFIDENCE_ML_API_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmConfidenceAnalysisResult.mqh"

/// @brief Future Machine Learning interface — feature export only (no ML yet).
struct SGmConfidenceMlFeatures
  {
   double overall_confidence;
   double trade_quality;
   double market_quality;
   double execution_readiness;
   double risk_environment;
   double trend_score;
   double volatility_score;
   double news_risk;
   double structure_score;
   double liquidity_score;
   double atr14;
   double f_trend;
   double f_vol;
   double f_atr;
   double f_news;
   double f_structure;
   double f_momentum;
   double f_spread;
   double f_session;
   double f_history;
   int    environment_code;
   int    recommendation_code;
   ulong  session_id;
   datetime stamped_at;
   bool   valid;

   void Reset(void)
     {
      overall_confidence = trade_quality = market_quality = 0.0;
      execution_readiness = risk_environment = 0.0;
      trend_score = volatility_score = news_risk = 0.0;
      structure_score = liquidity_score = atr14 = 0.0;
      f_trend = f_vol = f_atr = f_news = f_structure = 0.0;
      f_momentum = f_spread = f_session = f_history = 0.0;
      environment_code = recommendation_code = 0;
      session_id = 0;
      stamped_at = 0;
      valid = false;
     }
  };

class CGmConfidenceMlApi
  {
public:
   SGmConfidenceMlFeatures ExportFeatures(const SGmConfidenceAnalysisResult &r) const
     {
      SGmConfidenceMlFeatures f;
      f.Reset();
      if(!r.valid)
         return f;
      f.overall_confidence = r.overall_confidence;
      f.trade_quality = r.trade_quality;
      f.market_quality = r.market_quality;
      f.execution_readiness = r.execution_readiness;
      f.risk_environment = r.risk_environment;
      f.trend_score = r.trend_score;
      f.volatility_score = r.volatility_score;
      f.news_risk = r.news_risk;
      f.structure_score = r.structure_score;
      f.liquidity_score = r.liquidity_score;
      f.atr14 = r.atr14;
      f.f_trend = r.factors.trend;
      f.f_vol = r.factors.volatility;
      f.f_atr = r.factors.atr;
      f.f_news = r.factors.news;
      f.f_structure = r.factors.structure;
      f.f_momentum = r.factors.momentum;
      f.f_spread = r.factors.spread;
      f.f_session = r.factors.session;
      f.f_history = r.factors.history;
      f.environment_code = (int)r.environment;
      f.recommendation_code = (int)r.recommendation;
      f.session_id = r.session_id;
      f.stamped_at = r.stamped_at;
      f.valid = true;
      return f;
     }

   /// @brief Historical outcomes placeholder for future supervised learning.
   string PatternDatabaseNote(void) const
     {
      return "Pattern DB interface ready — outcomes wiring deferred to future ML sprint";
     }

   bool MlEnabled(void) const { return false; }
  };

#endif // GM_CCONFIDENCE_ML_API_MQH
//+------------------------------------------------------------------+
