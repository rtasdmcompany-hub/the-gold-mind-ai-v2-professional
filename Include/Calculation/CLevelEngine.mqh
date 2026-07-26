//+------------------------------------------------------------------+
//|                                               CLevelEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CLEVEL_ENGINE_MQH
#define GM_CLEVEL_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CLevelBase.mqh"
#include "SGmLevels.mqh"
#include "LevelConstants.mqh"
#include "../Core/TradingRules.mqh"

/// @file CLevelEngine.mqh
/// @brief Official Gold Mind H4 Trading Level Engine.
/// @details Exact production formulas — NOT optimized, NOT altered:
///          diff = High - Low (last CLOSED H4)
///          BuyN  = Low  - diff * {0.20, 0.58, 0.92}
///          SellN = High + diff * {0.20, 0.58, 0.92}

//+------------------------------------------------------------------+
//| CGmLevelEngine                                                   |
//+------------------------------------------------------------------+
class CGmLevelEngine : public CGmLevelBase
  {
private:
   string     m_symbol;
   SGmLevels  m_levels;

public:
                     CGmLevelEngine(void)
                       : m_symbol("")
     {
      m_module_name = "LevelEngine";
      m_levels.Reset();
     }

   virtual          ~CGmLevelEngine(void) {}

   virtual bool Init(CGmLogger *logger)
     {
      if(!CGmLevelBase::Init(logger))
         return false;
      m_status = GM_MODULE_READY;
      if(m_logger != NULL)
         m_logger.Info("Level Engine ready | official fractions 0.20 / 0.58 / 0.92", m_module_name);
      return true;
     }

   void SetSymbol(const string symbol) { m_symbol = symbol; }

   SGmLevels GetLevelsCopy(void) const { return m_levels; }
   bool IsValid(void) const { return m_levels.valid; }

   /// @brief Generate levels from the most recently CLOSED H4 candle (shift 1).
   virtual bool Recalculate(void)
     {
      const ulong t0 = GetMicrosecondCount();
      m_levels.Reset();

      if(StringLen(m_symbol) == 0)
        {
         if(m_logger != NULL)
            m_logger.Error("Level generation failed — empty symbol", m_module_name);
         m_status = GM_MODULE_FAULT;
         return false;
        }

      const datetime bar_time = iTime(m_symbol, GM_POLICY_STRATEGY_TIMEFRAME, 1);
      const double high1 = iHigh(m_symbol, GM_POLICY_STRATEGY_TIMEFRAME, 1);
      const double low1  = iLow(m_symbol, GM_POLICY_STRATEGY_TIMEFRAME, 1);

      if(bar_time <= 0 || high1 <= 0.0 || low1 <= 0.0 || high1 <= low1)
        {
         if(m_logger != NULL)
            m_logger.Error(StringFormat("Invalid CLOSED H4 data | high=%.5f low=%.5f time=%s",
                                        high1, low1, TimeToString(bar_time, TIME_DATE | TIME_MINUTES)),
                           m_module_name);
         m_status = GM_MODULE_FAULT;
         return false;
        }

      const int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
      const double diff = high1 - low1;

      // Official Gold Mind calculation — identical to CalculateH4GridLevels().
      m_levels.h4_bar_time = bar_time;
      m_levels.high = high1;
      m_levels.low  = low1;
      m_levels.diff = diff;
      m_levels.pivot = NormalizeDouble((high1 + low1) / 2.0, digits);
      m_levels.buy1  = NormalizeDouble(low1  - (diff * GM_LEVEL_FRAC_1), digits);
      m_levels.buy2  = NormalizeDouble(low1  - (diff * GM_LEVEL_FRAC_2), digits);
      m_levels.buy3  = NormalizeDouble(low1  - (diff * GM_LEVEL_FRAC_3), digits);
      m_levels.sell1 = NormalizeDouble(high1 + (diff * GM_LEVEL_FRAC_1), digits);
      m_levels.sell2 = NormalizeDouble(high1 + (diff * GM_LEVEL_FRAC_2), digits);
      m_levels.sell3 = NormalizeDouble(high1 + (diff * GM_LEVEL_FRAC_3), digits);
      m_levels.valid = true;
      m_status = GM_MODULE_READY;

      const ulong elapsed_us = GetMicrosecondCount() - t0;
      if(m_logger != NULL)
        {
         m_logger.Success(StringFormat("Levels generated from CLOSED H4 | bar=%s | High=%.5f Low=%.5f Diff=%.5f | %I64u us",
                                       TimeToString(bar_time, TIME_DATE | TIME_MINUTES),
                                       high1, low1, diff, elapsed_us),
                          m_module_name);
         m_logger.Info(StringFormat("BUY  L1=%.5f L2=%.5f L3=%.5f",
                                    m_levels.buy1, m_levels.buy2, m_levels.buy3),
                       m_module_name);
         m_logger.Info(StringFormat("SELL L1=%.5f L2=%.5f L3=%.5f",
                                    m_levels.sell1, m_levels.sell2, m_levels.sell3),
                       m_module_name);
        }
      return true;
     }
  };

#endif // GM_CLEVEL_ENGINE_MQH
//+------------------------------------------------------------------+
