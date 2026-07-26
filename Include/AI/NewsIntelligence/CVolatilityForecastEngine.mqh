//+------------------------------------------------------------------+
//|                               CVolatilityForecastEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CVOLATILITY_FORECAST_ENGINE_NI_MQH
#define GM_CVOLATILITY_FORECAST_ENGINE_NI_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmNewsIntelligenceResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../OrderFlow/SGmOrderFlowResult.mqh"

class CGmVolatilityForecastEngineNI
  {
public:
   void Analyze(const SGmVolatilityAnalysisResult &vol,
                const SGmTrendAnalysisResult &trend,
                const SGmOrderFlowResult &of,
                const SGmNewsIntelligenceResult &partial,
                SGmNewsIntelligenceResult &r)
     {
      const double impact = partial.news_impact_score;
      const double cur_atr = vol.valid ? vol.atr_strength : 50.0;
      const double cur_energy = vol.valid ? vol.energy_score
                              : (of.valid ? of.energy_score : 50.0);

      r.atr_forecast = GmNiClamp(
                          0.40 * cur_atr +
                          0.35 * partial.expected_atr_expansion +
                          0.25 * (50.0 + impact * 0.35));

      r.candle_size_forecast = GmNiClamp(
                                  0.45 * r.atr_forecast +
                                  0.35 * partial.expected_price_expansion +
                                  0.20 * (of.valid ? of.market_speed : 50.0));

      r.expansion_forecast = GmNiClamp(
                                MathMax(partial.expected_price_expansion,
                                        partial.expected_atr_expansion) * 0.7 +
                                impact * 0.25);

      r.compression_forecast = GmNiClamp(
                                  100.0 - r.expansion_forecast * 0.85 +
                                  (vol.valid && vol.atr_compression ? 12.0 : 0.0));

      r.energy_forecast = GmNiClamp(
                             0.40 * cur_energy +
                             0.35 * r.expansion_forecast +
                             0.25 * partial.expected_volatility);

      r.momentum_forecast = GmNiClamp(
                               0.40 * (trend.valid ? trend.momentum_strength : 50.0) +
                               0.30 * (of.valid ? of.session_momentum : 50.0) +
                               0.30 * r.energy_forecast);

      r.liquidity_forecast = GmNiClamp(
                                0.50 * partial.expected_liquidity +
                                0.30 * (of.valid ? of.session_liquidity : 55.0) +
                                0.20 * (100.0 - partial.expected_spread_expansion * 0.4));

      r.forecast_confidence = GmNiClamp(
                                 0.35 * partial.news_confidence +
                                 0.25 * (vol.valid ? vol.vol_confidence : 50.0) +
                                 0.20 * partial.historical_similarity +
                                 0.20 * (partial.impact_class != GM_NI_IMPACT_NONE ? 70.0 : 45.0));

      r.forecast_report = StringFormat(
                             "Volatility Forecast Engine:\r\nATR=%.0f Candle=%.0f Exp=%.0f Comp=%.0f\r\nEnergy=%.0f Mom=%.0f Liq=%.0f | Conf=%.0f\r\n%s\r\n",
                             r.atr_forecast, r.candle_size_forecast,
                             r.expansion_forecast, r.compression_forecast,
                             r.energy_forecast, r.momentum_forecast,
                             r.liquidity_forecast, r.forecast_confidence,
                             GM_NI_ANALYSIS_ONLY);
     }
  };

#endif // GM_CVOLATILITY_FORECAST_ENGINE_NI_MQH
//+------------------------------------------------------------------+
