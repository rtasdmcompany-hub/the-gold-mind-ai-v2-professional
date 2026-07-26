//+------------------------------------------------------------------+
//|                               CHistoricalSimulationEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CHISTORICAL_SIMULATION_ENGINE_MQH
#define GM_CHISTORICAL_SIMULATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmPredictiveIntelligenceResult.mqh"
#include "../MultiTimeframe/SGmMultiTimeframeResult.mqh"
#include "../RecoveryIntelligence/SGmRecoveryIntelligenceResult.mqh"
#include "../Forecasting/SGmForecastResult.mqh"
#include "../NewsIntelligence/SGmNewsIntelligenceResult.mqh"

class CGmHistoricalSimulationEngine
  {
public:
   void Analyze(const SGmMultiTimeframeResult &mtf,
                const SGmRecoveryIntelligenceResult &ri,
                const SGmForecastResult &fcst,
                const SGmNewsIntelligenceResult &ni,
                const SGmPredictiveIntelligenceResult &partial,
                SGmPredictiveIntelligenceResult &r)
     {
      r.historical_match = GmPredClamp(
                              0.40 * (mtf.valid ? mtf.historical_similarity : 55.0) +
                              0.30 * (ni.valid ? ni.historical_similarity : 55.0) +
                              0.30 * partial.forecast_reliability);

      r.historical_success_rate = GmPredClamp(
                                     0.45 * (ri.valid ? ri.historical_recovery_pct : 58.0) +
                                     0.30 * (fcst.valid ? fcst.accuracy_score : 55.0) +
                                     0.25 * partial.continuation_probability);

      r.historical_failure_rate = GmPredClamp(100.0 - r.historical_success_rate);

      r.pattern_frequency = GmPredClamp(
                               40.0 + partial.scenario_probability * 0.35 +
                               (partial.dominant_scenario != GM_PRED_SCN_UNKNOWN ? 12.0 : 0.0));

      r.historical_probability = GmPredClamp(
                                    0.40 * r.historical_match +
                                    0.35 * r.historical_success_rate +
                                    0.25 * partial.overall_probability_score);

      r.historical_reliability = GmPredClamp(
                                    0.50 * r.historical_match +
                                    0.30 * partial.forecast_reliability +
                                    0.20 * (fcst.valid ? fcst.accuracy_score : 50.0));

      r.historical_report = StringFormat(
                               "Historical Simulation Engine:\r\nMatch=%.0f Success=%.0f Fail=%.0f Freq=%.0f\r\nHistProb=%.0f Reliability=%.0f | Dominant=%s\r\n%s\r\n%s\r\n",
                               r.historical_match, r.historical_success_rate,
                               r.historical_failure_rate, r.pattern_frequency,
                               r.historical_probability, r.historical_reliability,
                               GmPredScenarioName(partial.dominant_scenario),
                               GM_PRED_CONTEXT, GM_PRED_ADVISORY);
     }
  };

#endif // GM_CHISTORICAL_SIMULATION_ENGINE_MQH
//+------------------------------------------------------------------+
