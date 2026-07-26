//+------------------------------------------------------------------+
//|                                        CTakeProfitEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CTAKE_PROFIT_ENGINE_MQH
#define GM_CTAKE_PROFIT_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CAtrEngine.mqh"
#include "../Logging/CLogger.mqh"
#include "../Calculation/EnumsLevels.mqh"

/// @file CTakeProfitEngine.mqh
/// @brief Official ATR(14) Take Profit: TP = entry ± (ATR × 1.0).

class CGmTakeProfitEngine
  {
private:
   CGmLogger    *m_logger;
   CGmAtrEngine *m_atr;
   string        m_symbol;
   bool          m_initialized;

public:
                     CGmTakeProfitEngine(void)
                       : m_logger(NULL),
                         m_atr(NULL),
                         m_symbol(""),
                         m_initialized(false)
     {
     }

                    ~CGmTakeProfitEngine(void)
     {
      m_logger = NULL;
      m_atr = NULL;
     }

   bool Init(CGmLogger *logger, CGmAtrEngine *atr, const string symbol)
     {
      m_logger = logger;
      m_atr = atr;
      m_symbol = symbol;
      m_initialized = (m_atr != NULL);
      if(m_logger != NULL)
         m_logger.Info("Take Profit Engine ready | ATR(14)×1.0", "TakeProfitEngine");
      return m_initialized;
     }

   bool CalculateTakeProfit(const double entry,
                            const ENUM_GM_LEVEL_SIDE side,
                            double &tp_out)
     {
      tp_out = 0.0;
      if(!m_initialized || entry <= 0.0 || m_atr == NULL)
         return false;

      double tp_dist = 0.0;
      if(!m_atr.GetTakeProfitDistance(tp_dist))
         return false;

      const int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
      if(side == GM_LEVEL_SIDE_BUY)
         tp_out = NormalizeDouble(entry + tp_dist, digits);
      else
         tp_out = NormalizeDouble(entry - tp_dist, digits);

      if(m_logger != NULL)
         m_logger.Info(StringFormat("TP calc | side=%s entry=%.5f tp=%.5f dist=%.5f",
                                    (side == GM_LEVEL_SIDE_BUY) ? "BUY" : "SELL",
                                    entry, tp_out, tp_dist),
                       "TakeProfitEngine");
      return (tp_out > 0.0);
     }
  };

#endif // GM_CTAKE_PROFIT_ENGINE_MQH
//+------------------------------------------------------------------+
