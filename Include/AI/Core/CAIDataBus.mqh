//+------------------------------------------------------------------+
//|                                                CAIDataBus.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CAI_DATA_BUS_MQH
#define GM_CAI_DATA_BUS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmAIBusSnapshot.mqh"
#include "SGmAICoreSettings.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Analytics/CAnalyticsEngine.mqh"
#include "../../Recovery/CRecoveryBase.mqh"
#include "../../Protection/SGmAccountSnapshot.mqh"
#include "../../Protection/SGmDrawdownState.mqh"
#include "../../Logging/CLogger.mqh"

/// @file CAIDataBus.mqh
/// @brief Central observation bus — NEVER binds TradeManager/Pending/Risk mutators.

class CGmAIDataBus
  {
private:
   CGmLogger           *m_logger;
   CGmPhase2Bridge     *m_bridge;      ///< read-only Core surface
   CGmAnalyticsEngine  *m_analytics;   ///< read-only analytics
   CGmRecoveryBase     *m_recovery;    ///< recovery snapshot only
   SGmAICoreSettings    m_settings;
   SGmAIBusSnapshot     m_last;
   ulong                m_last_ms;
   bool                 m_ready;

public:
                     CGmAIDataBus(void)
                       : m_logger(NULL), m_bridge(NULL), m_analytics(NULL),
                         m_recovery(NULL), m_last_ms(0), m_ready(false)
     {
      m_settings.Defaults();
      m_last.Reset();
     }

   bool Init(CGmLogger *logger,
             CGmPhase2Bridge *bridge,
             CGmAnalyticsEngine *analytics,
             CGmRecoveryBase *recovery,
             const SGmAICoreSettings &settings)
     {
      m_logger = logger;
      m_bridge = bridge;
      m_analytics = analytics;
      m_recovery = recovery;
      m_settings = settings;
      m_settings.Clamp();
      m_last.Reset();
      m_last_ms = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Success("AI Data Bus ready | observation sources only (no trade modules)",
                          "AIDataBus");
      return true;
     }

   bool IsReady(void) const { return m_ready; }
   SGmAIBusSnapshot Last(void) const { return m_last; }

   void SetSettings(const SGmAICoreSettings &settings)
     {
      m_settings = settings;
      m_settings.Clamp();
     }

   /// @return true when a fresh observation was collected.
   bool Collect(SGmAIBusSnapshot &out)
     {
      out.Reset();
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(m_last_ms != 0 &&
         (now - m_last_ms) < (ulong)m_settings.bus_throttle_ms &&
         m_last.valid)
        {
         out = m_last;
         return true;
        }

      out.stamped_at = TimeCurrent();
      out.broker_connected = (TerminalInfoInteger(TERMINAL_CONNECTED) != 0);
      out.trade_allowed = (TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) != 0);

      if(m_bridge != NULL)
        {
         out.symbol = m_bridge.Symbol();
         out.magic = m_bridge.Magic();
         out.session_id = m_bridge.SessionId();
         out.h4_cycle = m_bridge.H4Cycle();
         out.open_positions = m_bridge.OwnPositions();
         out.pending_orders = m_bridge.OwnPendings();
         out.registry_count = m_bridge.RegistryCount();

         SGmAccountSnapshot acc;
         if(m_bridge.ReadAccount(acc) && acc.valid)
           {
            out.balance = acc.balance;
            out.equity = acc.equity;
           }
         SGmDrawdownState dd;
         if(m_bridge.ReadDrawdown(dd) && dd.valid)
           {
            out.current_dd_pct = dd.current_dd_pct;
            out.maximum_dd_pct = dd.max_dd_pct;
           }
        }

      if(StringLen(out.symbol) > 0)
        {
         out.bid = SymbolInfoDouble(out.symbol, SYMBOL_BID);
         out.ask = SymbolInfoDouble(out.symbol, SYMBOL_ASK);
         const double point = SymbolInfoDouble(out.symbol, SYMBOL_POINT);
         if(point > 0.0)
            out.spread_points = (out.ask - out.bid) / point;
         // ATR(14) H4 — observation only
         const int h = iATR(out.symbol, PERIOD_H4, 14);
         if(h != INVALID_HANDLE)
           {
            double buf[];
            ArraySetAsSeries(buf, true);
            if(CopyBuffer(h, 0, 0, 1, buf) > 0)
               out.atr14 = buf[0];
            IndicatorRelease(h);
           }
        }

      if(m_analytics != NULL)
        {
         m_analytics.Collect();
         const SGmAnalyticsSnapshot a = m_analytics.Snapshot();
         out.analytics_valid = a.valid;
         if(a.valid)
           {
            out.floating_profit = a.floating_profit;
            out.floating_loss = a.floating_loss;
            out.overall_win_rate = a.overall_win_rate;
            out.profit_factor = a.profit_factor;
            out.recovery_factor = a.recovery_factor;
            out.total_net = a.total_net_profit;
            if(out.current_dd_pct <= 0.0)
               out.current_dd_pct = a.current_dd_pct;
            if(out.maximum_dd_pct <= 0.0)
               out.maximum_dd_pct = a.maximum_dd_pct;
           }
        }

      if(m_recovery != NULL)
        {
         const SGmRecoverySnapshot rs = m_recovery.LastSnapshot();
         out.recovery_ok = rs.state_restored;
        }

      out.valid = (StringLen(out.symbol) > 0 || out.magic != 0 || out.analytics_valid);
      m_last = out;
      m_last_ms = now;
      return out.valid;
     }
  };

#endif // GM_CAI_DATA_BUS_MQH
//+------------------------------------------------------------------+
