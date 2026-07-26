//+------------------------------------------------------------------+
//|                                  CTradeEnvironmentMonitor.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     H4 environment grading — ADVISORY ONLY                      |
//+------------------------------------------------------------------+
#ifndef GM_CTRADE_ENVIRONMENT_MONITOR_MQH
#define GM_CTRADE_ENVIRONMENT_MONITOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmAssistantResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../News/SGmNewsAnalysisResult.mqh"
#include "../Confidence/SGmConfidenceAnalysisResult.mqh"
#include "../Learning/SGmLearningAnalysisResult.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"

/// @brief Grades H4 trade environment from frozen AI intelligence outputs.
class CGmTradeEnvironmentMonitor
  {
public:
   void Analyze(CGmPhase2Bridge *bridge,
                const SGmTrendAnalysisResult &trend,
                const SGmVolatilityAnalysisResult &vol,
                const SGmNewsAnalysisResult &news,
                const SGmConfidenceAnalysisResult &conf,
                const SGmLearningAnalysisResult &learn,
                SGmAssistantResult &r)
     {
      r.trend_quality = trend.valid ? GmAssistClamp(trend.strength_score) : 50.0;
      r.atr_environment = vol.valid ? GmAssistClamp(vol.atr_strength) : 50.0;
      r.volatility_score = vol.valid ? GmAssistClamp(vol.vol_confidence) : 50.0;
      r.market_energy = vol.valid ? GmAssistClamp(vol.energy_score) : 50.0;
      r.liquidity_score = conf.valid ? GmAssistClamp(conf.quality.liquidity_quality) : 50.0;
      r.news_environment = news.valid
                           ? GmAssistClamp(100.0 - news.news_risk_score)
                           : 70.0;
      r.historical_similarity = learn.valid
                                ? GmAssistClamp(learn.historical_correlation)
                                : 50.0;
      r.confidence_score = conf.valid
                           ? GmAssistClamp(conf.overall_confidence)
                           : (trend.valid ? GmAssistClamp(trend.confidence) : 50.0);

      // Spread from SymbolInfo (observation)
      r.spread_points = 0.0;
      if(bridge != NULL && StringLen(bridge.Symbol()) > 0)
        {
         const string sym = bridge.Symbol();
         const double point = SymbolInfoDouble(sym, SYMBOL_POINT);
         if(point > 0.0)
            r.spread_points = (double)SymbolInfoInteger(sym, SYMBOL_SPREAD);
        }

      // Spread contribution: lower spread => higher local score
      double spread_score = 90.0;
      if(r.spread_points >= GM_ASSIST_SPREAD_WARN_PTS)
         spread_score = GmAssistClamp(90.0 - (r.spread_points - GM_ASSIST_SPREAD_WARN_PTS) * 1.5);
      else if(r.spread_points > 20.0)
         spread_score = 80.0;

      r.environment_score = GmAssistClamp(
                               0.18 * r.trend_quality +
                               0.12 * r.atr_environment +
                               0.12 * r.volatility_score +
                               0.10 * spread_score +
                               0.10 * r.market_energy +
                               0.10 * r.liquidity_score +
                               0.08 * r.news_environment +
                               0.08 * r.historical_similarity +
                               0.12 * r.confidence_score);

      if(r.environment_score >= 85.0)
         r.environment_grade = GM_ENV_GRADE_A;
      else if(r.environment_score >= 70.0)
         r.environment_grade = GM_ENV_GRADE_B;
      else if(r.environment_score >= 55.0)
         r.environment_grade = GM_ENV_GRADE_C;
      else if(r.environment_score >= 40.0)
         r.environment_grade = GM_ENV_GRADE_D;
      else
         r.environment_grade = GM_ENV_GRADE_F;

      r.market_health = StringFormat("Env %s (%.0f)",
                                     GmEnvGradeName(r.environment_grade),
                                     r.environment_score);
     }
  };

#endif // GM_CTRADE_ENVIRONMENT_MONITOR_MQH
//+------------------------------------------------------------------+
