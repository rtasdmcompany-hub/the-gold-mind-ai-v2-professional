//+------------------------------------------------------------------+
//|                                       CMarketScoreEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CMARKET_SCORE_ENGINE_MQH
#define GM_CMARKET_SCORE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmIntelligenceResult.mqh"

class CGmMarketScoreEngine
  {
public:
   void Analyze(SGmIntelligenceResult &r)
     {
      // Risk environment contribution: invert risk_score (lower risk => higher contribution)
      const double risk_env = GmIntelClamp(100.0 - r.risk_score);

      r.market_score = GmIntelClamp(
                          GM_INTEL_W_TREND * r.trend_strength +
                          GM_INTEL_W_VOL   * (100.0 - MathAbs(r.volatility_state - 55.0)) + // prefer mid vol
                          GM_INTEL_W_LIQ   * r.liquidity_condition +
                          GM_INTEL_W_HIST  * r.historical_similarity +
                          GM_INTEL_W_RISK  * risk_env);

      // Soft adjustment for extreme conditions
      if(r.market_condition == GM_MKT_COND_HIGH_VOL)
         r.market_score = GmIntelClamp(r.market_score - 8.0);
      if((r.market_condition == GM_MKT_COND_TRENDING ||
          r.market_condition == GM_MKT_COND_STRONG_TREND) &&
         r.liquidity_condition >= 65.0)
         r.market_score = GmIntelClamp(r.market_score + 4.0);

      r.market_grade = GmIntelGradeFromScore(r.market_score);

      if(r.market_score >= 80.0)
         r.market_score_condition = "Favorable Monitoring Environment";
      else if(r.market_score >= 65.0)
         r.market_score_condition = "Acceptable Monitoring Environment";
      else if(r.market_score >= 50.0)
         r.market_score_condition = "Cautious Monitoring Environment";
      else
         r.market_score_condition = "Adverse Monitoring Environment";
     }
  };

#endif // GM_CMARKET_SCORE_ENGINE_MQH
//+------------------------------------------------------------------+
