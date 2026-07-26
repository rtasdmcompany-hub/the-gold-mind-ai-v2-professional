//+------------------------------------------------------------------+
//|                                   CExecutiveSummaryEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEXECUTIVE_SUMMARY_ENGINE_MQH
#define GM_CEXECUTIVE_SUMMARY_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmReportingResult.mqh"
#include "../Intelligence/SGmIntelligenceResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../Memory/SGmMemoryLearningResult.mqh"
#include "../Market/MarketAnalysisConstants.mqh"
#include "../Intelligence/IntelligenceAIConstants.mqh"

class CGmExecutiveSummaryEngine
  {
public:
   void Analyze(const SGmIntelligenceResult &intel,
                const SGmAssistantResult &sup,
                const SGmMemoryLearningResult &mem,
                SGmReportingResult &r)
     {
      r.market_condition_label = "Stable";
      if(intel.valid)
        {
         if(intel.market_condition == GM_MKT_COND_HIGH_VOL)
            r.market_condition_label = "Volatile";
         else if(intel.market_condition == GM_MKT_COND_TRENDING ||
                 intel.market_condition == GM_MKT_COND_STRONG_TREND)
            r.market_condition_label = "Trending";
         else if(intel.market_condition == GM_MKT_COND_RANGING ||
                 intel.market_condition == GM_MKT_COND_CONSOLIDATION)
            r.market_condition_label = "Quiet / Range";
         else
            r.market_condition_label = GmMktConditionName(intel.market_condition);
        }

      r.risk_level_label = "Moderate";
      if(intel.valid)
        {
         if(intel.risk_advisory == GM_RISK_ADV_LOW) r.risk_level_label = "Low";
         else if(intel.risk_advisory == GM_RISK_ADV_MODERATE) r.risk_level_label = "Moderate";
         else if(intel.risk_advisory == GM_RISK_ADV_ELEVATED) r.risk_level_label = "Elevated";
         else if(intel.risk_advisory == GM_RISK_ADV_HIGH) r.risk_level_label = "High";
        }

      r.system_health_label = "Good";
      const double health = sup.valid ? sup.system_health_score : 70.0;
      if(health >= 85.0) r.system_health_label = "Excellent";
      else if(health >= 70.0) r.system_health_label = "Good";
      else if(health >= 55.0) r.system_health_label = "Fair";
      else r.system_health_label = "Attention";

      r.exec_confidence = mem.valid ? mem.calibrated_confidence
                                    : (intel.valid ? intel.ai_confidence : 50.0);
      r.recommendation = "Continue Monitoring";
      if(r.risk_level_label == "High")
         r.recommendation = "Heighten Observation (no execution change)";
      else if(r.market_condition_label == "Volatile")
         r.recommendation = "Closer Monitoring Recommended";

      r.executive_brief = StringFormat(
                             "THE GOLD MIND AI STATUS\r\n\r\nMarket Condition:\r\n%s\r\n\r\nRisk Level:\r\n%s\r\n\r\nSystem Health:\r\n%s\r\n\r\nAI Confidence:\r\n%.0f%%\r\n\r\nRecommendation:\r\n%s\r\n\r\n(No execution instructions)\r\n",
                             r.market_condition_label,
                             r.risk_level_label,
                             r.system_health_label,
                             r.exec_confidence,
                             r.recommendation);
     }
  };

#endif // GM_CEXECUTIVE_SUMMARY_ENGINE_MQH
//+------------------------------------------------------------------+
