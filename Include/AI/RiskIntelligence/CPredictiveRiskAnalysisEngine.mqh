//+------------------------------------------------------------------+
//|                             CPredictiveRiskAnalysisEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CPREDICTIVE_RISK_ANALYSIS_ENGINE_MQH
#define GM_CPREDICTIVE_RISK_ANALYSIS_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmRiskIntelligenceResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../Intelligence/SGmIntelligenceResult.mqh"
#include "../Intelligence/IntelligenceAIConstants.mqh"

class CGmPredictiveRiskAnalysisEngine
  {
public:
   void Analyze(const SGmAssistantResult &sup,
                const SGmIntelligenceResult &intel,
                const SGmRiskIntelligenceResult &partial,
                SGmRiskIntelligenceResult &r)
     {
      double p = 8.0;
      const double dd = MathMax(partial.current_dd_pct,
                                (sup.valid ? MathMax(sup.current_dd_pct, MathMax(sup.daily_dd_pct, 0.0)) : 0.0));

      if(dd >= 3.0) p += dd * 2.5;
      if(sup.valid && sup.margin_usage_pct >= 35.0)
         p += (sup.margin_usage_pct - 30.0) * 0.6;
      if(sup.valid && sup.volatility_score >= 70.0)
         p += 8.0;
      else if(sup.valid && sup.volatility_score >= 55.0)
         p += 4.0;
      if(sup.valid && (sup.recovery_active || StringFind(sup.recovery_status, "Recovery") >= 0))
         p += 10.0;
      if(intel.valid)
        {
         if(intel.risk_advisory == GM_RISK_ADV_HIGH) p += 18.0;
         else if(intel.risk_advisory == GM_RISK_ADV_ELEVATED) p += 12.0;
         else if(intel.risk_advisory == GM_RISK_ADV_MODERATE) p += 6.0;
         if(intel.market_score < 50.0) p += 8.0;
         else if(intel.market_score < 65.0) p += 4.0;
        }
      if(partial.capital_protection_score < 55.0)
         p += 10.0;
      else if(partial.capital_protection_score < 70.0)
         p += 5.0;

      r.risk_probability = GmRiskIntClamp(p);

      if(r.risk_probability < 20.0)
         r.risk_level = GM_RISK_LEVEL_LOW;
      else if(r.risk_probability < 40.0)
         r.risk_level = GM_RISK_LEVEL_MODERATE;
      else if(r.risk_probability < 65.0)
         r.risk_level = GM_RISK_LEVEL_ELEVATED;
      else
         r.risk_level = GM_RISK_LEVEL_HIGH;

      if(r.risk_level == GM_RISK_LEVEL_LOW)
         r.predictive_reason = "Current exposure remains controlled.";
      else if(r.risk_level == GM_RISK_LEVEL_MODERATE)
         r.predictive_reason = "Mild drawdown / volatility expansion signals present.";
      else if(r.risk_level == GM_RISK_LEVEL_ELEVATED)
         r.predictive_reason = "Margin, drawdown, or market instability pressure rising.";
      else
         r.predictive_reason = "Multiple historical risk patterns aligned — monitoring advised.";

      r.predictive_report = StringFormat(
                               "Future Risk Probability Score:\r\nRisk Probability:\r\n%.0f%%\r\n\r\nRisk Level:\r\n%s\r\n\r\nReason:\r\n%s\r\n\r\n%s\r\n",
                               r.risk_probability,
                               GmRiskLevelName(r.risk_level),
                               r.predictive_reason,
                               GM_RISKINT_ADVISORY);
     }
  };

#endif // GM_CPREDICTIVE_RISK_ANALYSIS_ENGINE_MQH
//+------------------------------------------------------------------+
