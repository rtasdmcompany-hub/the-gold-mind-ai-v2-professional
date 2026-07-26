//+------------------------------------------------------------------+
//|                              CConfidenceCalibrationEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Calibrates advisory confidence — NEVER gates execution      |
//+------------------------------------------------------------------+
#ifndef GM_CCONFIDENCE_CALIBRATION_ENGINE_MQH
#define GM_CCONFIDENCE_CALIBRATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMemoryLearningResult.mqh"
#include "../Intelligence/SGmIntelligenceResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"

class CGmConfidenceCalibrationEngine
  {
public:
   void Analyze(const SGmIntelligenceResult &intel,
                const SGmAssistantResult &sup,
                const SGmMemoryLearningResult &partial,
                SGmMemoryLearningResult &r)
     {
      double prev = 50.0;
      if(intel.valid)
         prev = intel.ai_confidence;
      else if(sup.valid)
         prev = sup.overall_health_score;

      r.previous_confidence = GmMemClamp(prev);
      double adj = prev;
      string reason = "Stable calibration";

      // Soft penalties / boosts (informational only)
      if(intel.valid && intel.risk_advisory == GM_RISK_ADV_HIGH)
        {
         adj -= 8.0;
         reason = "Market uncertainty / high risk advisory";
        }
      else if(intel.valid && intel.risk_advisory == GM_RISK_ADV_ELEVATED)
        {
         adj -= 5.0;
         reason = "Elevated risk environment";
        }

      if(partial.behavior_type == GM_BEH_FAKE_BREAKOUT ||
         partial.behavior_type == GM_BEH_LOW_LIQUIDITY)
        {
         adj -= 4.0;
         reason = "Behavior uncertainty increased";
        }

      if(partial.learning_accuracy >= 85.0 && adj < prev)
        {
         adj += 2.0;
         reason = "Learning accuracy supports mild confidence restore";
        }

      if(sup.valid && sup.warning_count >= 3)
        {
         adj -= 3.0;
         reason = "Multiple supervisory warnings active";
        }

      if(partial.top_pattern.active && partial.top_pattern.success_rate >= 85.0)
        {
         adj += 2.5;
         if(StringFind(reason, "uncertainty") < 0 && StringFind(reason, "warnings") < 0)
            reason = "Strong historical pattern match";
        }

      r.calibrated_confidence = GmMemClamp(adj);
      r.calibration_reason = reason;
     }
  };

#endif // GM_CCONFIDENCE_CALIBRATION_ENGINE_MQH
//+------------------------------------------------------------------+
