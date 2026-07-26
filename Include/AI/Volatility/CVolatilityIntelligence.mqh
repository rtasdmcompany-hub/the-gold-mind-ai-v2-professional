//+------------------------------------------------------------------+
//|                                  CVolatilityIntelligence.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CVOLATILITY_INTELLIGENCE_MQH
#define GM_CVOLATILITY_INTELLIGENCE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmVolatilityAnalysisResult.mqh"

/// @brief Multi-horizon volatility metrics (ANALYSIS ONLY).
class CGmVolatilityIntelligence
  {
public:
   void Analyze(const string symbol, SGmVolatilityAnalysisResult &r)
     {
      r.current_vol = RangeVol(symbol, PERIOD_H4, 14);
      r.historical_vol = RangeVol(symbol, PERIOD_H4, 48);
      r.intraday_vol = RangeVol(symbol, PERIOD_H1, 24);
      r.weekly_vol = RangeVol(symbol, PERIOD_D1, 5);
      r.monthly_vol = RangeVol(symbol, PERIOD_D1, 20);

      if(r.historical_vol > 0.0)
         r.relative_vol = GmClamp01(r.current_vol / r.historical_vol * 50.0);
      else
         r.relative_vol = 50.0;

      // Expected = blend of recent ATR average and historical
      r.expected_vol = (r.atr_average > 0.0)
                       ? (r.atr_average * 0.6 + r.historical_vol * 0.4)
                       : r.historical_vol;

      // Stability: inverse of ATR change magnitude
      r.vol_stability = GmClamp01(100.0 - MathAbs(r.atr_change_rate) * 3.0);
      r.vol_confidence = GmClamp01(45.0 + r.vol_stability * 0.35 +
                                   (r.atr14 > 0.0 ? 10.0 : 0.0));
     }

private:
   double RangeVol(const string symbol, const ENUM_TIMEFRAMES tf, const int bars)
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

#endif // GM_CVOLATILITY_INTELLIGENCE_MQH
//+------------------------------------------------------------------+
