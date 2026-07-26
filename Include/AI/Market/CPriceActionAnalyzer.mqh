//+------------------------------------------------------------------+
//|                                     CPriceActionAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CPRICE_ACTION_ANALYZER_MQH
#define GM_CPRICE_ACTION_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMarketAnalysisResult.mqh"

class CGmPriceActionAnalyzer
  {
public:
   void Analyze(const string symbol, SGmMarketAnalysisResult &r)
     {
      double o[], h[], l[], c[];
      ArraySetAsSeries(o, true);
      ArraySetAsSeries(h, true);
      ArraySetAsSeries(l, true);
      ArraySetAsSeries(c, true);
      if(CopyOpen(symbol, PERIOD_H4, 0, 3, o) < 2 ||
         CopyHigh(symbol, PERIOD_H4, 0, 3, h) < 2 ||
         CopyLow(symbol, PERIOD_H4, 0, 3, l) < 2 ||
         CopyClose(symbol, PERIOD_H4, 0, 3, c) < 2)
        {
         r.pattern = GM_MKT_PAT_NONE;
         return;
        }

      const double body0 = MathAbs(c[0] - o[0]);
      const double range0 = h[0] - l[0];
      const double body1 = MathAbs(c[1] - o[1]);
      const double range1 = h[1] - l[1];
      const double upper0 = h[0] - MathMax(o[0], c[0]);
      const double lower0 = MathMin(o[0], c[0]) - l[0];

      r.pattern = GM_MKT_PAT_NONE;

      // Engulfing
      if(c[1] < o[1] && c[0] > o[0] && o[0] <= c[1] && c[0] >= o[1])
         r.pattern = GM_MKT_PAT_BULL_ENGULF;
      else if(c[1] > o[1] && c[0] < o[0] && o[0] >= c[1] && c[0] <= o[1])
         r.pattern = GM_MKT_PAT_BEAR_ENGULF;
      // Inside / Outside
      else if(h[0] <= h[1] && l[0] >= l[1])
         r.pattern = GM_MKT_PAT_INSIDE;
      else if(h[0] >= h[1] && l[0] <= l[1])
         r.pattern = GM_MKT_PAT_OUTSIDE;
      // Doji
      else if(range0 > 0.0 && body0 / range0 <= 0.1)
         r.pattern = GM_MKT_PAT_DOJI;
      // Hammer / Shooting star / Pin
      else if(range0 > 0.0 && lower0 >= body0 * 2.0 && upper0 <= body0 * 0.5)
         r.pattern = (c[0] >= o[0]) ? GM_MKT_PAT_HAMMER : GM_MKT_PAT_PIN_BULL;
      else if(range0 > 0.0 && upper0 >= body0 * 2.0 && lower0 <= body0 * 0.5)
         r.pattern = (c[0] <= o[0]) ? GM_MKT_PAT_SHOOTING_STAR : GM_MKT_PAT_PIN_BEAR;
      // Momentum / weak
      else if(range0 > 0.0 && body0 / range0 >= 0.7)
         r.pattern = (c[0] > o[0]) ? GM_MKT_PAT_STRONG_BULL : GM_MKT_PAT_STRONG_BEAR;
      else if(range0 > 0.0 && body0 / range0 <= 0.25 && range1 > 0.0)
         r.pattern = GM_MKT_PAT_WEAK;
     }
  };

#endif // GM_CPRICE_ACTION_ANALYZER_MQH
//+------------------------------------------------------------------+
