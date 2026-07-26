//+------------------------------------------------------------------+
//|                                    CAIMarketForecastEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_MARKET_FORECAST_ENGINE_MQH
#define GM_CAI_MARKET_FORECAST_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmForecastResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../Intelligence/SGmIntelligenceResult.mqh"
#include "../Trend/TrendAIConstants.mqh"

class CGmAIMarketForecastEngine
  {
public:
   void Analyze(const SGmTrendAnalysisResult &trend,
                const SGmVolatilityAnalysisResult &vol,
                const SGmIntelligenceResult &intel,
                SGmForecastResult &r)
     {
      double trend_p = 50.0;
      if(trend.valid)
        {
         trend_p = 40.0 + trend.confidence * 0.35 + trend.trend_stability * 0.20;
         if(trend.trend_exhaustion >= 55.0)
            trend_p -= 12.0;
         if(MathAbs(trend.directional_bias) >= 25.0)
            trend_p += 6.0;
        }
      if(intel.valid)
         trend_p = 0.7 * trend_p + 0.3 * intel.market_score;
      r.trend_probability = GmFcstClamp(trend_p);

      if(vol.valid && vol.atr_expansion)
         r.volatility_expectation = "High";
      else if(vol.valid && vol.atr_compression)
         r.volatility_expectation = "Low";
      else if(vol.valid && vol.energy_score >= 60.0)
         r.volatility_expectation = "Medium-High";
      else
         r.volatility_expectation = "Medium";

      r.forecast_confidence = GmFcstClamp(
                                 0.45 * (trend.valid ? trend.confidence : 55.0) +
                                 0.25 * (vol.valid ? vol.phase_confidence : 55.0) +
                                 0.30 * (intel.valid ? intel.ai_confidence : 55.0));

      const bool bullish = (trend.valid &&
                            (trend.primary == GM_TREND_DIR_BULL || trend.directional_bias > 10.0));
      const bool bearish = (trend.valid &&
                            (trend.primary == GM_TREND_DIR_BEAR || trend.directional_bias < -10.0));

      if(r.trend_probability >= 70.0 && bullish && r.volatility_expectation != "High")
         r.outlook = GM_FCST_OUTLOOK_POSITIVE;
      else if(r.trend_probability >= 58.0 && bullish)
         r.outlook = GM_FCST_OUTLOOK_MOD_POSITIVE;
      else if(bearish && r.trend_probability >= 58.0)
         r.outlook = GM_FCST_OUTLOOK_NEGATIVE;
      else
         r.outlook = GM_FCST_OUTLOOK_NEUTRAL;

      r.market_forecast_report = StringFormat(
                                    "AI Market Forecast Report:\r\nMarket Outlook:\r\n%s\r\n\r\nTrend Probability:\r\n%.0f%%\r\n\r\nVolatility Expectation:\r\n%s\r\n\r\nConfidence:\r\n%.0f%%\r\n\r\n%s\r\n",
                                    GmFcstOutlookName(r.outlook),
                                    r.trend_probability,
                                    r.volatility_expectation,
                                    r.forecast_confidence,
                                    GM_FCST_ANALYSIS_ONLY);
     }
  };

#endif // GM_CAI_MARKET_FORECAST_ENGINE_MQH
//+------------------------------------------------------------------+
