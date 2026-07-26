//+------------------------------------------------------------------+
//|                                  CMultiFactorScoringEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CMULTI_FACTOR_SCORING_ENGINE_MQH
#define GM_CMULTI_FACTOR_SCORING_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmConfidenceAnalysisResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../News/SGmNewsAnalysisResult.mqh"

class CGmMultiFactorScoringEngine
  {
private:
   SGmConfidenceWeights m_weights;

public:
                     CGmMultiFactorScoringEngine(void) { m_weights.Defaults(); }

   void SetWeights(const SGmConfidenceWeights &w)
     {
      m_weights = w;
      m_weights.Normalize();
     }

   SGmConfidenceWeights Weights(void) const { return m_weights; }

   void Score(const string symbol,
              const SGmTrendAnalysisResult &trend,
              const SGmVolatilityAnalysisResult &vol,
              const SGmNewsAnalysisResult &news,
              const double hist_avg_conf,
              SGmConfidenceAnalysisResult &r)
     {
      r.weights_used = m_weights;
      r.factors.Reset();

      // Trend
      if(trend.valid)
        {
         r.factors.trend = GmConfClamp(trend.confidence);
         r.factors.structure = GmConfClamp(r.structure_score > 0.0 ? r.structure_score
                                           : trend.agreement_score);
         r.factors.momentum = GmConfClamp(MathAbs(trend.momentum_strength));
         r.trend_label = GmTrendDirName(trend.primary);
         r.trend_score = r.factors.trend;
        }

      // Volatility / ATR
      if(vol.valid)
        {
         // Prefer stable-but-active energy for Gold Mind H4 levels
         double vol_score = vol.vol_stability * 0.55 + (100.0 - MathAbs(vol.energy_score - 55.0)) * 0.45;
         r.factors.volatility = GmConfClamp(vol_score);
         r.factors.atr = GmConfClamp(50.0 + (vol.atr_compression ? 10.0 : 0.0) -
                                     (vol.energy == GM_ENERGY_EXPLOSIVE ? 25.0 : 0.0) +
                                     (vol.atr_strength - 50.0) * 0.3);
         r.volatility_score = r.factors.volatility;
         r.atr14 = vol.atr14;
        }

      // News — high risk lowers factor but NEVER blocks
      if(news.valid)
        {
         r.news_risk = news.news_risk_score;
         r.factors.news = GmConfClamp(100.0 - news.news_risk_score * 0.55);
        }
      else
         r.factors.news = 60.0;

      // Spread
      const double spread = (double)SymbolInfoInteger(symbol, SYMBOL_SPREAD);
      r.factors.spread = GmConfClamp(100.0 - MathMax(0.0, spread - 12.0) * 2.0);

      // Session — London/NY overlap preferred for gold
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      const int h = dt.hour;
      if(h >= 12 && h <= 17)
         r.factors.session = 85.0;
      else if(h >= 7 && h <= 20)
         r.factors.session = 70.0;
      else
         r.factors.session = 45.0;
      r.session_rating = (r.factors.session >= 80.0) ? "Prime"
                         : (r.factors.session >= 65.0) ? "Active" : "Off-Peak";

      // Historical pattern proxy
      r.factors.history = (hist_avg_conf > 0.0) ? GmConfClamp(hist_avg_conf) : 55.0;

      // Weighted overall
      double overall =
         r.factors.trend * m_weights.trend +
         r.factors.volatility * m_weights.volatility +
         r.factors.atr * m_weights.atr +
         r.factors.news * m_weights.news +
         r.factors.structure * m_weights.structure +
         r.factors.momentum * m_weights.momentum +
         r.factors.spread * m_weights.spread +
         r.factors.session * m_weights.session +
         r.factors.history * m_weights.history;

      r.overall_confidence = GmConfClamp(overall);
      r.trade_quality = GmConfClamp(
         r.factors.trend * 0.35 + r.factors.structure * 0.25 +
         r.factors.momentum * 0.20 + r.factors.spread * 0.20);
      r.execution_readiness = GmConfClamp(
         r.factors.spread * 0.40 + r.factors.session * 0.30 +
         r.factors.atr * 0.30);
      r.risk_environment = GmConfClamp(
         (100.0 - r.factors.news) * 0.40 +
         (100.0 - r.factors.spread) * 0.25 +
         (vol.valid && vol.energy_score > 70.0 ? vol.energy_score * 0.35 : 20.0));
      r.confidence = r.overall_confidence;
     }
  };

#endif // GM_CMULTI_FACTOR_SCORING_ENGINE_MQH
//+------------------------------------------------------------------+
