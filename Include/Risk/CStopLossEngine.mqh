//+------------------------------------------------------------------+
//|                                           CStopLossEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CSTOP_LOSS_ENGINE_MQH
#define GM_CSTOP_LOSS_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "RiskConstants.mqh"
#include "../Logging/CLogger.mqh"
#include "../Calculation/EnumsLevels.mqh"

/// @file CStopLossEngine.mqh
/// @brief Fixed 30-pip Stop Loss engine (never leave a trade unprotected).

class CGmStopLossEngine
  {
private:
   CGmLogger *m_logger;
   string     m_symbol;
   double     m_sl_pips;
   bool       m_initialized;

   /// @brief Pip size matching Gold Mind metals + forex.
   /// @details XAU: 1 pip = 0.10 → 30 pips = 3.00 (Exness digits=3 and classic digits=2).
   double PipSize(void) const
     {
      const double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      if(point <= 0.0)
         return 0.0;
      string s = m_symbol;
      StringToUpper(s);
      if(StringFind(s, "XAU") >= 0 || StringFind(s, "XAG") >= 0 ||
         StringFind(s, "GOLD") >= 0 || StringFind(s, "SILVER") >= 0)
         return 0.10;
      const int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
      if(digits == 2 || digits == 3 || digits == 4 || digits == 5)
         return point * 10.0;
      return point;
     }

public:
                     CGmStopLossEngine(void)
                       : m_logger(NULL),
                         m_symbol(""),
                         m_sl_pips(GM_FIXED_SL_PIPS),
                         m_initialized(false)
     {
     }

                    ~CGmStopLossEngine(void) { m_logger = NULL; }

   bool Init(CGmLogger *logger, const string symbol, const double sl_pips = GM_FIXED_SL_PIPS)
     {
      m_logger = logger;
      m_symbol = symbol;
      m_sl_pips = (sl_pips > 0.0) ? sl_pips : GM_FIXED_SL_PIPS;
      m_initialized = true;
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Stop Loss Engine ready | fixed=%.0f pips | dist=%.5f",
                                    m_sl_pips, StopDistancePrice()),
                       "StopLossEngine");
      return true;
     }

   double StopDistancePrice(void) const
     {
      return m_sl_pips * PipSize();
     }

   /// @brief Absolute SL price from entry for buy/sell.
   bool CalculateStopLoss(const double entry,
                          const ENUM_GM_LEVEL_SIDE side,
                          double &sl_out)
     {
      sl_out = 0.0;
      if(!m_initialized || entry <= 0.0)
         return false;

      const double dist = StopDistancePrice();
      if(dist <= 0.0)
         return false;

      const int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
      if(side == GM_LEVEL_SIDE_BUY)
         sl_out = NormalizeDouble(entry - dist, digits);
      else
         sl_out = NormalizeDouble(entry + dist, digits);

      if(m_logger != NULL)
         m_logger.Info(StringFormat("SL calc | side=%s entry=%.5f sl=%.5f (%.0f pips)",
                                    (side == GM_LEVEL_SIDE_BUY) ? "BUY" : "SELL",
                                    entry, sl_out, m_sl_pips),
                       "StopLossEngine");
      return (sl_out > 0.0);
     }
  };

#endif // GM_CSTOP_LOSS_ENGINE_MQH
//+------------------------------------------------------------------+
