//+------------------------------------------------------------------+
//|                                       CUnifiedAIStatusEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CUNIFIED_AI_STATUS_ENGINE_MQH
#define GM_CUNIFIED_AI_STATUS_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMasterControlResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../Memory/SGmMemoryLearningResult.mqh"
#include "../Reporting/SGmReportingResult.mqh"
#include "../RiskIntelligence/SGmRiskIntelligenceResult.mqh"
#include "../Forecasting/SGmForecastResult.mqh"
#include "../Conversation/SGmConversationResult.mqh"
#include "../Enterprise/SGmEnterpriseResult.mqh"
#include "../Orchestration/SGmOrchestrationResult.mqh"

class CGmUnifiedAIStatusEngine
  {
public:
   void Analyze(const SGmAssistantResult &sup,
                const SGmMemoryLearningResult &mem,
                const SGmReportingResult &rpt,
                const SGmRiskIntelligenceResult &risk,
                const SGmForecastResult &fcst,
                const SGmConversationResult &chat,
                const SGmEnterpriseResult &ent,
                const SGmOrchestrationResult &orch,
                SGmMasterControlResult &r)
     {
      r.supervisor_status = sup.valid ? (sup.supervisor_status + " OK") : "Offline";
      string learning_mod = mem.valid ? "Active" : "Warming";
      r.reporting_status = rpt.valid ? "Active" : "Warming";
      string risk_mod = risk.valid ? "Active" : "Warming";
      r.forecast_status = fcst.valid ? "Active" : "Warming";
      r.assistant_status = chat.valid ? "Active" : "Warming";
      r.enterprise_status = ent.valid ? "Active" : "Warming";
      r.orchestration_status = orch.valid ? "Active" : "Warming";
      r.database_status = "File-backed AI DBs Ready";
      r.api_status = "Read-only observation APIs Ready";

      int up = 0;
      if(sup.valid) up++;
      if(mem.valid) up++;
      if(rpt.valid) up++;
      if(risk.valid) up++;
      if(fcst.valid) up++;
      if(chat.valid) up++;
      if(ent.valid) up++;
      if(orch.valid) up++;

      double score = 40.0 + (double)up * 6.5;
      if(sup.valid) score += 0.08 * MathMax(sup.system_health_score, 0.0);
      if(orch.valid) score += 0.08 * orch.intelligence_score;
      r.ai_health_score = GmMccClamp(score);

      if(r.ai_health_score >= 94.0)
         r.ai_health_grade = GM_MCC_GRADE_A_PLUS;
      else if(r.ai_health_score >= 85.0)
         r.ai_health_grade = GM_MCC_GRADE_A;
      else if(r.ai_health_score >= 70.0)
         r.ai_health_grade = GM_MCC_GRADE_B;
      else
         r.ai_health_grade = GM_MCC_GRADE_C;

      r.panel_system_health = StringFormat("%.0f/100 | %s | ModulesUp=%d/8",
                                           r.ai_health_score, GmMccGradeName(r.ai_health_grade), up);

      r.unified_status_report = StringFormat(
                                   "Overall AI Health Score:\r\nAI Health Score:\r\n%.0f/100\r\n\r\nGrade:\r\n%s\r\n\r\nSupervisor=%s\r\nLearning=%s\r\nReporting=%s\r\nRisk=%s\r\nForecast=%s\r\nAssistant=%s\r\nEnterprise=%s\r\nOrchestration=%s\r\nDatabase=%s\r\nAPI=%s\r\n%s\r\n",
                                   r.ai_health_score, GmMccGradeName(r.ai_health_grade),
                                   r.supervisor_status, learning_mod, r.reporting_status,
                                   risk_mod, r.forecast_status, r.assistant_status,
                                   r.enterprise_status, r.orchestration_status,
                                   r.database_status, r.api_status, GM_MCC_ANALYSIS_ONLY);
     }
  };

#endif // GM_CUNIFIED_AI_STATUS_ENGINE_MQH
//+------------------------------------------------------------------+
