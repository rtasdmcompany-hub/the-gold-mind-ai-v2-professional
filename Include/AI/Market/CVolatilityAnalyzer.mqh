//+------------------------------------------------------------------+
//|                                      CVolatilityAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CVOLATILITY_ANALYZER_MQH
#define GM_CVOLATILITY_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMarketAnalysisResult.mqh"

class CGmVolatilityAnalyzer
  {
private:
   int    m_atr_handle;
   string m_atr_symbol;

   void EnsureAtr(const string symbol)
     {
      if(m_atr_handle != INVALID_HANDLE && m_atr_symbol == symbol)
         return;
      if(m_atr_handle != INVALID_HANDLE)
         IndicatorRelease(m_atr_handle);
      m_atr_symbol = symbol;
      m_atr_handle = iATR(symbol, PERIOD_H4, GM_MKT_ATR_PERIOD);
     }

public:
                     CGmVolatilityAnalyzer(void)
                       : m_atr_handle(INVALID_HANDLE), m_atr_symbol("") {}
                    ~CGmVolatilityAnalyzer(void)
     {
      if(m_atr_handle != INVALID_HANDLE)
        {
         IndicatorRelease(m_atr_handle);
         m_atr_handle = INVALID_HANDLE;
        }
     }

   void Analyze(const string symbol, SGmMarketAnalysisResult &r)
     {
      EnsureAtr(symbol);
      r.atr14 = 0.0;
      if(m_atr_handle != INVALID_HANDLE)
        {
         double buf[];
         ArraySetAsSeries(buf, true);
         if(CopyBuffer(m_atr_handle, 0, 0, 1, buf) > 0)
            r.atr14 = buf[0];
        }

      r.candle_h4 = iHigh(symbol, PERIOD_H4, 0) - iLow(symbol, PERIOD_H4, 0);
      r.candle_d1 = iHigh(symbol, PERIOD_D1, 0) - iLow(symbol, PERIOD_D1, 0);
      r.candle_w1 = iHigh(symbol, PERIOD_W1, 0) - iLow(symbol, PERIOD_W1, 0);
      r.candle_mn1 = iHigh(symbol, PERIOD_MN1, 0) - iLow(symbol, PERIOD_MN1, 0);
      r.daily_range = r.candle_d1;
      r.weekly_range = r.candle_w1;

      double sum = 0.0;
      int cnt = 0;
      for(int i = 1; i <= 10; i++)
        {
         const double rng = iHigh(symbol, PERIOD_H4, i) - iLow(symbol, PERIOD_H4, i);
         if(rng > 0.0)
           {
            sum += rng;
            cnt++;
           }
        }
      r.avg_candle_size = (cnt > 0) ? (sum / (double)cnt) : 0.0;

      if(r.atr14 > 0.0)
         r.volatility_ratio = r.candle_h4 / r.atr14;
      else
         r.volatility_ratio = 0.0;

      r.market_speed = r.volatility_ratio * 50.0;
      if(r.market_speed > 100.0)
         r.market_speed = 100.0;

      r.expansion = (r.avg_candle_size > 0.0 && r.candle_h4 >= r.avg_candle_size * 1.35);
      r.contraction = (r.avg_candle_size > 0.0 && r.candle_h4 <= r.avg_candle_size * 0.65);
     }
  };

#endif // GM_CVOLATILITY_ANALYZER_MQH
//+------------------------------------------------------------------+
