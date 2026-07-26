//+------------------------------------------------------------------+
//|                                   CAtrIntelligenceEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CATR_INTELLIGENCE_ENGINE_MQH
#define GM_CATR_INTELLIGENCE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmVolatilityAnalysisResult.mqh"

/// @brief ATR-14 intelligence — expansion/compression/momentum (ANALYSIS ONLY).
class CGmAtrIntelligenceEngine
  {
public:
   bool Analyze(const string symbol, SGmVolatilityAnalysisResult &r)
     {
      double high[], low[], close[];
      ArraySetAsSeries(high, true);
      ArraySetAsSeries(low, true);
      ArraySetAsSeries(close, true);
      const int need = GM_VOL_LOOKBACK + GM_VOL_ATR_PERIOD + 4;
      if(CopyHigh(symbol, PERIOD_H4, 0, need, high) < need ||
         CopyLow(symbol, PERIOD_H4, 0, need, low) < need ||
         CopyClose(symbol, PERIOD_H4, 0, need, close) < need)
         return false;

      double atr_series[];
      ArrayResize(atr_series, GM_VOL_LOOKBACK);
      for(int i = 0; i < GM_VOL_LOOKBACK; i++)
         atr_series[i] = CalcAtrAt(high, low, close, i, GM_VOL_ATR_PERIOD);

      r.atr14 = atr_series[0];
      double sum = 0.0;
      for(int i = 0; i < GM_VOL_LOOKBACK; i++)
         sum += atr_series[i];
      r.atr_average = sum / (double)GM_VOL_LOOKBACK;

      const double atr_prev = atr_series[1];
      const double atr_prev2 = atr_series[3];
      if(atr_prev > 0.0)
         r.atr_change_rate = (r.atr14 - atr_prev) / atr_prev * 100.0;
      else
         r.atr_change_rate = 0.0;

      const double rate_now = r.atr_change_rate;
      double rate_prev = 0.0;
      if(atr_prev2 > 0.0)
         rate_prev = (atr_prev - atr_prev2) / atr_prev2 * 100.0;
      const double accel = rate_now - rate_prev;
      if(accel >= 0.0)
        {
         r.atr_acceleration = accel;
         r.atr_deceleration = 0.0;
        }
      else
        {
         r.atr_acceleration = 0.0;
         r.atr_deceleration = -accel;
        }

      r.atr_expansion = (r.atr14 > r.atr_average * 1.08);
      r.atr_compression = (r.atr14 < r.atr_average * 0.92);

      if(r.atr_expansion)
         r.atr_trend = GM_ATR_TREND_EXPANDING;
      else if(r.atr_compression)
         r.atr_trend = GM_ATR_TREND_COMPRESSING;
      else
         r.atr_trend = GM_ATR_TREND_STABLE;

      r.atr_momentum = GmClamp01(50.0 + r.atr_change_rate * 2.0);
      if(r.atr_average > 0.0)
         r.atr_strength = GmClamp01(r.atr14 / r.atr_average * 50.0);
      else
         r.atr_strength = 50.0;
      return true;
     }

private:
   double CalcAtrAt(const double &high[], const double &low[], const double &close[],
                    const int start, const int period)
     {
      double sum = 0.0;
      for(int i = 0; i < period; i++)
        {
         const int idx = start + i;
         const double tr1 = high[idx] - low[idx];
         const double tr2 = MathAbs(high[idx] - close[idx + 1]);
         const double tr3 = MathAbs(low[idx] - close[idx + 1]);
         sum += MathMax(tr1, MathMax(tr2, tr3));
        }
      return sum / (double)period;
     }
  };

#endif // GM_CATR_INTELLIGENCE_ENGINE_MQH
//+------------------------------------------------------------------+
