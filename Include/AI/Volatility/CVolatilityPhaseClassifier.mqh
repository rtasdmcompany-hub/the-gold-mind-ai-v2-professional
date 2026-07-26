//+------------------------------------------------------------------+
//|                                CVolatilityPhaseClassifier.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CVOLATILITY_PHASE_CLASSIFIER_MQH
#define GM_CVOLATILITY_PHASE_CLASSIFIER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmVolatilityAnalysisResult.mqh"

/// @brief Volatility market-phase classifier (ANALYSIS ONLY).
class CGmVolatilityPhaseClassifier
  {
public:
   void Classify(SGmVolatilityAnalysisResult &r)
     {
      // Exhaustion: high energy but decelerating hard
      if(r.energy_score >= 65.0 && r.atr_deceleration >= 8.0 && r.atr_compression)
        {
         r.phase = GM_VOL_PHASE_EXHAUSTED;
         r.phase_confidence = GmClamp01(55.0 + r.atr_deceleration);
         return;
        }

      // News-like spike: extreme acceleration + expansion
      if(r.atr_acceleration >= 12.0 && r.energy_score >= 75.0)
        {
         r.phase = GM_VOL_PHASE_NEWS_DRIVEN;
         r.phase_confidence = GmClamp01(60.0 + r.atr_acceleration);
         return;
        }

      if(r.energy == GM_ENERGY_EXPLOSIVE || r.energy_score >= 88.0)
        {
         r.phase = GM_VOL_PHASE_EXPLOSIVE;
         r.phase_confidence = GmClamp01(r.energy_score);
         return;
        }

      if(r.atr_expansion && r.energy_score >= 60.0)
        {
         r.phase = GM_VOL_PHASE_VOLATILE;
         r.phase_confidence = GmClamp01(50.0 + r.relative_vol * 0.4);
         return;
        }

      if(r.atr_expansion)
        {
         r.phase = GM_VOL_PHASE_EXPANDING;
         r.phase_confidence = GmClamp01(50.0 + r.atr_strength * 0.4);
         return;
        }

      if(r.atr_compression)
        {
         r.phase = GM_VOL_PHASE_CONTRACTING;
         r.phase_confidence = GmClamp01(50.0 + (100.0 - r.atr_strength) * 0.3);
         return;
        }

      if(r.energy == GM_ENERGY_LOW || r.energy_score < 25.0)
        {
         r.phase = GM_VOL_PHASE_CALM;
         r.phase_confidence = GmClamp01(55.0 + r.vol_stability * 0.3);
         return;
        }

      r.phase = GM_VOL_PHASE_NORMAL;
      r.phase_confidence = GmClamp01(50.0 + r.vol_stability * 0.25);
     }
  };

#endif // GM_CVOLATILITY_PHASE_CLASSIFIER_MQH
//+------------------------------------------------------------------+
