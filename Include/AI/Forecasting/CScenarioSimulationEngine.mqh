//+------------------------------------------------------------------+
//|                                  CScenarioSimulationEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CSCENARIO_SIMULATION_ENGINE_MQH
#define GM_CSCENARIO_SIMULATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmForecastResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"

class CGmScenarioSimulationEngine
  {
public:
   void Analyze(const SGmTrendAnalysisResult &trend,
                const SGmVolatilityAnalysisResult &vol,
                const SGmAssistantResult &sup,
                const SGmForecastResult &partial,
                SGmForecastResult &r)
     {
      double cont = 28.0;
      double range = 24.0;
      double vexp = 22.0;
      double rev = 26.0;

      if(trend.valid)
        {
         cont += trend.trend_stability * 0.35 + MathMax(0.0, trend.confidence - 50.0) * 0.25;
         rev += trend.trend_exhaustion * 0.40;
         if(trend.trend_stability < 40.0)
            range += 12.0;
        }
      if(vol.valid)
        {
         if(vol.atr_expansion)
            vexp += 18.0 + vol.atr_strength * 0.15;
         if(vol.atr_compression)
            range += 14.0;
         if(vol.energy_score >= 70.0)
            vexp += 8.0;
        }
      if(sup.valid && (sup.recovery_active || StringFind(sup.recovery_status, "Recovery") >= 0))
         rev += 6.0;
      if(partial.trend_probability >= 65.0)
         cont += 8.0;

      // Normalize to ~100
      const double sum = cont + range + vexp + rev;
      if(sum > 0.0)
        {
         r.scn_continuation = GmFcstClamp(100.0 * cont / sum);
         r.scn_range = GmFcstClamp(100.0 * range / sum);
         r.scn_vol_expansion = GmFcstClamp(100.0 * vexp / sum);
         r.scn_reversal = GmFcstClamp(100.0 * rev / sum);
        }

      r.dominant_scenario = GM_FCST_SCN_CONTINUATION;
      double best = r.scn_continuation;
      if(r.scn_range > best) { best = r.scn_range; r.dominant_scenario = GM_FCST_SCN_RANGE; }
      if(r.scn_vol_expansion > best) { best = r.scn_vol_expansion; r.dominant_scenario = GM_FCST_SCN_VOL_EXPANSION; }
      if(r.scn_reversal > best) { r.dominant_scenario = GM_FCST_SCN_REVERSAL; }

      r.scenario_probability_map = StringFormat("Cont=%.0f%% Range=%.0f%% VolExp=%.0f%% Rev=%.0f%%",
                                                r.scn_continuation, r.scn_range,
                                                r.scn_vol_expansion, r.scn_reversal);

      r.scenario_report = StringFormat(
                             "Scenario Intelligence Report:\r\nScenario 1: Trend Continuation (%.0f%%)\r\nScenario 2: Range Formation (%.0f%%)\r\nScenario 3: High Volatility Expansion (%.0f%%)\r\nScenario 4: Market Reversal (%.0f%%)\r\n\r\nDominant: %s\r\nRisk Impact: Informational only\r\n%s\r\n",
                             r.scn_continuation, r.scn_range, r.scn_vol_expansion, r.scn_reversal,
                             GmFcstScenarioName(r.dominant_scenario),
                             GM_FCST_ADVISORY);
     }
  };

#endif // GM_CSCENARIO_SIMULATION_ENGINE_MQH
//+------------------------------------------------------------------+
