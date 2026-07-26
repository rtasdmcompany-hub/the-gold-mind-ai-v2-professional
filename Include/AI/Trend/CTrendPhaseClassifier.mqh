//+------------------------------------------------------------------+
//|                                     CTrendPhaseClassifier.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CTREND_PHASE_CLASSIFIER_MQH
#define GM_CTREND_PHASE_CLASSIFIER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmTrendAnalysisResult.mqh"

class CGmTrendPhaseClassifier
  {
public:
   void Classify(SGmTrendAnalysisResult &r)
     {
      r.phase = GM_TREND_PHASE_UNCERTAIN;

      if(r.choch_up || r.choch_down || r.trend_exhaustion >= 55.0)
         r.phase = GM_TREND_PHASE_TRANSITION;
      else if(r.liq_sweep_low && r.primary != GM_TREND_DIR_BEAR && r.strength_score < 45.0)
         r.phase = GM_TREND_PHASE_ACCUMULATION;
      else if(r.liq_sweep_high && r.primary != GM_TREND_DIR_BULL && r.strength_score < 45.0)
         r.phase = GM_TREND_PHASE_DISTRIBUTION;
      else if(r.primary == GM_TREND_DIR_FLAT || r.strength_score < 25.0)
         r.phase = GM_TREND_PHASE_SIDEWAYS;
      else if(r.primary == GM_TREND_DIR_BULL)
        {
         if(r.strength_score >= 70.0 && r.trend_stability >= 60.0)
            r.phase = GM_TREND_PHASE_STRONG_BULL;
         else if(r.strength_score >= 45.0)
            r.phase = GM_TREND_PHASE_BULL;
         else
            r.phase = GM_TREND_PHASE_WEAK_BULL;
        }
      else if(r.primary == GM_TREND_DIR_BEAR)
        {
         if(r.strength_score >= 70.0 && r.trend_stability >= 60.0)
            r.phase = GM_TREND_PHASE_STRONG_BEAR;
         else if(r.strength_score >= 45.0)
            r.phase = GM_TREND_PHASE_BEAR;
         else
            r.phase = GM_TREND_PHASE_WEAK_BEAR;
        }

      // Confidence blend
      r.confidence = MathMin(98.0,
                             MathMax(r.confidence,
                                     45.0 + r.strength_score * 0.2 + r.agreement_score * 0.2));
     }
  };

#endif // GM_CTREND_PHASE_CLASSIFIER_MQH
//+------------------------------------------------------------------+
