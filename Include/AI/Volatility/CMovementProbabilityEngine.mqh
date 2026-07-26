//+------------------------------------------------------------------+
//|                               CMovementProbabilityEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CMOVEMENT_PROBABILITY_ENGINE_MQH
#define GM_CMOVEMENT_PROBABILITY_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmVolatilityAnalysisResult.mqh"

/// @brief Movement probability estimates only — NEVER a trade signal.
class CGmMovementProbabilityEngine
  {
public:
   void Analyze(SGmVolatilityAnalysisResult &r)
     {
      // Large vs small move from energy + expansion
      r.prob_large_move = GmClamp01(20.0 + r.energy_score * 0.55 +
                                    (r.atr_expansion ? 12.0 : 0.0));
      r.prob_small_move = GmClamp01(100.0 - r.prob_large_move);

      // Breakout more likely under compression then building energy
      r.prob_breakout = GmClamp01(15.0 +
                                  (r.atr_compression ? 25.0 : 0.0) +
                                  (r.energy == GM_ENERGY_BUILDING ? 20.0 : 0.0) +
                                  r.relative_vol * 0.25);

      // Continuation vs reversal from stability / exhaustion phase
      r.prob_continuation = GmClamp01(35.0 + r.vol_stability * 0.35 +
                                      (r.atr_expansion ? 10.0 : 0.0));
      r.prob_reversal = GmClamp01(25.0 +
                                  (r.phase == GM_VOL_PHASE_EXHAUSTED ? 30.0 : 0.0) +
                                  r.atr_deceleration * 1.5);
      // Normalize continuation/reversal soft split
      const double cr = r.prob_continuation + r.prob_reversal;
      if(cr > 100.0)
        {
         r.prob_continuation = r.prob_continuation / cr * 100.0;
         r.prob_reversal = r.prob_reversal / cr * 100.0;
        }

      r.prob_confidence = GmClamp01(40.0 + r.vol_confidence * 0.35 +
                                    r.phase_confidence * 0.25);
     }
  };

#endif // GM_CMOVEMENT_PROBABILITY_ENGINE_MQH
//+------------------------------------------------------------------+
