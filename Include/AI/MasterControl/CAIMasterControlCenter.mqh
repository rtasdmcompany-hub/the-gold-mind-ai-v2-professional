//+------------------------------------------------------------------+
//|                                    CAIMasterControlCenter.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_MASTER_CONTROL_CENTER_MQH
#define GM_CAI_MASTER_CONTROL_CENTER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMasterControlResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../Intelligence/SGmIntelligenceResult.mqh"
#include "../RiskIntelligence/SGmRiskIntelligenceResult.mqh"
#include "../Forecasting/SGmForecastResult.mqh"
#include "../Memory/SGmMemoryLearningResult.mqh"
#include "../Orchestration/SGmOrchestrationResult.mqh"
#include "../Enterprise/SGmEnterpriseResult.mqh"
#include "../Reporting/SGmReportingResult.mqh"
#include "../Conversation/SGmConversationResult.mqh"
#include "../Conversation/ConversationAIConstants.mqh"
#include "../Forecasting/ForecastingAIConstants.mqh"
#include "../RiskIntelligence/RiskIntelligenceConstants.mqh"
#include "../Orchestration/OrchestrationAIConstants.mqh"

class CGmAIMasterControlCenter
  {
public:
   void Analyze(const SGmAssistantResult &sup,
                const SGmIntelligenceResult &intel,
                const SGmRiskIntelligenceResult &risk,
                const SGmForecastResult &fcst,
                const SGmMemoryLearningResult &mem,
                const SGmOrchestrationResult &orch,
                const SGmEnterpriseResult &ent,
                const SGmReportingResult &rpt,
                const SGmConversationResult &chat,
                SGmMasterControlResult &r)
     {
      if(sup.valid && MathMax(sup.system_health_score, sup.overall_health_score) >= 88.0)
         r.system_health = "Excellent";
      else if(sup.valid && MathMax(sup.system_health_score, sup.overall_health_score) >= 75.0)
         r.system_health = "Good";
      else if(sup.valid)
         r.system_health = "Stable";
      else
         r.system_health = "Observed";

      r.ai_intelligence = orch.valid ? orch.intelligence_score
                          : (intel.valid ? intel.ai_confidence : 70.0);

      if(risk.valid)
         r.risk_status = (risk.risk_level == GM_RISK_LEVEL_LOW) ? "Controlled"
                         : (risk.risk_level == GM_RISK_LEVEL_MODERATE ? "Monitored" : "Watch");
      else
         r.risk_status = "Observed";

      r.market_condition = intel.valid
                           ? ((intel.market_score >= 70.0) ? "Stable"
                              : ((intel.market_score >= 50.0) ? "Mixed" : "Cautious"))
                           : "Observed";

      r.learning_status = mem.valid
                          ? ((mem.calibrated_confidence >= 70.0) ? "Improving" : "Adapting")
                          : "Warming";

      r.master_overview = StringFormat(
                             "THE GOLD MIND AI MASTER STATUS\r\n\r\nSystem Health:\r\n%s\r\n\r\nAI Intelligence:\r\n%.0f/100\r\n\r\nRisk Status:\r\n%s\r\n\r\nMarket Condition:\r\n%s\r\n\r\nLearning Status:\r\n%s\r\n\r\n%s\r\n",
                             r.system_health, r.ai_intelligence, r.risk_status,
                             r.market_condition, r.learning_status, GM_MCC_ANALYSIS_ONLY);

      r.panel_master = StringFormat("%s | AI=%.0f | Risk=%s",
                                    r.system_health, r.ai_intelligence, r.risk_status);
      r.panel_market = intel.valid
                       ? StringFormat("%.0f | %s", intel.market_score, intel.market_score_condition)
                       : "—";
      r.panel_risk = risk.valid
                     ? StringFormat("%s | Cap=%.0f Pred=%.0f%%",
                                    GmRiskLevelName(risk.risk_level),
                                    risk.capital_protection_score, risk.risk_probability)
                     : "—";
      r.panel_forecast = fcst.valid
                         ? StringFormat("%s | Acc=%.0f%%",
                                        GmFcstOutlookName(fcst.outlook), fcst.accuracy_score)
                         : "—";
      r.panel_learning = mem.valid
                         ? StringFormat("Cal=%.0f", mem.calibrated_confidence)
                         : "—";
      r.panel_reports = rpt.valid
                        ? StringFormat("Conf=%.0f", rpt.exec_confidence)
                        : "—";
      r.panel_assistant = chat.valid
                          ? StringFormat("%s | Sec=%s",
                                         chat.assistant_status,
                                         GmChatSecName(chat.security_status))
                          : "—";
      r.panel_enterprise = ent.valid
                           ? StringFormat("Fleet=%.0f | Accts=%d",
                                          ent.fleet_health_score, ent.accounts_monitored)
                           : "—";
     }
  };

#endif // GM_CAI_MASTER_CONTROL_CENTER_MQH
//+------------------------------------------------------------------+
