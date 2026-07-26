//+------------------------------------------------------------------+
//|                              CAIKnowledgeRetrievalEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_KNOWLEDGE_RETRIEVAL_ENGINE_MQH
#define GM_CAI_KNOWLEDGE_RETRIEVAL_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmConversationResult.mqh"
#include "../Intelligence/SGmIntelligenceResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../Memory/SGmMemoryLearningResult.mqh"
#include "../Reporting/SGmReportingResult.mqh"
#include "../Intelligence/IntelligenceAIConstants.mqh"
#include "../Reporting/ReportingAIConstants.mqh"
#include "../Market/MarketAnalysisConstants.mqh"

class CGmAIKnowledgeRetrievalEngine
  {
public:
   void Retrieve(const SGmIntelligenceResult &intel,
                 const SGmAssistantResult &sup,
                 const SGmMemoryLearningResult &mem,
                 const SGmReportingResult &rpt,
                 SGmConversationResult &r)
     {
      r.market_answer = intel.valid
                        ? StringFormat("Market condition is %s with score %.0f/%s. %s",
                                       GmMktConditionName(intel.market_condition),
                                       intel.market_score,
                                       GmIntelGradeName(intel.market_grade),
                                       intel.market_advisory)
                        : "Market intelligence is still warming up.";

      r.risk_answer = intel.valid
                      ? StringFormat("Risk advisory is %s. %s Capital protection score is %.0f.",
                                     GmRiskAdvName(intel.risk_advisory),
                                     intel.risk_explanation,
                                     sup.valid ? sup.capital_protection_score : 0.0)
                      : (sup.valid
                         ? StringFormat("Observed drawdown %.1f%% with capital protection %.0f.",
                                        MathMax(sup.current_dd_pct, sup.daily_dd_pct),
                                        sup.capital_protection_score)
                         : "Risk context unavailable.");

      r.health_answer = sup.valid
                        ? StringFormat("System health is %.0f (EA %.0f). Terminal %s. Warnings: %s",
                                       sup.system_health_score, sup.ea_health,
                                       (sup.terminal_connected ? "connected" : "disconnected"),
                                       (sup.warning_count > 0 ? sup.warning_center : "none"))
                        : "Supervisor health data pending.";

      r.performance_answer = rpt.valid
                             ? StringFormat("AI performance scorecard is %.0f/%s. %s",
                                            rpt.performance_score,
                                            GmRptGradeName(rpt.performance_grade),
                                            rpt.accuracy_trend)
                             : (intel.valid
                                ? StringFormat("Strategy performance score %.0f | market score %.0f.",
                                               intel.strategy_performance_score, intel.market_score)
                                : "Performance reports pending.");

      r.learning_answer = mem.valid
                          ? StringFormat("Learning accuracy %.0f%%. Calibrated confidence %.0f%% (%s). %s",
                                         mem.learning_accuracy, mem.calibrated_confidence,
                                         mem.calibration_reason, mem.pattern_report)
                          : "Learning memory is initializing.";

      r.report_answer = rpt.valid
                        ? StringFormat("Latest report: %s | Recommendation: %s",
                                       rpt.latest_report_headline, rpt.recommendation)
                        : "No enterprise report generated yet.";

      r.strategy_explain =
         "Gold Mind observes H4 sessions with 3 buy and 3 sell levels, ATR-14 take-profit, "
         "fixed 30-pip stop, break-even, 80% partial close and 20% runner, plus second-attempt "
         "and recovery statistics. The Assistant explains these rules but never changes them.";

      r.knowledge_snippet = StringFormat("MKT|%s || RISK|%s || HEALTH|%s || LEARN|%s",
                                         r.market_answer, r.risk_answer,
                                         r.health_answer, r.learning_answer);
     }
  };

#endif // GM_CAI_KNOWLEDGE_RETRIEVAL_ENGINE_MQH
//+------------------------------------------------------------------+
