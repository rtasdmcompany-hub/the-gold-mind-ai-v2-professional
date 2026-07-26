//+------------------------------------------------------------------+
//|                                            CAIDataProvider.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CAI_DATA_PROVIDER_MQH
#define GM_CAI_DATA_PROVIDER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmAISnapshot.mqh"
#include "CAIDecisionCenter.mqh"
#include "../Phase2/CPhase2Bridge.mqh"
#include "../Analytics/CAnalyticsEngine.mqh"
#include "../Recovery/CRecoveryBase.mqh"
#include "../Protection/SGmAccountSnapshot.mqh"
#include "../Protection/SGmDrawdownState.mqh"
#include "../Risk/RiskConstants.mqh"
#include "../Logging/CLogger.mqh"

/// @file CAIDataProvider.mqh
/// @brief Centralized READ-ONLY collector for future AI models.
/// @warning Never mutates trades, risk, or strategy.

class CGmAIDataProvider
  {
private:
   CGmLogger             *m_logger;
   CGmPhase2Bridge       *m_bridge;
   CGmAnalyticsEngine    *m_analytics;
   CGmRecoveryBase       *m_recovery;
   CGmAIDecisionCenter   *m_decision;
   int                    m_atr_handle;
   string                 m_atr_symbol;
   SGmAISnapshot          m_last;
   datetime               m_last_collect;

   void EnsureAtr(const string symbol)
     {
      if(m_atr_handle != INVALID_HANDLE && m_atr_symbol == symbol)
         return;
      if(m_atr_handle != INVALID_HANDLE)
         IndicatorRelease(m_atr_handle);
      m_atr_symbol = symbol;
      m_atr_handle = iATR(symbol, PERIOD_H4, 14);
     }

   double ReadAtr(const string symbol)
     {
      EnsureAtr(symbol);
      if(m_atr_handle == INVALID_HANDLE)
         return 0.0;
      double buf[];
      ArraySetAsSeries(buf, true);
      if(CopyBuffer(m_atr_handle, 0, 0, 1, buf) <= 0)
         return 0.0;
      return buf[0];
     }

   double CandleRange(const string symbol, const ENUM_TIMEFRAMES tf, const int shift) const
     {
      const double hi = iHigh(symbol, tf, shift);
      const double lo = iLow(symbol, tf, shift);
      if(hi <= 0.0 || lo <= 0.0)
         return 0.0;
      return hi - lo;
     }

   string ClassifyVolatility(const double atr, const double daily_range) const
     {
      if(atr <= 0.0)
         return "UNKNOWN";
      if(daily_range <= 0.0)
         return "NORMAL";
      const double ratio = daily_range / atr;
      if(ratio >= 3.0)
         return "EXTREME";
      if(ratio >= 2.0)
         return "HIGH";
      if(ratio >= 1.0)
         return "NORMAL";
      return "LOW";
     }

   string ClassifyActivity(const int running, const int pending, const double spread) const
     {
      if(running + pending >= 4)
         return "BUSY";
      if(running + pending >= 1)
         return "ACTIVE";
      if(spread >= 50.0)
         return "WIDE_SPREAD";
      return "QUIET";
     }

public:
                     CGmAIDataProvider(void)
                       : m_logger(NULL), m_bridge(NULL), m_analytics(NULL),
                         m_recovery(NULL), m_decision(NULL),
                         m_atr_handle(INVALID_HANDLE), m_atr_symbol(""),
                         m_last_collect(0)
     {
      m_last.Reset();
     }

                    ~CGmAIDataProvider(void)
     {
      if(m_atr_handle != INVALID_HANDLE)
        {
         IndicatorRelease(m_atr_handle);
         m_atr_handle = INVALID_HANDLE;
        }
     }

   void Init(CGmLogger *logger,
             CGmPhase2Bridge *bridge,
             CGmAnalyticsEngine *analytics,
             CGmRecoveryBase *recovery,
             CGmAIDecisionCenter *decision)
     {
      m_logger = logger;
      m_bridge = bridge;
      m_analytics = analytics;
      m_recovery = recovery;
      m_decision = decision;
      m_last.Reset();
      m_last_collect = 0;
     }

   SGmAISnapshot Last(void) const { return m_last; }

   bool Collect(SGmAISnapshot &out, const bool force)
     {
      const datetime now = TimeCurrent();
      if(!force && m_last_collect > 0 && (now - m_last_collect) < GM_AI_SYNC_SEC)
        {
         out = m_last;
         return m_last.valid;
        }

      const ulong t0 = GetMicrosecondCount();
      out.Reset();

      if(m_decision != NULL)
         m_decision.ApplyToSnapshot(out);

      if(m_bridge != NULL)
        {
         out.magic = m_bridge.Magic();
         out.symbol = m_bridge.Symbol();
         out.h4_session_id = m_bridge.SessionId();
         out.registry_count = m_bridge.RegistryCount();
         out.running_trades = m_bridge.OwnPositions();
         out.pending_orders = m_bridge.OwnPendings();

         SGmAccountSnapshot acc;
         if(m_bridge.ReadAccount(acc) && acc.valid)
           {
            out.balance = acc.balance;
            out.equity = acc.equity;
           }
         SGmDrawdownState dd;
         if(m_bridge.ReadDrawdown(dd))
            out.current_dd_pct = dd.current_dd_pct;
        }

      if(StringLen(out.symbol) > 0)
        {
         const double ask = SymbolInfoDouble(out.symbol, SYMBOL_ASK);
         const double bid = SymbolInfoDouble(out.symbol, SYMBOL_BID);
         const double point = SymbolInfoDouble(out.symbol, SYMBOL_POINT);
         out.spread_points = (point > 0.0) ? (ask - bid) / point : 0.0;
         out.atr14 = ReadAtr(out.symbol);
         out.candle_size_cur = CandleRange(out.symbol, PERIOD_H4, 0);
         out.candle_size_prev = CandleRange(out.symbol, PERIOD_H4, 1);
         out.daily_range = CandleRange(out.symbol, PERIOD_D1, 0);
         out.weekly_range = CandleRange(out.symbol, PERIOD_W1, 0);
         out.market_volatility = ClassifyVolatility(out.atr14, out.daily_range);
         out.market_activity = ClassifyActivity(out.running_trades, out.pending_orders,
                                                out.spread_points);
        }

      if(m_analytics != NULL)
        {
         m_analytics.Collect();
         const SGmAnalyticsSnapshot a = m_analytics.Snapshot();
         if(a.valid)
           {
            out.overall_win_rate = a.overall_win_rate;
            out.analytics_ok = true;
            if(out.balance <= 0.0)
               out.balance = a.balance;
            if(out.equity <= 0.0)
               out.equity = a.equity;
            if(out.current_dd_pct <= 0.0)
               out.current_dd_pct = a.current_dd_pct;
            if(out.spread_points <= 0.0)
               out.spread_points = a.spread_points;
            if(out.atr14 <= 0.0)
               out.atr14 = a.atr14;
            if(out.running_trades <= 0)
               out.running_trades = a.running_trades;
            if(out.pending_orders <= 0)
               out.pending_orders = a.pending_orders;
           }
        }

      if(m_recovery != NULL)
         out.recovery_ok = m_recovery.LastSnapshot().state_restored;

      out.dashboard_ok = true;
      out.memory_kb = (ulong)TerminalInfoInteger(TERMINAL_MEMORY_USED);
      out.collect_us = GetMicrosecondCount() - t0;
      out.stamped_at = now;
      out.valid = true;
      m_last = out;
      m_last_collect = now;

      if(m_logger != NULL)
         m_logger.Debug(StringFormat("AI Data Updated | %I64u us | mem=%I64u KB",
                                     out.collect_us, out.memory_kb),
                        "AIDataProvider");
      return true;
     }
  };

#endif // GM_CAI_DATA_PROVIDER_MQH
//+------------------------------------------------------------------+
