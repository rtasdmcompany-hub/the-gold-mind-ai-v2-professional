//+------------------------------------------------------------------+
//|                            CAIKnowledgeOrchestrationEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_KNOWLEDGE_ORCHESTRATION_ENGINE_MQH
#define GM_CAI_KNOWLEDGE_ORCHESTRATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmOrchestrationResult.mqh"
#include "../Intelligence/SGmIntelligenceResult.mqh"
#include "../RiskIntelligence/SGmRiskIntelligenceResult.mqh"
#include "../Forecasting/SGmForecastResult.mqh"
#include "../Memory/SGmMemoryLearningResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../Reporting/SGmReportingResult.mqh"

class CGmAIKnowledgeOrchestrationEngine
  {
public:
   void Analyze(const SGmIntelligenceResult &intel,
                const SGmRiskIntelligenceResult &risk,
                const SGmForecastResult &fcst,
                const SGmMemoryLearningResult &mem,
                const SGmAssistantResult &sup,
                const SGmReportingResult &rpt,
                SGmOrchestrationResult &r)
     {
      if(intel.valid && intel.market_score >= 70.0)
         r.market_status = "Stable";
      else if(intel.valid && intel.market_score >= 50.0)
         r.market_status = "Mixed";
      else if(fcst.valid && fcst.outlook == GM_FCST_OUTLOOK_NEGATIVE)
         r.market_status = "Cautious";
      else
         r.market_status = "Observed";

      if(risk.valid)
        {
         if(risk.risk_level == GM_RISK_LEVEL_LOW)
            r.risk_status = "Controlled";
         else if(risk.risk_level == GM_RISK_LEVEL_MODERATE)
            r.risk_status = "Monitored";
         else
            r.risk_status = "Elevated Watch";
        }
      else
         r.risk_status = "Observed";

      if(mem.valid)
         r.learning_status = (mem.calibrated_confidence >= 70.0) ? "Improving" : "Adapting";
      else
         r.learning_status = "Warming";

      if(sup.valid && sup.system_health_score >= 80.0)
         r.system_status = "Healthy";
      else if(sup.valid && sup.system_health_score >= 60.0)
         r.system_status = "Stable";
      else
         r.system_status = "Watch";

      r.unified_confidence = GmOrchClamp(
                                0.22 * (intel.valid ? intel.ai_confidence : 55.0) +
                                0.22 * (risk.valid ? risk.confidence : 55.0) +
                                0.20 * (fcst.valid ? fcst.forecast_confidence : 55.0) +
                                0.18 * (mem.valid ? mem.calibrated_confidence : 55.0) +
                                0.18 * (sup.valid ? MathMax(sup.overall_health_score, sup.system_health_score) : 55.0));

      r.unified_profile = StringFormat(
                             "THE GOLD MIND AI INTELLIGENCE STATUS\r\n\r\nMarket:\r\n%s\r\n\r\nRisk:\r\n%s\r\n\r\nLearning:\r\n%s\r\n\r\nSystem:\r\n%s\r\n\r\nAI Confidence:\r\n%.0f%%\r\n\r\n%s\r\n",
                             r.market_status, r.risk_status, r.learning_status, r.system_status,
                             r.unified_confidence, GM_ORCH_ANALYSIS_ONLY);

      r.market_intel_panel = intel.valid
                             ? StringFormat("Mkt=%.0f | %s", intel.market_score, intel.market_score_condition)
                             : "—";
      r.risk_intel_panel = risk.valid
                           ? StringFormat("Cap=%.0f Pred=%.0f%% Exp=%.0f",
                                          risk.capital_protection_score, risk.risk_probability,
                                          risk.exposure_score)
                           : "—";
      r.forecast_intel_panel = fcst.valid
                               ? StringFormat("%s | Acc=%.0f%%",
                                              GmFcstOutlookName(fcst.outlook), fcst.accuracy_score)
                               : "—";
      r.learning_intel_panel = mem.valid
                               ? StringFormat("Cal=%.0f | %s", mem.calibrated_confidence,
                                              (StringLen(mem.insight) > 0 ? mem.insight : "Learning active"))
                               : "—";
      if(rpt.valid && StringLen(r.learning_intel_panel) > 0)
         r.learning_intel_panel += StringFormat(" | RptConf=%.0f", rpt.exec_confidence);
     }
  };

#endif // GM_CAI_KNOWLEDGE_ORCHESTRATION_ENGINE_MQH
//+------------------------------------------------------------------+
