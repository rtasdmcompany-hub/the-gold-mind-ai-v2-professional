//+------------------------------------------------------------------+
//|                                    CTrendStrengthAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CTREND_STRENGTH_ANALYZER_MQH
#define GM_CTREND_STRENGTH_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmTrendAnalysisResult.mqh"

class CGmTrendStrengthAnalyzer
  {
public:
   void AnalyzeTF(const string symbol, const ENUM_TIMEFRAMES tf, SGmTrendTFState &st)
     {
      st.Reset();
      st.tf = tf;
      double high[], low[], close[];
      ArraySetAsSeries(high, true);
      ArraySetAsSeries(low, true);
      ArraySetAsSeries(close, true);
      const int n = GM_TREND_LOOKBACK;
      if(CopyHigh(symbol, tf, 0, n, high) < n ||
         CopyLow(symbol, tf, 0, n, low) < n ||
         CopyClose(symbol, tf, 0, n, close) < n)
         return;

      double hi = high[0], lo = low[0];
      for(int i = 1; i < n; i++)
        {
         if(high[i] > hi) hi = high[i];
         if(low[i] < lo) lo = low[i];
        }
      const double range = hi - lo;
      st.direction = GmTrendFromCloses(close[0], close[n - 1], range);
      if(range > 0.0)
         st.strength = MathMin(100.0, MathAbs(close[0] - close[n - 1]) / range * 100.0);
      const double m_now = (close[0] + close[1] + close[2]) / 3.0;
      const double m_prev = (close[3] + close[4] + close[5]) / 3.0;
      st.momentum = (range > 0.0)
                    ? MathMax(-100.0, MathMin(100.0, (m_now - m_prev) / range * 100.0))
                    : 0.0;
     }

   void Aggregate(SGmTrendAnalysisResult &r)
     {
      // Primary = D1, Secondary = H4, Micro = recent H4 momentum
      r.primary = r.d1.direction;
      r.secondary = r.h4.direction;
      if(r.h4.momentum > 25.0)
         r.micro = GM_TREND_DIR_BULL;
      else if(r.h4.momentum < -25.0)
         r.micro = GM_TREND_DIR_BEAR;
      else
         r.micro = GM_TREND_DIR_FLAT;

      r.strength_score = (r.h4.strength * 0.35 + r.d1.strength * 0.35 +
                          r.w1.strength * 0.20 + r.mn1.strength * 0.10);

      double bull = 0.0, bear = 0.0;
      AddPressure(r.h4.direction, r.h4.strength, bull, bear);
      AddPressure(r.d1.direction, r.d1.strength, bull, bear);
      AddPressure(r.w1.direction, r.w1.strength, bull, bear);
      AddPressure(r.mn1.direction, r.mn1.strength, bull, bear);
      const double tot = bull + bear;
      r.bullish_pressure = (tot > 0.0) ? (bull / tot * 100.0) : 50.0;
      r.bearish_pressure = (tot > 0.0) ? (bear / tot * 100.0) : 50.0;
      r.momentum_strength = MathMin(100.0, MathAbs(r.h4.momentum));
      r.directional_bias = r.bullish_pressure - r.bearish_pressure;

      // Stability: agreement of H4/D1/W1
      int agree = 0;
      if(r.h4.direction == r.d1.direction && r.h4.direction != GM_TREND_DIR_FLAT) agree++;
      if(r.d1.direction == r.w1.direction && r.d1.direction != GM_TREND_DIR_FLAT) agree++;
      if(r.h4.direction == r.w1.direction && r.h4.direction != GM_TREND_DIR_FLAT) agree++;
      r.trend_stability = agree * 33.0;

      // Exhaustion: high strength + fading momentum opposite to direction
      r.trend_exhaustion = 0.0;
      if(r.strength_score >= 60.0)
        {
         if(r.primary == GM_TREND_DIR_BULL && r.h4.momentum < 0.0)
            r.trend_exhaustion = MathMin(100.0, MathAbs(r.h4.momentum));
         if(r.primary == GM_TREND_DIR_BEAR && r.h4.momentum > 0.0)
            r.trend_exhaustion = MathMin(100.0, MathAbs(r.h4.momentum));
        }

      r.confidence = MathMin(95.0,
                             40.0 + r.strength_score * 0.25 + r.trend_stability * 0.25);
     }

private:
   void AddPressure(const ENUM_GM_TREND_DIR d, const double s, double &bull, double &bear)
     {
      if(d == GM_TREND_DIR_BULL) bull += s;
      else if(d == GM_TREND_DIR_BEAR) bear += s;
      else { bull += s * 0.5; bear += s * 0.5; }
     }
  };

#endif // GM_CTREND_STRENGTH_ANALYZER_MQH
//+------------------------------------------------------------------+
