//+------------------------------------------------------------------+
//|                                  CMarketStructureAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CMARKET_STRUCTURE_ANALYZER_MQH
#define GM_CMARKET_STRUCTURE_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMarketAnalysisResult.mqh"

class CGmMarketStructureAnalyzer
  {
public:
   void Analyze(const string symbol, SGmMarketAnalysisResult &r)
     {
      double high[], low[], close[];
      ArraySetAsSeries(high, true);
      ArraySetAsSeries(low, true);
      ArraySetAsSeries(close, true);
      const int n = GM_MKT_SWING_LOOKBACK;
      if(CopyHigh(symbol, PERIOD_H4, 0, n + 5, high) < n + 2 ||
         CopyLow(symbol, PERIOD_H4, 0, n + 5, low) < n + 2 ||
         CopyClose(symbol, PERIOD_H4, 0, n + 5, close) < n + 2)
        {
         r.direction = GM_MKT_DIR_UNKNOWN;
         r.structure = GM_MKT_STRUCT_NONE;
         r.trend_strength = 0.0;
         r.momentum = 0.0;
         return;
        }

      // Simple swing points at shift 2 vs prior window
      double sh = high[2];
      double sl = low[2];
      for(int i = 3; i < n; i++)
        {
         if(high[i] > sh) sh = high[i];
         if(low[i] < sl) sl = low[i];
        }
      r.swing_high = sh;
      r.swing_low = sl;

      const double prev_high = high[3];
      const double prev_low = low[3];
      const double cur_high = high[1];
      const double cur_low = low[1];

      if(cur_high > prev_high && cur_low > prev_low)
         r.structure = GM_MKT_STRUCT_HH;
      else if(cur_high > prev_high && cur_low < prev_low)
         r.structure = GM_MKT_STRUCT_HL; // mixed — prefer HL if close rising
      else if(cur_high < prev_high && cur_low < prev_low)
         r.structure = GM_MKT_STRUCT_LL;
      else if(cur_high < prev_high && cur_low > prev_low)
         r.structure = GM_MKT_STRUCT_LH;
      else
         r.structure = GM_MKT_STRUCT_NONE;

      // BOS: close beyond prior swing
      if(close[0] > sh)
         r.structure = GM_MKT_STRUCT_BOS_UP;
      else if(close[0] < sl)
         r.structure = GM_MKT_STRUCT_BOS_DOWN;

      // Direction from net close change
      const double delta = close[0] - close[n - 1];
      const double range = sh - sl;
      if(range <= 0.0)
        {
         r.direction = GM_MKT_DIR_SIDEWAYS;
         r.trend_strength = 0.0;
        }
      else
        {
         const double strength = MathMin(100.0, MathAbs(delta) / range * 100.0);
         r.trend_strength = strength;
         if(MathAbs(delta) / range < 0.15)
            r.direction = GM_MKT_DIR_SIDEWAYS;
         else if(delta > 0.0)
            r.direction = GM_MKT_DIR_BULLISH;
         else
            r.direction = GM_MKT_DIR_BEARISH;
        }

      // Momentum: last 3 closes vs prior 3
      const double m_now = (close[0] + close[1] + close[2]) / 3.0;
      const double m_prev = (close[3] + close[4] + close[5]) / 3.0;
      if(range > 0.0)
         r.momentum = MathMax(-100.0, MathMin(100.0, (m_now - m_prev) / range * 100.0));
      else
         r.momentum = 0.0;
     }
  };

#endif // GM_CMARKET_STRUCTURE_ANALYZER_MQH
//+------------------------------------------------------------------+
