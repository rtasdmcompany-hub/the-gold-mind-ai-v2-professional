//+------------------------------------------------------------------+
//|                                       CForwardTestEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CFORWARD_TEST_ENGINE_MQH
#define GM_CFORWARD_TEST_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmAIValidationResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../Confidence/SGmConfidenceAnalysisResult.mqh"
#include "../Decision/SGmDecisionSupportResult.mqh"
#include "../Learning/SGmLearningAnalysisResult.mqh"

/// @brief Live forward-test: AI prediction vs recent outcomes (analytical).
class CGmForwardTestEngine
  {
private:
   double m_prev_conf;
   double m_prev_pred;
   int    m_samples;

public:
                     CGmForwardTestEngine(void)
                       : m_prev_conf(-1.0), m_prev_pred(-1.0), m_samples(0) {}

   void Analyze(const SGmTrendAnalysisResult &trend,
                const SGmVolatilityAnalysisResult &vol,
                const SGmConfidenceAnalysisResult &conf,
                const SGmDecisionSupportResult &dec,
                const SGmLearningAnalysisResult &learn,
                SGmAIValidationResult &r)
     {
      // Soft live accuracy from learning outcomes + decision similarity
      if(learn.valid)
        {
         r.prediction_accuracy = learn.prediction_accuracy;
         r.confidence_accuracy = learn.confidence_accuracy;
         r.recommendation_accuracy = learn.recommendation_accuracy;
         r.pattern_accuracy = learn.pattern_accuracy;
         r.historical_correlation = learn.historical_correlation;
        }

      if(trend.valid)
         r.trend_accuracy = GmAiValClamp(trend.confidence * 0.5 + trend.trend_stability * 0.5);
      if(vol.valid)
         r.volatility_accuracy = GmAiValClamp(vol.vol_confidence);
      if(conf.valid)
        {
         r.market_quality_accuracy = GmAiValClamp(conf.market_quality);
         // Confidence accuracy vs historical success (if available)
         if(learn.valid && learn.trades_studied > 0)
            r.confidence_accuracy = GmAiValClamp(100.0 - MathAbs(conf.overall_confidence - learn.historical_success_rate));
        }
      if(dec.valid)
        {
         r.strategy_match_accuracy = GmAiValClamp(
            (dec.strategy_match == GM_DEC_MATCH_VERY_STRONG) ? 90.0 :
            (dec.strategy_match == GM_DEC_MATCH_STRONG) ? 75.0 :
            (dec.strategy_match == GM_DEC_MATCH_AVERAGE) ? 55.0 :
            (dec.strategy_match == GM_DEC_MATCH_WEAK) ? 35.0 : 40.0);
         r.similarity_accuracy = GmAiValClamp(dec.historical_similarity);
         r.recommendation_accuracy = GmAiValClamp(
            0.5 * r.recommendation_accuracy + 0.5 * dec.overall_confidence);
        }

      // News accuracy soft proxy from decision news factor if present
      r.news_accuracy = 55.0;
      if(learn.valid)
         r.news_accuracy = GmAiValClamp(50.0 + (100.0 - MathMin(100.0, learn.confidence)) * 0.1 +
                                        r.prediction_accuracy * 0.35);

      r.forward_test_score = GmAiValClamp(
         r.prediction_accuracy * 0.30 +
         r.confidence_accuracy * 0.25 +
         r.recommendation_accuracy * 0.20 +
         r.trend_accuracy * 0.15 +
         r.volatility_accuracy * 0.10);

      m_samples++;
      m_prev_conf = conf.valid ? conf.overall_confidence : m_prev_conf;
      m_prev_pred = r.prediction_accuracy;

      r.forward_status = StringFormat("LIVE | samples=%d score=%.0f | predErr~%.0f",
                                      m_samples, r.forward_test_score,
                                      GmAiValClamp(100.0 - r.prediction_accuracy));
     }
  };

#endif // GM_CFORWARD_TEST_ENGINE_MQH
//+------------------------------------------------------------------+
