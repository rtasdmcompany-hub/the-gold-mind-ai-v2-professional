//+------------------------------------------------------------------+
//|                                         CBrokerValidator.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CBROKER_VALIDATOR_MQH
#define GM_CBROKER_VALIDATOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "RiskConstants.mqh"
#include "../Logging/CLogger.mqh"

/// @file CBrokerValidator.mqh
/// @brief Pre-trade broker / market / margin / lot / stop-distance gates.

class CGmBrokerValidator
  {
private:
   CGmLogger *m_logger;
   string     m_symbol;
   int        m_max_spread_points;
   bool       m_initialized;
   string     m_last_reason;

public:
                     CGmBrokerValidator(void)
                       : m_logger(NULL),
                         m_symbol(""),
                         m_max_spread_points(GM_MAX_SPREAD_POINTS_DEFAULT),
                         m_initialized(false),
                         m_last_reason("")
     {
     }

                    ~CGmBrokerValidator(void) { m_logger = NULL; }

   bool Init(CGmLogger *logger, const string symbol,
             const int max_spread_points = GM_MAX_SPREAD_POINTS_DEFAULT)
     {
      m_logger = logger;
      m_symbol = symbol;
      m_max_spread_points = (max_spread_points > 0) ? max_spread_points : GM_MAX_SPREAD_POINTS_DEFAULT;
      m_initialized = true;
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Broker Validator ready | maxSpread=%d pts", m_max_spread_points),
                       "BrokerValidator");
      return true;
     }

   void SetMaxSpreadPoints(const int max_spread_points)
     {
      m_max_spread_points = (max_spread_points > 0) ? max_spread_points : m_max_spread_points;
     }

   int MaxSpreadPoints(void) const { return m_max_spread_points; }

   string LastReason(void) const { return m_last_reason; }

   bool Fail(const string reason)
     {
      m_last_reason = reason;
      if(m_logger != NULL)
         m_logger.Warning("Broker validation FAIL | " + reason, "BrokerValidator");
      return false;
     }

   bool ValidateTradingAllowed(void)
     {
      if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
         return Fail("Terminal trading disabled");
      if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
         return Fail("EA trading permission disabled");
      if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
         return Fail("Account trading not allowed");
      if(!AccountInfoInteger(ACCOUNT_TRADE_EXPERT))
         return Fail("Expert trading not allowed on account");
      return true;
     }

   bool ValidateMarketOpen(void)
     {
      if(!SymbolInfoInteger(m_symbol, SYMBOL_TRADE_MODE))
         return Fail("Symbol trade mode blocked");

      const long trade_mode = SymbolInfoInteger(m_symbol, SYMBOL_TRADE_MODE);
      if(trade_mode == SYMBOL_TRADE_MODE_DISABLED)
         return Fail("Symbol trading disabled");

      const datetime tick_time = (datetime)SymbolInfoInteger(m_symbol, SYMBOL_TIME);
      if(tick_time <= 0)
         return Fail("No symbol tick time");
      if(TimeCurrent() - tick_time > 600)
         return Fail("Stale quotes (>10 min) — market likely closed");
      return true;
     }

   bool ValidateSpread(void)
     {
      const long spread = SymbolInfoInteger(m_symbol, SYMBOL_SPREAD);
      if(spread < 0)
         return Fail("Invalid spread");
      if(spread > m_max_spread_points)
         return Fail(StringFormat("Spread too wide | spread=%d max=%d",
                                  (int)spread, m_max_spread_points));
      return true;
     }

   bool ValidateLot(const double lots)
     {
      const double vmin = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
      const double vmax = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
      const double vstep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
      if(lots <= 0.0)
         return Fail("Lot <= 0");
      if(vmin > 0.0 && lots + 1e-8 < vmin)
         return Fail(StringFormat("Lot %.2f < min %.2f", lots, vmin));
      if(vmax > 0.0 && lots - 1e-8 > vmax)
         return Fail(StringFormat("Lot %.2f > max %.2f", lots, vmax));
      if(vstep > 0.0)
        {
         const double steps = lots / vstep;
         if(MathAbs(steps - MathRound(steps)) > 1e-6)
            return Fail(StringFormat("Lot %.2f not aligned to step %.2f", lots, vstep));
        }
      return true;
     }

   bool ValidateFreeMargin(const double lots, const ENUM_ORDER_TYPE type, const double price)
     {
      double margin = 0.0;
      if(!OrderCalcMargin(type, m_symbol, lots, price, margin))
         return Fail(StringFormat("OrderCalcMargin failed | err=%d", GetLastError()));
      const double free = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      if(margin > free)
         return Fail(StringFormat("Insufficient free margin | need=%.2f free=%.2f", margin, free));
      return true;
     }

   bool ValidateStopDistance(const double entry, const double sl, const double tp)
     {
      const long stops_level = SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL);
      const double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      if(point <= 0.0)
         return Fail("Invalid point size");
      const double min_dist = (double)stops_level * point;

      if(sl > 0.0 && MathAbs(entry - sl) < min_dist)
         return Fail(StringFormat("SL too close | dist=%.5f min=%.5f", MathAbs(entry - sl), min_dist));
      if(tp > 0.0 && MathAbs(entry - tp) < min_dist)
         return Fail(StringFormat("TP too close | dist=%.5f min=%.5f", MathAbs(entry - tp), min_dist));
      return true;
     }

   /// @brief Full pre-pending validation suite.
   bool ValidatePending(const ENUM_ORDER_TYPE type,
                        const double lots,
                        const double price,
                        const double sl,
                        const double tp)
     {
      m_last_reason = "";
      if(!m_initialized)
         return Fail("Validator not initialized");
      if(!ValidateTradingAllowed()) return false;
      if(!ValidateMarketOpen()) return false;
      if(!ValidateSpread()) return false;
      if(!ValidateLot(lots)) return false;
      if(!ValidateFreeMargin(lots, type, price)) return false;
      if(!ValidateStopDistance(price, sl, tp)) return false;

      if(m_logger != NULL)
         m_logger.Info(StringFormat("Broker validation OK | %s lots=%.2f price=%.5f sl=%.5f tp=%.5f",
                                    EnumToString(type), lots, price, sl, tp),
                       "BrokerValidator");
      return true;
     }
  };

#endif // GM_CBROKER_VALIDATOR_MQH
//+------------------------------------------------------------------+
