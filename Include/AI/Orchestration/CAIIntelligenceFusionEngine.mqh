//+------------------------------------------------------------------+
//|                               CAIIntelligenceFusionEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_INTELLIGENCE_FUSION_ENGINE_MQH
#define GM_CAI_INTELLIGENCE_FUSION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmOrchestrationResult.mqh"
#include "../Intelligence/SGmIntelligenceResult.mqh"
#include "../RiskIntelligence/SGmRiskIntelligenceResult.mqh"
#include "../Forecasting/SGmForecastResult.mqh"
#include "../Memory/SGmMemoryLearningResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"

class CGmAIIntelligenceFusionEngine
  {
public:
   void Analyze(const SGmIntelligenceResult &intel,
                const SGmRiskIntelligenceResult &risk,
                const SGmForecastResult &fcst,
                const SGmMemoryLearningResult &mem,
                const SGmAssistantResult &sup,
                SGmOrchestrationResult &r)
     {
      r.market_score_in = intel.valid ? intel.market_score : 55.0;
      r.risk_score_in = risk.valid
                        ? GmOrchClamp(0.5 * risk.capital_protection_score +
                                      0.3 * risk.exposure_score +
                                      0.2 * (100.0 - risk.risk_probability))
                        : 55.0;
      r.learning_score_in = mem.valid ? mem.calibrated_confidence : 55.0;
      r.forecast_score_in = fcst.valid
                            ? GmOrchClamp(0.55 * fcst.forecast_confidence + 0.45 * fcst.accuracy_score)
                            : 55.0;
      r.system_score_in = sup.valid
                          ? MathMax(sup.overall_health_score, MathMax(sup.system_health_score, 0.0))
                          : 55.0;

      r.intelligence_score = GmOrchClamp(
                                0.22 * r.market_score_in +
                                0.22 * r.risk_score_in +
                                0.18 * r.learning_score_in +
                                0.20 * r.forecast_score_in +
                                0.18 * r.system_score_in);

      if(r.intelligence_score >= 90.0)
        {
         r.intelligence_grade = GM_ORCH_GRADE_A_PLUS;
         r.intelligence_status = "Optimal Monitoring Condition";
        }
      else if(r.intelligence_score >= 80.0)
        {
         r.intelligence_grade = GM_ORCH_GRADE_A;
         r.intelligence_status = "Strong Monitoring Condition";
        }
      else if(r.intelligence_score >= 70.0)
        {
         r.intelligence_grade = GM_ORCH_GRADE_B;
         r.intelligence_status = "Healthy Monitoring Condition";
        }
      else if(r.intelligence_score >= 55.0)
        {
         r.intelligence_grade = GM_ORCH_GRADE_C;
         r.intelligence_status = "Cautious Monitoring Condition";
        }
      else
        {
         r.intelligence_grade = GM_ORCH_GRADE_D;
         r.intelligence_status = "Attention Monitoring Condition";
        }

      r.fusion_report = StringFormat(
                           "Overall AI Intelligence Score:\r\nAI Intelligence Score:\r\n%.0f/100\r\n\r\nGrade:\r\n%s\r\n\r\nStatus:\r\n%s\r\n\r\nInputs M=%.0f R=%.0f L=%.0f F=%.0f S=%.0f\r\n%s\r\n",
                           r.intelligence_score, GmOrchGradeName(r.intelligence_grade),
                           r.intelligence_status,
                           r.market_score_in, r.risk_score_in, r.learning_score_in,
                           r.forecast_score_in, r.system_score_in,
                           GM_ORCH_ANALYSIS_ONLY);
     }
  };

#endif // GM_CAI_INTELLIGENCE_FUSION_ENGINE_MQH
//+------------------------------------------------------------------+
