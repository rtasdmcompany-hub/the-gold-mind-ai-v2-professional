//+------------------------------------------------------------------+
//|                                   CDecisionMatrixEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CDECISION_MATRIX_ENGINE_MQH
#define GM_CDECISION_MATRIX_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmDecisionSupportResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../News/SGmNewsAnalysisResult.mqh"
#include "../Confidence/SGmConfidenceAnalysisResult.mqh"
#include "../Learning/SGmLearningAnalysisResult.mqh"

class CGmDecisionMatrixEngine
  {
   void AddFactor(SGmDecisionSupportResult &r, const string name,
                  const double score, const double weight, const string note)
     {
      if(r.factor_count >= GM_DEC_FACTOR_MAX)
         return;
      r.factors[r.factor_count].name = name;
      r.factors[r.factor_count].score = GmDecClamp(score);
      r.factors[r.factor_count].weight = weight;
      r.factors[r.factor_count].note = note;
      r.factor_count++;
     }

public:
   void Build(const SGmTrendAnalysisResult &trend,
              const SGmVolatilityAnalysisResult &vol,
              const SGmNewsAnalysisResult &news,
              const SGmConfidenceAnalysisResult &conf,
              const SGmLearningAnalysisResult &learn,
              SGmDecisionSupportResult &r)
     {
      r.factor_count = 0;

      if(trend.valid)
        {
         AddFactor(r, "Trend", trend.confidence, 0.16,
                   StringFormat("%s str=%.0f", GmTrendDirName(trend.primary), trend.strength_score));
         AddFactor(r, "Structure", trend.agreement_score, 0.12,
                   GmTrendStructName(trend.structure));
        }
      else
        {
         AddFactor(r, "Trend", 50.0, 0.16, "unavailable");
         AddFactor(r, "Structure", 50.0, 0.12, "unavailable");
        }

      if(vol.valid)
        {
         AddFactor(r, "ATR", vol.atr_strength, 0.10,
                   StringFormat("%.5f %s", vol.atr14, GmAtrTrendName(vol.atr_trend)));
         AddFactor(r, "Volatility", vol.vol_stability, 0.12,
                   GmEnergyName(vol.energy));
        }
      else
        {
         AddFactor(r, "ATR", 50.0, 0.10, "unavailable");
         AddFactor(r, "Volatility", 50.0, 0.12, "unavailable");
        }

      if(news.valid)
         AddFactor(r, "News", GmDecClamp(100.0 - news.news_risk_score * 0.55), 0.12,
                   GmNewsImpactName(news.current_impact));
      else
         AddFactor(r, "News", 60.0, 0.12, "unavailable");

      if(conf.valid)
        {
         AddFactor(r, "Confidence", conf.overall_confidence, 0.16,
                   GmConfEnvName(conf.environment));
         AddFactor(r, "MarketQuality", conf.market_quality, 0.10,
                   StringFormat("TQ=%.0f", conf.trade_quality));
         r.trade_quality = conf.trade_quality;
         r.execution_readiness = conf.execution_readiness;
         r.risk_environment = conf.risk_environment;
         r.overall_confidence = conf.overall_confidence;
        }
      else
        {
         AddFactor(r, "Confidence", 50.0, 0.16, "unavailable");
         AddFactor(r, "MarketQuality", 50.0, 0.10, "unavailable");
        }

      if(learn.valid)
        {
         AddFactor(r, "Learning", learn.prediction_accuracy, 0.12,
                   StringFormat("xp=%s", GmLearnXpName(learn.experience)));
         r.learning_confidence = learn.confidence;
        }
      else
        {
         AddFactor(r, "Learning", 50.0, 0.12, "unavailable");
         r.learning_confidence = 50.0;
        }

      // Normalize weights and compute overall
      double wsum = 0.0;
      for(int i = 0; i < r.factor_count; i++)
         wsum += r.factors[i].weight;
      if(wsum <= 0.0)
         wsum = 1.0;

      double overall = 0.0;
      for(int i = 0; i < r.factor_count; i++)
        {
         r.factors[i].weight /= wsum;
         overall += r.factors[i].score * r.factors[i].weight;
        }
      r.overall_confidence = GmDecClamp(overall);
      r.confidence = r.overall_confidence;
      r.market_health = GmDecClamp(
         (conf.valid ? conf.market_quality : 50.0) * 0.55 +
         (vol.valid ? vol.vol_stability : 50.0) * 0.25 +
         (trend.valid ? trend.trend_stability : 50.0) * 0.20);
      r.environment_score = GmDecClamp(
         r.market_health * 0.5 + (100.0 - r.risk_environment) * 0.5);

      // Top factors summary (sorted by contribution)
      string ranks[GM_DEC_FACTOR_MAX];
      double contrib[GM_DEC_FACTOR_MAX];
      for(int i = 0; i < r.factor_count; i++)
        {
         ranks[i] = r.factors[i].name;
         contrib[i] = r.factors[i].score * r.factors[i].weight;
        }
      for(int a = 0; a < r.factor_count - 1; a++)
         for(int b = a + 1; b < r.factor_count; b++)
            if(contrib[b] > contrib[a])
              {
               const double td = contrib[a]; contrib[a] = contrib[b]; contrib[b] = td;
               const string ts = ranks[a]; ranks[a] = ranks[b]; ranks[b] = ts;
              }
      r.top_factors_summary = "";
      const int top_n = MathMin(5, r.factor_count);
      for(int i = 0; i < top_n; i++)
        {
         if(i > 0) r.top_factors_summary += ", ";
         r.top_factors_summary += ranks[i];
        }

      // Recommendation from overall + risk
      if(r.risk_environment >= 70.0 || (news.valid && news.news_risk_score >= 75.0))
         r.recommendation = GM_DEC_RECO_ELEVATED_RISK;
      else if(r.overall_confidence >= 75.0 && r.market_health >= 65.0)
         r.recommendation = GM_DEC_RECO_FAVORABLE;
      else if(r.overall_confidence >= 55.0)
         r.recommendation = GM_DEC_RECO_NORMAL;
      else if(r.overall_confidence >= 40.0)
         r.recommendation = GM_DEC_RECO_CAUTION;
      else
         r.recommendation = GM_DEC_RECO_UNCERTAIN;
     }
  };

#endif // GM_CDECISION_MATRIX_ENGINE_MQH
//+------------------------------------------------------------------+
