//+------------------------------------------------------------------+
//|                                CAIReportGenerationEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_REPORT_GENERATION_ENGINE_MQH
#define GM_CAI_REPORT_GENERATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmReportingResult.mqh"
#include "../Intelligence/SGmIntelligenceResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../Memory/SGmMemoryLearningResult.mqh"
#include "../Market/MarketAnalysisConstants.mqh"
#include "../Intelligence/IntelligenceAIConstants.mqh"

class CGmAIReportGenerationEngine
  {
public:
   void Analyze(const SGmIntelligenceResult &intel,
                const SGmAssistantResult &sup,
                const SGmMemoryLearningResult &mem,
                SGmReportingResult &r)
     {
      const string mkt = intel.valid ? GmMktConditionName(intel.market_condition) : "Unknown";
      const string risk = intel.valid ? GmRiskAdvName(intel.risk_advisory) : "UNKNOWN";
      const double conf = mem.valid ? mem.calibrated_confidence
                                    : (intel.valid ? intel.ai_confidence : 50.0);
      const double cap = sup.valid ? sup.capital_protection_score : 0.0;
      const double health = sup.valid ? sup.system_health_score : 0.0;
      const string env = intel.valid ? intel.market_score_condition : "—";
      const string learn = mem.valid ? mem.learning_report : "Learning pending";

      r.daily_report = StringFormat(
                          "=== DAILY AI REPORT ===\r\nMarket Summary: %s\r\nStrategy Observation: Advisory monitoring only\r\nRisk Overview: %s\r\nCapital Protection: %.0f\r\nEnvironment: %s\r\nHistorical Comparison: HistSim=%.0f\r\nAI Confidence: %.0f%%\r\nLearning: %s\r\nSystem Health: %.0f\r\n%s\r\n",
                          mkt, risk, cap, env,
                          intel.valid ? intel.historical_similarity : 0.0,
                          conf, learn, health, GM_RPT_ADVISORY);

      r.weekly_report = StringFormat(
                           "=== WEEKLY AI REPORT ===\r\nWeekly DD obs=%.1f%% | EnvGrade=%s | LearnAcc=%.0f | Cap=%.0f | %s\r\n",
                           sup.valid ? sup.weekly_dd_pct : 0.0,
                           intel.valid ? StringFormat("%.0f", intel.market_score) : "—",
                           mem.valid ? mem.learning_accuracy : 0.0,
                           cap, GM_RPT_ANALYSIS_ONLY);

      r.monthly_report = StringFormat(
                            "=== MONTHLY AI REPORT ===\r\nMonthly DD=%.1f%% | StratPerf=%.0f | KnowledgeGrowth=%.0f | Improve=%.0f | %s\r\n",
                            sup.valid ? sup.monthly_dd_pct : 0.0,
                            intel.valid ? intel.strategy_performance_score : 0.0,
                            mem.valid ? mem.knowledge_growth : 0.0,
                            mem.valid ? mem.improvement_score : 0.0,
                            GM_RPT_ANALYSIS_ONLY);

      r.risk_report = StringFormat(
                         "=== RISK REPORT ===\r\n%s | Exposure=%.1f%% | DD=%.1f%% | MarginSafe=%.0f | Recovery=%s | MayModifyRisk=false\r\n",
                         risk,
                         sup.valid ? sup.risk_exposure_pct : 0.0,
                         sup.valid ? MathMax(sup.current_dd_pct, sup.daily_dd_pct) : 0.0,
                         intel.valid ? intel.margin_safety : (sup.valid ? 100.0 - sup.margin_usage_pct : 70.0),
                         sup.valid ? sup.recovery_status : "Idle");

      r.performance_report = StringFormat(
                                "=== PERFORMANCE REPORT ===\r\nMarketScore=%.0f | Strat=%.0f | LearnAcc=%.0f | OverallHealth=%.0f | %s\r\n",
                                intel.valid ? intel.market_score : 0.0,
                                intel.valid ? intel.strategy_performance_score : 0.0,
                                mem.valid ? mem.learning_accuracy : 0.0,
                                sup.valid ? sup.overall_health_score : 0.0,
                                GM_RPT_ANALYSIS_ONLY);

      r.learning_report = StringFormat(
                             "=== LEARNING REPORT ===\r\n%s | Patterns=%d | ConfImprove=+%.0f%% | Cal=%.0f | %s\r\n",
                             mem.valid ? mem.memory_profile : "Memory idle",
                             mem.valid ? mem.patterns_discovered : 0,
                             mem.valid ? mem.confidence_improvement_pct : 0.0,
                             mem.valid ? mem.calibrated_confidence : conf,
                             GM_RPT_ANALYSIS_ONLY);

      r.latest_report_headline = StringFormat("%s | %s | Conf=%.0f%%",
                                              mkt, risk, conf);
      r.primary_type = GM_RPT_TYPE_DAILY;
     }
  };

#endif // GM_CAI_REPORT_GENERATION_ENGINE_MQH
//+------------------------------------------------------------------+
