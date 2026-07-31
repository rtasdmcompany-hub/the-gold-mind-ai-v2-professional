//+------------------------------------------------------------------+
//|                                            CLotSizeEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CLOT_SIZE_ENGINE_MQH
#define GM_CLOT_SIZE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "RiskConstants.mqh"
#include "../Logging/CLogger.mqh"
#include "../TradeManagement/CPipTools.mqh"

/// @file CLotSizeEngine.mqh
/// @brief Dynamic lot size = 3% of equity risked across SL price distance.
/// @details Ported from The_Gold_Mind v2.065 CalculateAutoLotSize + NormalizeVolume.

class CGmLotSizeEngine
  {
private:
   CGmLogger *m_logger;
   string     m_symbol;
   double     m_risk_fraction;
   bool       m_initialized;

public:
                     CGmLotSizeEngine(void)
                       : m_logger(NULL),
                         m_symbol(""),
                         m_risk_fraction(GM_RISK_EQUITY_FRACTION),
                         m_initialized(false)
     {
     }

                    ~CGmLotSizeEngine(void) { m_logger = NULL; }

   bool Init(CGmLogger *logger, const string symbol,
             const double risk_fraction = GM_RISK_EQUITY_FRACTION)
     {
      m_logger = logger;
      m_symbol = symbol;
      m_risk_fraction = (risk_fraction > 0.0) ? risk_fraction : GM_RISK_EQUITY_FRACTION;
      m_initialized = true;
      if(m_logger != NULL)
         m_logger.Info(StringFormat(
            "TGM [LOT]: Max_Lot_Size=%.2f | AutoRisk=%.0f%% of EQUITY per trade.",
            GM_MAX_LOT_SIZE, m_risk_fraction * 100.0),
            "LotEngine");
      return true;
     }

   /// @brief Official NormalizeVolume from The_Gold_Mind — hard cap at GM_MAX_LOT_SIZE.
   double NormalizeVolume(double volume) const
     {
      const double vmin = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
      double vmax = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
      const double vstep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
      if(GM_MAX_LOT_SIZE > 0.0 && (vmax <= 0.0 || GM_MAX_LOT_SIZE < vmax))
         vmax = GM_MAX_LOT_SIZE;
      if(vstep > 0.0)
         volume = MathFloor(volume / vstep) * vstep;
      if(vmin > 0.0 && volume < vmin)
         volume = vmin;
      if(vmax > 0.0 && volume > vmax)
         volume = vmax;
      return NormalizeDouble(volume, 2);
     }

   /// @brief The_Gold_Mind v2.065 CalculateAutoLotSize — tick-value formula (proven on Exness XAU).
   bool CalculateLots(const double sl_distance_price, double &lots_out)
     {
      lots_out = 0.0;
      if(!m_initialized)
         return false;

      const double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      if(point <= 0.0 || sl_distance_price <= 0.0)
        {
         lots_out = NormalizeVolume(0.01);
         return (lots_out > 0.0);
        }

      // Mode B official: $3.00 fixed SL distance for lot math on XAU.
      double sl_use = sl_distance_price;
      const double expected_sl = CGmPipTools::PipsToPrice(m_symbol, GM_FIXED_SL_PIPS);
      if(expected_sl > 0.0 && MathAbs(sl_distance_price - expected_sl) > expected_sl * 0.15)
        {
         if(m_logger != NULL)
            m_logger.Warning(StringFormat(
               "SL distance %.5f != official %.5f — using official for lot calc",
               sl_distance_price, expected_sl),
               "LotEngine");
         sl_use = expected_sl;
        }

      const double sl_points = sl_use / point;
      const double tick_size = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
      const double tick_value = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
      if(sl_points <= 0.0 || tick_size <= 0.0 || tick_value <= 0.0)
        {
         lots_out = NormalizeVolume(0.01);
         return (lots_out > 0.0);
        }

      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      if(equity <= 0.0)
         equity = AccountInfoDouble(ACCOUNT_BALANCE);
      if(equity <= 0.0)
        {
         lots_out = NormalizeVolume(0.01);
         return (lots_out > 0.0);
        }

      const double risk_amount = equity * m_risk_fraction;
      const double points_value = (point / tick_size) * tick_value;
      lots_out = NormalizeVolume(risk_amount / (sl_points * points_value));

      if(m_logger != NULL)
         m_logger.Info(StringFormat(
            "Lot calc | equity=%.2f risk=%.2f (%.0f%%) sl=$%.2f pts=%.0f → lots=%.2f (cap %.2f)",
            equity, risk_amount, m_risk_fraction * 100.0,
            sl_use, sl_points, lots_out, GM_MAX_LOT_SIZE),
            "LotEngine");

      return (lots_out > 0.0);
     }
  };

#endif // GM_CLOT_SIZE_ENGINE_MQH
//+------------------------------------------------------------------+
