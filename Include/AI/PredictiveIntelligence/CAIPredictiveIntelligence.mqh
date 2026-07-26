//+------------------------------------------------------------------+
//|                              CAIPredictiveIntelligence.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_PREDICTIVE_INTELLIGENCE_MQH
#define GM_CAI_PREDICTIVE_INTELLIGENCE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmPredictiveIntelligenceResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../OrderFlow/SGmOrderFlowResult.mqh"
#include "../NewsIntelligence/SGmNewsIntelligenceResult.mqh"
#include "../MarketIntelligence/SGmMarketIntelligenceResult.mqh"
#include "../MultiTimeframe/SGmMultiTimeframeResult.mqh"
#include "../Forecasting/SGmForecastResult.mqh"

class CGmAIPredictiveIntelligence
  {
public:
   void Analyze(const SGmTrendAnalysisResult &trend,
                const SGmVolatilityAnalysisResult &vol,
                const SGmOrderFlowResult &of,
                const SGmNewsIntelligenceResult &ni,
                const SGmMarketIntelligenceResult &mi,
                const SGmMultiTimeframeResult &mtf,
                const SGmForecastResult &fcst,
                SGmPredictiveIntelligenceResult &r)
     {
      const double trend_q = trend.valid ? trend.strength_score : 50.0;
      const double mom_q = trend.valid ? trend.momentum_strength
                           : (mi.valid ? mi.momentum_index : 50.0);
      const double atr_q = vol.valid ? vol.atr_strength : 50.0;
      const double vol_q = vol.valid ? vol.energy_score
                           : (of.valid ? of.energy_score : 50.0);
      const double liq_q = of.valid ? of.session_liquidity
                           : (mi.valid ? mi.liquidity_score : 55.0);
      const double struct_q = mi.valid ? mi.structure_quality
                              : (mtf.valid ? mtf.h4_structure_score : 50.0);
      const double news_q = ni.valid ? GmPredClamp(100.0 - ni.news_impact_score * 0.3) : 60.0;
      const double hist_q = mtf.valid ? mtf.historical_similarity
                            : (fcst.valid && StringLen(fcst.historical_match) > 0 ? 62.0 : 50.0);
      const double sess_q = of.valid ? of.session_strength : 55.0;
      const double sync_q = mtf.valid ? mtf.synchronization_score : 55.0;
      const double fcst_q = fcst.valid ? fcst.forecast_confidence : 50.0;

      r.prediction_confidence = GmPredClamp(
                                   0.14 * trend_q + 0.12 * mom_q + 0.12 * atr_q +
                                   0.10 * vol_q + 0.10 * liq_q + 0.10 * struct_q +
                                   0.08 * news_q + 0.08 * hist_q + 0.08 * sess_q +
                                   0.08 * sync_q);

      r.forecast_reliability = GmPredClamp(
                                  0.40 * r.prediction_confidence +
                                  0.30 * fcst_q +
                                  0.20 * (fcst.valid ? fcst.accuracy_score : 55.0) +
                                  0.10 * sync_q);

      // Soft dominant scenario probability placeholder until simulator fills
      r.scenario_probability = GmPredClamp(
                                  0.50 * r.prediction_confidence +
                                  0.50 * (fcst.valid ? MathMax(fcst.scn_continuation,
                                                               MathMax(fcst.scn_range, fcst.scn_reversal))
                                                     : 55.0));

      r.predictive_report = StringFormat(
                               "AI Predictive Engine:\r\nConf=%.0f Reliability=%.0f ScnProb=%.0f\r\nTrend=%.0f Mom=%.0f ATR=%.0f Vol=%.0f Liq=%.0f\r\nStruct=%.0f News=%.0f Hist=%.0f Sess=%.0f Sync=%.0f\r\n%s | %s\r\n",
                               r.prediction_confidence, r.forecast_reliability, r.scenario_probability,
                               trend_q, mom_q, atr_q, vol_q, liq_q,
                               struct_q, news_q, hist_q, sess_q, sync_q,
                               GM_PRED_CONTEXT, GM_PRED_ANALYSIS_ONLY);
     }
  };

#endif // GM_CAI_PREDICTIVE_INTELLIGENCE_MQH
//+------------------------------------------------------------------+
