//+------------------------------------------------------------------+
//|                                 CScenarioExplanationEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CSCENARIO_EXPLANATION_ENGINE_MQH
#define GM_CSCENARIO_EXPLANATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmForecastResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../Intelligence/SGmIntelligenceResult.mqh"

class CGmScenarioExplanationEngine
  {
public:
   void Analyze(const SGmTrendAnalysisResult &trend,
                const SGmVolatilityAnalysisResult &vol,
                const SGmIntelligenceResult &intel,
                SGmForecastResult &r)
     {
      string tech = "Balanced structure";
      if(vol.valid && vol.atr_expansion && trend.valid && trend.trend_stability < 50.0)
         tech = "ATR Expansion + Weak Trend";
      else if(vol.valid && vol.atr_expansion)
         tech = "ATR Expansion";
      else if(trend.valid && trend.trend_exhaustion >= 55.0)
         tech = "Trend Exhaustion Signals";
      else if(vol.valid && vol.atr_compression)
         tech = "ATR Compression / Range Bias";
      else if(trend.valid && trend.trend_stability >= 65.0)
         tech = "Stable Trend Structure";
      r.technical_summary = tech;

      if(r.dominant_scenario == GM_FCST_SCN_VOL_EXPANSION)
         r.ai_explanation = "Current conditions suggest increased uncertainty. The system is monitoring possible volatility expansion.";
      else if(r.dominant_scenario == GM_FCST_SCN_CONTINUATION)
         r.ai_explanation = "Structure favors continuation of the observed H4 directional bias. Monitoring remains advisory only.";
      else if(r.dominant_scenario == GM_FCST_SCN_RANGE)
         r.ai_explanation = "Compression and mixed momentum favor range formation. Breakout confirmation is not assumed.";
      else if(r.dominant_scenario == GM_FCST_SCN_REVERSAL)
         r.ai_explanation = "Exhaustion and conflicting signals raise reversal probability. No execution is recommended by AI.";
      else
         r.ai_explanation = "Market conditions are under observation. Forecasts are informational only.";

      const double sim = (intel.valid ? intel.historical_similarity : 50.0);
      r.historical_match = StringFormat("Similarity=%.0f%% | Env=%s | Dominant=%s",
                                        sim,
                                        (intel.valid ? intel.market_score_condition : "—"),
                                        GmFcstScenarioName(r.dominant_scenario));
     }
  };

#endif // GM_CSCENARIO_EXPLANATION_ENGINE_MQH
//+------------------------------------------------------------------+
