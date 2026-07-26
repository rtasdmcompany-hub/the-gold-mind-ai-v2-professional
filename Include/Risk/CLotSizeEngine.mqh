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

/// @file CLotSizeEngine.mqh
/// @brief Dynamic lot size = 3% of equity risked across SL price distance.
/// @details Official CalculateAutoLotSize formula from production EA.

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
         m_logger.Info(StringFormat("Lot Size Engine ready | risk=%.2f%% of equity",
                                    m_risk_fraction * 100.0),
                       "LotEngine");
      return true;
     }

   double NormalizeVolume(double volume) const
     {
      const double vmin = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
      const double vmax = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
      const double vstep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
      if(vstep > 0.0)
         volume = MathFloor(volume / vstep) * vstep;
      if(vmin > 0.0 && volume < vmin)
         volume = vmin;
      if(vmax > 0.0 && volume > vmax)
         volume = vmax;
      return NormalizeDouble(volume, 2);
     }

   /// @brief Official 3% equity risk lot from SL price distance.
   bool CalculateLots(const double sl_distance_price, double &lots_out)
     {
      lots_out = 0.0;
      if(!m_initialized)
         return false;

      const double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      if(point <= 0.0 || sl_distance_price <= 0.0)
        {
         if(m_logger != NULL)
            m_logger.Error("Lot calc failed — invalid point or SL distance", "LotEngine");
         return false;
        }

      const double sl_points = sl_distance_price / point;
      const double tick_size = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
      const double tick_value = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
      if(sl_points <= 0.0 || tick_size <= 0.0 || tick_value <= 0.0)
        {
         if(m_logger != NULL)
            m_logger.Error("Lot calc failed — invalid tick metrics", "LotEngine");
         return false;
        }

      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      if(equity <= 0.0)
         equity = AccountInfoDouble(ACCOUNT_BALANCE);
      if(equity <= 0.0)
        {
         if(m_logger != NULL)
            m_logger.Error("Lot calc failed — equity/balance unavailable", "LotEngine");
         return false;
        }

      const double risk_amount = equity * m_risk_fraction;
      const double points_value = (point / tick_size) * tick_value;
      if(points_value <= 0.0)
         return false;

      double lots = risk_amount / (sl_points * points_value);
      lots_out = NormalizeVolume(lots);

      if(m_logger != NULL)
         m_logger.Info(StringFormat("Lot calc | equity=%.2f risk=%.2f (%.2f%%) slDist=%.5f slPts=%.1f → lots=%.2f",
                                    equity, risk_amount, m_risk_fraction * 100.0,
                                    sl_distance_price, sl_points, lots_out),
                       "LotEngine");

      return (lots_out > 0.0);
     }
  };

#endif // GM_CLOT_SIZE_ENGINE_MQH
//+------------------------------------------------------------------+
