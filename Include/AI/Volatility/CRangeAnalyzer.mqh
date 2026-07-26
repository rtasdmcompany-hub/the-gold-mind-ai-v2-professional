//+------------------------------------------------------------------+
//|                                            CRangeAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CRANGE_ANALYZER_MQH
#define GM_CRANGE_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmVolatilityAnalysisResult.mqh"

/// @brief Multi-TF range + efficiency / expected next range (ANALYSIS ONLY).
class CGmRangeAnalyzer
  {
public:
   void Analyze(const string symbol, SGmVolatilityAnalysisResult &r)
     {
      r.range_h4 = BarRange(symbol, PERIOD_H4, 0);
      r.range_d1 = BarRange(symbol, PERIOD_D1, 0);
      r.range_w1 = BarRange(symbol, PERIOD_W1, 0);
      r.range_mn1 = BarRange(symbol, PERIOD_MN1, 0);
      r.avg_candle_range = AvgRange(symbol, PERIOD_H4, 20);

      const double avg = (r.avg_candle_range > 0.0) ? r.avg_candle_range : r.atr_average;
      if(avg > 0.0)
        {
         r.range_expansion = (r.range_h4 > avg * 1.15);
         r.range_compression = (r.range_h4 < avg * 0.85);
         // Efficiency: how much of range was traveled by close vs open
         double open[], close[];
         ArraySetAsSeries(open, true);
         ArraySetAsSeries(close, true);
         if(CopyOpen(symbol, PERIOD_H4, 0, 1, open) >= 1 &&
            CopyClose(symbol, PERIOD_H4, 0, 1, close) >= 1 &&
            r.range_h4 > 0.0)
            r.range_efficiency = GmClamp01(MathAbs(close[0] - open[0]) / r.range_h4 * 100.0);
         else
            r.range_efficiency = 50.0;
        }

      // Expected next range blends ATR and recent average
      r.expected_next_range = (r.atr14 * 0.55 + r.avg_candle_range * 0.45);
      if(r.atr_expansion)
         r.expected_next_range *= 1.08;
      else if(r.atr_compression)
         r.expected_next_range *= 0.92;
     }

private:
   double BarRange(const string symbol, const ENUM_TIMEFRAMES tf, const int shift)
     {
      const double h = iHigh(symbol, tf, shift);
      const double l = iLow(symbol, tf, shift);
      if(h <= 0.0 || l <= 0.0)
         return 0.0;
      return h - l;
     }

   double AvgRange(const string symbol, const ENUM_TIMEFRAMES tf, const int bars)
     {
      double high[], low[];
      ArraySetAsSeries(high, true);
      ArraySetAsSeries(low, true);
      if(CopyHigh(symbol, tf, 0, bars, high) < bars ||
         CopyLow(symbol, tf, 0, bars, low) < bars)
         return 0.0;
      double sum = 0.0;
      for(int i = 0; i < bars; i++)
         sum += (high[i] - low[i]);
      return sum / (double)bars;
     }
  };

#endif // GM_CRANGE_ANALYZER_MQH
//+------------------------------------------------------------------+
