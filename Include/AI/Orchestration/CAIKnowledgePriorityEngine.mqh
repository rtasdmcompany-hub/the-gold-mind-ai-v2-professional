//+------------------------------------------------------------------+
//|                                 CAIKnowledgePriorityEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_KNOWLEDGE_PRIORITY_ENGINE_MQH
#define GM_CAI_KNOWLEDGE_PRIORITY_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmOrchestrationResult.mqh"
#include "../RiskIntelligence/SGmRiskIntelligenceResult.mqh"
#include "../Forecasting/SGmForecastResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../Memory/SGmMemoryLearningResult.mqh"

class CGmAIKnowledgePriorityEngine
  {
private:
   void Add(SGmOrchestrationResult &r, const string item)
     {
      if(r.priority_count >= GM_ORCH_PRIORITY_MAX)
         return;
      r.priorities[r.priority_count++] = item;
     }

public:
   void Analyze(const SGmRiskIntelligenceResult &risk,
                const SGmForecastResult &fcst,
                const SGmAssistantResult &sup,
                const SGmVolatilityAnalysisResult &vol,
                const SGmMemoryLearningResult &mem,
                SGmOrchestrationResult &r)
     {
      r.priority_count = 0;
      for(int i = 0; i < GM_ORCH_PRIORITY_MAX; i++)
         r.priorities[i] = "";

      if(risk.valid && risk.alert_count > 0)
         Add(r, "Critical Risk Alert Review");
      if(vol.valid && vol.atr_expansion)
         Add(r, "High Volatility Detection");
      if(fcst.valid && fcst.transition_detected)
         Add(r, "Market Regime Transition");
      if(sup.valid && (sup.recovery_active || StringFind(sup.recovery_status, "Recovery") >= 0))
         Add(r, "Recovery Pattern Update");
      if(sup.valid && (sup.warning_count >= 2 || sup.system_health_score < 65.0))
         Add(r, "System Health Change");
      if(mem.valid && mem.calibrated_confidence >= 75.0)
         Add(r, "Learning Improvement Signal");
      if(fcst.valid && fcst.accuracy_improvement >= 3.0)
         Add(r, "Forecast Accuracy Improvement");
      if(r.priority_count == 0)
         Add(r, "Routine Monitoring — No Critical Priority");

      r.priority_queue = "Priority Intelligence Queue:\r\n";
      for(int p = 0; p < r.priority_count; p++)
         r.priority_queue += StringFormat("%d. %s\r\n", p + 1, r.priorities[p]);
      r.priority_queue += "\r\n" + GM_ORCH_ADVISORY + "\r\n";
     }
  };

#endif // GM_CAI_KNOWLEDGE_PRIORITY_ENGINE_MQH
//+------------------------------------------------------------------+
