//+------------------------------------------------------------------+
//|                                  CMarketReactionAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CMARKET_REACTION_ANALYZER_MQH
#define GM_CMARKET_REACTION_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmNewsAnalysisResult.mqh"

/// @brief Observes spread / ATR / momentum around news windows (ANALYSIS ONLY).
class CGmMarketReactionAnalyzer
  {
public:
   void Analyze(const string symbol, SGmNewsAnalysisResult &r)
     {
      r.reaction.Reset();
      if(StringLen(symbol) == 0)
         return;

      const double spread = (double)SymbolInfoInteger(symbol, SYMBOL_SPREAD);
      const double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      r.reaction.spread_after = spread;
      r.reaction.spread_before = spread; // instantaneous proxy; history via ATR compare

      double atr_now = AvgTR(symbol, PERIOD_M15, 14);
      double atr_prev = AvgTR(symbol, PERIOD_M15, 14, 14);
      r.reaction.atr_after = atr_now;
      r.reaction.atr_before = atr_prev;
      if(atr_prev > 0.0)
         r.reaction.atr_change_pct = (atr_now - atr_prev) / atr_prev * 100.0;

      // Typical gold/USD spread baseline heuristic
      const double spread_pts = spread;
      r.reaction.spread_expansion = (spread_pts >= 40.0);
      r.reaction.vol_spike = (r.reaction.atr_change_pct >= 25.0);
      r.reaction.liquidity_expansion = (r.reaction.spread_expansion && r.reaction.vol_spike);

      double close[];
      ArraySetAsSeries(close, true);
      if(CopyClose(symbol, PERIOD_M5, 0, 12, close) >= 12)
        {
         const double m_now = close[0] - close[3];
         const double m_prev = close[4] - close[7];
         r.reaction.momentum_change = (MathAbs(m_now) > MathAbs(m_prev) * 1.35);
         r.reaction.trend_continuation = ((m_now > 0 && m_prev > 0) || (m_now < 0 && m_prev < 0));
         r.reaction.trend_reversal = ((m_now > 0 && m_prev < 0) || (m_now < 0 && m_prev > 0)) &&
                                     MathAbs(m_now) > MathAbs(m_prev) * 0.8;
         r.reaction.price_acceleration = (MathAbs(close[0] - close[1]) >
                                          MathAbs(close[2] - close[3]) * 1.5);
         if(point > 0.0)
            r.reaction.gap_detected = (MathAbs(close[0] - close[1]) / point >= 50.0);
        }

      // Primary reaction label
      if(r.reaction.gap_detected)
         r.reaction.primary = GM_NEWS_REACT_GAP;
      else if(r.reaction.vol_spike)
         r.reaction.primary = GM_NEWS_REACT_VOL_SPIKE;
      else if(r.reaction.spread_expansion)
         r.reaction.primary = GM_NEWS_REACT_SPREAD_EXPAND;
      else if(r.reaction.price_acceleration)
         r.reaction.primary = GM_NEWS_REACT_ACCELERATION;
      else if(r.reaction.trend_reversal)
         r.reaction.primary = GM_NEWS_REACT_REVERSAL;
      else if(r.reaction.trend_continuation)
         r.reaction.primary = GM_NEWS_REACT_CONTINUATION;
      else if(r.reaction.momentum_change)
         r.reaction.primary = GM_NEWS_REACT_MOMENTUM;
      else if(r.reaction.liquidity_expansion)
         r.reaction.primary = GM_NEWS_REACT_LIQUIDITY;
      else
         r.reaction.primary = GM_NEWS_REACT_QUIET;

      r.reaction_status = r.reaction.primary;
      r.reaction.summary = StringFormat("%s | ATRΔ=%.0f%% | spread=%.0f",
                                        GmNewsReactionName(r.reaction.primary),
                                        r.reaction.atr_change_pct,
                                        r.reaction.spread_after);
     }

private:
   double AvgTR(const string symbol, const ENUM_TIMEFRAMES tf,
                const int period, const int shift_start = 0)
     {
      double high[], low[], close[];
      ArraySetAsSeries(high, true);
      ArraySetAsSeries(low, true);
      ArraySetAsSeries(close, true);
      const int need = shift_start + period + 1;
      if(CopyHigh(symbol, tf, 0, need, high) < need ||
         CopyLow(symbol, tf, 0, need, low) < need ||
         CopyClose(symbol, tf, 0, need, close) < need)
         return 0.0;
      double sum = 0.0;
      for(int i = 0; i < period; i++)
        {
         const int idx = shift_start + i;
         const double tr1 = high[idx] - low[idx];
         const double tr2 = MathAbs(high[idx] - close[idx + 1]);
         const double tr3 = MathAbs(low[idx] - close[idx + 1]);
         sum += MathMax(tr1, MathMax(tr2, tr3));
        }
      return sum / (double)period;
     }
  };

#endif // GM_CMARKET_REACTION_ANALYZER_MQH
//+------------------------------------------------------------------+
