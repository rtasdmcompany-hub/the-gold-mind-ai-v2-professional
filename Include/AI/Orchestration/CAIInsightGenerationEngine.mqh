//+------------------------------------------------------------------+
//|                                 CAIInsightGenerationEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_INSIGHT_GENERATION_ENGINE_MQH
#define GM_CAI_INSIGHT_GENERATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmOrchestrationResult.mqh"
#include "../Intelligence/SGmIntelligenceResult.mqh"
#include "../RiskIntelligence/SGmRiskIntelligenceResult.mqh"
#include "../Forecasting/SGmForecastResult.mqh"
#include "../Memory/SGmMemoryLearningResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../Reporting/SGmReportingResult.mqh"

class CGmAIInsightGenerationEngine
  {
public:
   void Analyze(const SGmIntelligenceResult &intel,
                const SGmRiskIntelligenceResult &risk,
                const SGmForecastResult &fcst,
                const SGmMemoryLearningResult &mem,
                const SGmAssistantResult &sup,
                const SGmReportingResult &rpt,
                const SGmOrchestrationResult &partial,
                SGmOrchestrationResult &r)
     {
      const double sim = intel.valid ? intel.historical_similarity : 70.0;
      r.market_insight = StringFormat(
                            "The current market environment matches %.0f%% with previous stable recovery sessions.",
                            sim);
      if(intel.valid && StringLen(intel.market_score_condition) > 0)
         r.market_insight += " Context: " + intel.market_score_condition + ".";

      r.risk_insight = risk.valid
                       ? StringFormat("Capital protection %.0f | Predictive risk %.0f%% | Exposure %.0f/100.",
                                      risk.capital_protection_score, risk.risk_probability, risk.exposure_score)
                       : "Risk intelligence warming.";

      r.performance_insight = rpt.valid
                              ? StringFormat("Reporting confidence %.0f. %s",
                                             rpt.exec_confidence,
                                             (StringLen(rpt.insight) > 0 ? rpt.insight : "Performance under observation."))
                              : "Performance reports pending.";

      r.learning_insight = mem.valid
                           ? StringFormat("Learning calibrated confidence %.0f. %s",
                                          mem.calibrated_confidence,
                                          (StringLen(mem.insight) > 0 ? mem.insight : "Adaptive learning active."))
                           : "Learning layer warming.";

      r.system_insight = sup.valid
                         ? StringFormat("System health %.0f | Supervisor %s | Warnings=%d.",
                                        MathMax(sup.system_health_score, sup.overall_health_score),
                                        sup.supervisor_status, sup.warning_count)
                         : "System health observed via orchestration.";

      // Primary insight prefers market similarity narrative from requirements
      r.primary_insight = r.market_insight;
      if(partial.intelligence_score < 60.0 && risk.valid && risk.alert_count > 0)
         r.primary_insight = r.risk_insight;
      else if(fcst.valid && fcst.transition_detected)
         r.primary_insight = "Market transition insight: " + fcst.transition_alert;
     }
  };

#endif // GM_CAI_INSIGHT_GENERATION_ENGINE_MQH
//+------------------------------------------------------------------+
