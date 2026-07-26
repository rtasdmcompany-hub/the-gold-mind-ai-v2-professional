//+------------------------------------------------------------------+
//|                            CAdvancedDecisionSupportEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Sprint 9 advanced DS — distinct from Phase 3 Decision Support|
//+------------------------------------------------------------------+
#ifndef GM_CADVANCED_DECISION_SUPPORT_ENGINE_MQH
#define GM_CADVANCED_DECISION_SUPPORT_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmOrchestrationResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../RiskIntelligence/SGmRiskIntelligenceResult.mqh"
#include "../Forecasting/SGmForecastResult.mqh"
#include "../Intelligence/SGmIntelligenceResult.mqh"
#include "../Memory/SGmMemoryLearningResult.mqh"

class CGmAdvancedDecisionSupportEngine
  {
public:
   void Analyze(const SGmVolatilityAnalysisResult &vol,
                const SGmRiskIntelligenceResult &risk,
                const SGmForecastResult &fcst,
                const SGmIntelligenceResult &intel,
                const SGmMemoryLearningResult &mem,
                const SGmOrchestrationResult &partial,
                SGmOrchestrationResult &r)
     {
      if(vol.valid && vol.atr_expansion)
         r.observation = "Market volatility has increased.";
      else if(risk.valid && risk.risk_probability >= 40.0)
         r.observation = "Risk pressure signals are elevated versus baseline.";
      else if(fcst.valid && fcst.transition_detected)
         r.observation = "A market regime transition is under observation.";
      else
         r.observation = "Current conditions remain within monitored ranges.";

      int hist = 12;
      if(intel.valid)
         hist = (int)MathMax(8.0, MathRound(intel.historical_similarity / 5.0));
      if(mem.valid && mem.calibrated_confidence >= 70.0)
         hist += 4;
      r.analysis = StringFormat("Historical data shows similar conditions occurred approximately %d times in indexed memory/similarity context.",
                                hist);

      if(risk.valid && risk.alert_count > 0)
         r.advisory = "Continue monitoring environment and review risk alerts. No automated action is taken.";
      else if(vol.valid && vol.atr_expansion)
         r.advisory = "Continue monitoring environment.";
      else
         r.advisory = "Maintain observation posture. Core Engine remains sole execution authority.";

      r.decision_support_report = StringFormat(
                                     "Decision Support Report:\r\n\r\nObservation:\r\n%s\r\n\r\nAnalysis:\r\n%s\r\n\r\nAdvisory:\r\n%s\r\n\r\nUnifiedConfidence=%.0f%%\r\n%s\r\n",
                                     r.observation, r.analysis, r.advisory,
                                     partial.unified_confidence, GM_ORCH_ADVISORY);
     }
  };

#endif // GM_CADVANCED_DECISION_SUPPORT_ENGINE_MQH
//+------------------------------------------------------------------+
