//+------------------------------------------------------------------+
//|                                     CMarketStructureEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CMARKET_STRUCTURE_ENGINE_MQH
#define GM_CMARKET_STRUCTURE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmTrendAnalysisResult.mqh"

class CGmMarketStructureEngine
  {
public:
   void Analyze(const string symbol, SGmTrendAnalysisResult &r)
     {
      double high[], low[], close[];
      ArraySetAsSeries(high, true);
      ArraySetAsSeries(low, true);
      ArraySetAsSeries(close, true);
      const int n = GM_TREND_LOOKBACK;
      if(CopyHigh(symbol, PERIOD_H4, 0, n, high) < n ||
         CopyLow(symbol, PERIOD_H4, 0, n, low) < n ||
         CopyClose(symbol, PERIOD_H4, 0, n, close) < n)
        {
         r.structure = GM_TREND_STRUCT_NONE;
         return;
        }

      // Swing high/low from lookback excluding forming bar
      double sh = high[2], sl = low[2];
      for(int i = 3; i < n - 1; i++)
        {
         if(high[i] > sh) sh = high[i];
         if(low[i] < sl) sl = low[i];
        }
      r.swing_high = sh;
      r.swing_low = sl;

      const double ph = high[3], pl = low[3];
      const double ch = high[1], cl = low[1];

      r.structure = GM_TREND_STRUCT_NONE;
      r.bos_up = r.bos_down = false;
      r.choch_up = r.choch_down = false;
      r.liq_sweep_high = r.liq_sweep_low = false;

      if(ch > ph && cl > pl)
         r.structure = GM_TREND_STRUCT_HH;
      else if(ch > ph && cl < pl)
         r.structure = GM_TREND_STRUCT_HL;
      else if(ch < ph && cl < pl)
         r.structure = GM_TREND_STRUCT_LL;
      else if(ch < ph && cl > pl)
         r.structure = GM_TREND_STRUCT_LH;

      // Liquidity sweep: wick beyond swing then close back inside
      if(high[0] > sh && close[0] < sh)
        {
         r.liq_sweep_high = true;
         r.structure = GM_TREND_STRUCT_LIQ_SWEEP_HIGH;
        }
      if(low[0] < sl && close[0] > sl)
        {
         r.liq_sweep_low = true;
         r.structure = GM_TREND_STRUCT_LIQ_SWEEP_LOW;
        }

      // BOS: close beyond swing in trend direction
      if(close[0] > sh)
        {
         r.bos_up = true;
         r.structure = GM_TREND_STRUCT_BOS_UP;
        }
      else if(close[0] < sl)
        {
         r.bos_down = true;
         r.structure = GM_TREND_STRUCT_BOS_DOWN;
        }

      // CHOCH: break opposite to prior primary bias
      if(r.prev_primary == GM_TREND_DIR_BEAR && close[0] > sh)
        {
         r.choch_up = true;
         r.structure = GM_TREND_STRUCT_CHOCH_UP;
        }
      else if(r.prev_primary == GM_TREND_DIR_BULL && close[0] < sl)
        {
         r.choch_down = true;
         r.structure = GM_TREND_STRUCT_CHOCH_DOWN;
        }
      else if(r.primary == GM_TREND_DIR_BEAR && close[0] > sh && !r.bos_up)
        {
         r.choch_up = true;
         r.structure = GM_TREND_STRUCT_CHOCH_UP;
        }
      else if(r.primary == GM_TREND_DIR_BULL && close[0] < sl && !r.bos_down)
        {
         r.choch_down = true;
         r.structure = GM_TREND_STRUCT_CHOCH_DOWN;
        }
     }
  };

#endif // GM_CMARKET_STRUCTURE_ENGINE_MQH
//+------------------------------------------------------------------+
