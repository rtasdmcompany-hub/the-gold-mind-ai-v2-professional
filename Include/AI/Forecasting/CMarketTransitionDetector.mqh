//+------------------------------------------------------------------+
//|                                  CMarketTransitionDetector.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CMARKET_TRANSITION_DETECTOR_MQH
#define GM_CMARKET_TRANSITION_DETECTOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmForecastResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../Trend/TrendAIConstants.mqh"

class CGmMarketTransitionDetector
  {
private:
   ENUM_GM_FCST_REGIME Classify(const SGmTrendAnalysisResult &trend,
                                const SGmVolatilityAnalysisResult &vol,
                                const SGmAssistantResult &sup) const
     {
      if(sup.valid && (sup.recovery_active || StringFind(sup.recovery_status, "Recovery") >= 0))
         return GM_FCST_REGIME_RECOVERY;
      if(vol.valid && vol.atr_expansion && vol.energy_score >= 70.0)
         return GM_FCST_REGIME_VOLATILE;
      if(trend.valid && trend.trend_stability < 35.0 && vol.valid && vol.atr_expansion)
         return GM_FCST_REGIME_UNSTABLE;
      if(trend.valid && trend.trend_stability >= 55.0 &&
         trend.primary != GM_TREND_DIR_FLAT && trend.primary != GM_TREND_DIR_UNKNOWN)
         return GM_FCST_REGIME_TRENDING;
      if(vol.valid && vol.atr_compression)
         return GM_FCST_REGIME_SIDEWAYS;
      if(trend.valid && (trend.primary == GM_TREND_DIR_FLAT || trend.trend_stability < 45.0))
         return GM_FCST_REGIME_SIDEWAYS;
      return GM_FCST_REGIME_TRENDING;
     }

public:
   void Analyze(const SGmTrendAnalysisResult &trend,
                const SGmVolatilityAnalysisResult &vol,
                const SGmAssistantResult &sup,
                const ENUM_GM_FCST_REGIME prev_regime,
                SGmForecastResult &r)
     {
      r.regime_to = Classify(trend, vol, sup);
      r.regime_from = (prev_regime != GM_FCST_REGIME_UNKNOWN) ? prev_regime : r.regime_to;
      r.transition_detected = (r.regime_from != r.regime_to);

      r.transition_confidence = 55.0;
      if(trend.valid) r.transition_confidence += trend.confidence * 0.15;
      if(vol.valid) r.transition_confidence += vol.phase_confidence * 0.15;
      if(r.transition_detected) r.transition_confidence += 10.0;
      r.transition_confidence = GmFcstClamp(r.transition_confidence);

      if(r.transition_detected)
         r.transition_alert = StringFormat("Transition Detected:\r\n%s → %s\r\n\r\nConfidence:\r\n%.0f%%",
                                           GmFcstRegimeName(r.regime_from),
                                           GmFcstRegimeName(r.regime_to),
                                           r.transition_confidence);
      else
         r.transition_alert = StringFormat("No Transition:\r\nRegime=%s | Confidence=%.0f%%",
                                           GmFcstRegimeName(r.regime_to),
                                           r.transition_confidence);
     }
  };

#endif // GM_CMARKET_TRANSITION_DETECTOR_MQH
//+------------------------------------------------------------------+
