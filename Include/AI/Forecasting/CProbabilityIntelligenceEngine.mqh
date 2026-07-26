//+------------------------------------------------------------------+
//|                               CProbabilityIntelligenceEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CPROBABILITY_INTELLIGENCE_ENGINE_MQH
#define GM_CPROBABILITY_INTELLIGENCE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmForecastResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../RiskIntelligence/SGmRiskIntelligenceResult.mqh"

class CGmProbabilityIntelligenceEngine
  {
public:
   void Analyze(const SGmVolatilityAnalysisResult &vol,
                const SGmAssistantResult &sup,
                const SGmRiskIntelligenceResult &risk,
                const SGmForecastResult &partial,
                SGmForecastResult &r)
     {
      r.prob_trend = GmFcstClamp(partial.trend_probability);
      r.prob_volatility = 30.0;
      if(vol.valid)
        {
         r.prob_volatility = GmFcstClamp(25.0 + (vol.atr_expansion ? 30.0 : 0.0) +
                                         vol.energy_score * 0.25 +
                                         MathMax(0.0, vol.atr_change_rate) * 1.2);
        }
      r.prob_recovery = 70.0;
      if(sup.valid)
        {
         if(sup.recovery_active)
            r.prob_recovery = GmFcstClamp(55.0 + (100.0 - MathMax(sup.current_dd_pct, 0.0)) * 0.25);
         else
            r.prob_recovery = GmFcstClamp(75.0 + MathMax(0.0, 10.0 - MathMax(sup.current_dd_pct, 0.0)));
        }
      if(risk.valid)
         r.prob_recovery = GmFcstClamp(0.6 * r.prob_recovery +
                                       0.4 * (risk.recovery_probability == "High" ? 89.0
                                              : (risk.recovery_probability == "Moderate" ? 65.0 : 40.0)));

      r.prob_risk = risk.valid ? risk.risk_probability
                    : GmFcstClamp(100.0 - partial.forecast_confidence * 0.5);
      r.prob_stability = GmFcstClamp(100.0 - 0.45 * r.prob_volatility - 0.35 * r.prob_risk +
                                     0.15 * r.prob_trend);

      r.probability_matrix = StringFormat(
                                "AI Probability Matrix:\r\nTrend Continuation:\r\n%.0f%%\r\n\r\nVolatility Increase:\r\n%.0f%%\r\n\r\nRecovery Success:\r\n%.0f%%\r\n\r\nRisk Probability:\r\n%.0f%%\r\n\r\nStability Probability:\r\n%.0f%%\r\n\r\n%s\r\n",
                                r.prob_trend,
                                r.prob_volatility,
                                r.prob_recovery,
                                r.prob_risk,
                                r.prob_stability,
                                GM_FCST_ANALYSIS_ONLY);
     }
  };

#endif // GM_CPROBABILITY_INTELLIGENCE_ENGINE_MQH
//+------------------------------------------------------------------+
