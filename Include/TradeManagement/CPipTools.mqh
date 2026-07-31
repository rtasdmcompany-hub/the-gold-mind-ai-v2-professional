//+------------------------------------------------------------------+
//|                                                 CPipTools.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CPIP_TOOLS_MQH
#define GM_CPIP_TOOLS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../Risk/RiskConstants.mqh"

/// @file CPipTools.mqh
/// @brief Shared pip sizing (aligned with Sprint 3 Stop Loss engine).

class CGmPipTools
  {
public:
   /// @brief True for gold/silver symbols (XAU/XAG/GOLD).
   static bool IsMetalSymbol(const string symbol)
     {
      string s = symbol;
      StringToUpper(s);
      return (StringFind(s, "XAU") >= 0 ||
              StringFind(s, "XAG") >= 0 ||
              StringFind(s, "GOLD") >= 0 ||
              StringFind(s, "SILVER") >= 0);
     }

   /// @brief Official Gold Mind pip size.
   /// @details XAU: 1 pip = 0.10 → 30 pips = 3.00 (works on Exness digits=3 and classic digits=2).
   ///          Forex 3/5-digit: 1 pip = 10 points.
   static double PipSize(const string symbol)
     {
      const double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      if(point <= 0.0)
         return 0.0;
      // Fixed metal pip — NEVER use point*10 on 3-digit gold (that yields 0.01 → wrong SL 0.30 / huge lots)
      if(IsMetalSymbol(symbol))
         return 0.10;
      const int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      if(digits == 2 || digits == 3 || digits == 4 || digits == 5)
         return point * 10.0;
      return point;
     }

   static double PipsToPrice(const string symbol, const double pips)
     {
      return pips * PipSize(symbol);
     }

   /// @brief Unrealized profit in pips for an open position.
   static double ProfitPips(const string symbol,
                            const long pos_type,
                            const double open_price)
     {
      const double pip = PipSize(symbol);
      if(pip <= 0.0 || open_price <= 0.0)
         return 0.0;
      if(pos_type == POSITION_TYPE_BUY)
        {
         const double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
         return (bid - open_price) / pip;
        }
      const double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
      return (open_price - ask) / pip;
     }

   static double NormalizeVolume(const string symbol, double volume)
     {
      const double vmin = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
      double vmax = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
      const double vstep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
      if(GM_MAX_LOT_SIZE > 0.0 && (vmax <= 0.0 || GM_MAX_LOT_SIZE < vmax))
         vmax = GM_MAX_LOT_SIZE;
      if(vstep > 0.0)
         volume = MathFloor(volume / vstep + 1e-8) * vstep;
      if(vmin > 0.0 && volume < vmin)
         volume = 0.0; // cannot partial below min — caller handles
      if(vmax > 0.0 && volume > vmax)
         volume = vmax;
      return NormalizeDouble(volume, 2);
     }
  };

#endif // GM_CPIP_TOOLS_MQH
//+------------------------------------------------------------------+
