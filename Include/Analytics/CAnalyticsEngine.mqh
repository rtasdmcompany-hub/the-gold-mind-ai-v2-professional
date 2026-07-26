//+------------------------------------------------------------------+
//|                                      CAnalyticsEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CANALYTICS_ENGINE_MQH
#define GM_CANALYTICS_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../Reports/CAnalyticsBase.mqh"
#include "../Phase2/IPhase2Interfaces.mqh"
#include "../Phase2/CPhase2Bridge.mqh"
#include "../Recovery/CRecoveryBase.mqh"
#include "../Risk/RiskConstants.mqh"
#include "../Protection/ProtectionConstants.mqh"
#include "../Protection/SGmDrawdownState.mqh"
#include "../TradeManagement/CPipTools.mqh"
#include "../Trading/SGmTradeRecord.mqh"
#include "SGmAnalyticsSnapshot.mqh"
#include "CAnalyticsPerfMonitor.mqh"
#include "CAnalyticsExport.mqh"
#include "AnalyticsConstants.mqh"

/// @file CAnalyticsEngine.mqh
/// @brief Phase 2 Sprint 3 — Enterprise Analytics Engine (READ-ONLY).
/// @warning Never opens/closes/modifies trades or risk settings.

class CGmAnalyticsEngine : public CGmAnalyticsBase
  {
private:
   CGmPhase2Bridge         *m_bridge;
   CGmRecoveryBase         *m_recovery;
   CGmAnalyticsPerfMonitor  m_perf;
   CGmAnalyticsExport       m_export;
   SGmAnalyticsSnapshot     m_snap;
   datetime                 m_last_hist;
   int                      m_atr_handle;
   string                   m_atr_symbol;
   double                   m_peak_risk_pct;
   double                   m_risk_sum;
   int                      m_risk_samples;

   datetime DayStart(const datetime t) const
     {
      MqlDateTime dt;
      TimeToStruct(t, dt);
      dt.hour = 0; dt.min = 0; dt.sec = 0;
      return StructToTime(dt);
     }

   datetime WeekStart(const datetime t) const
     {
      const datetime d0 = DayStart(t);
      MqlDateTime dt;
      TimeToStruct(d0, dt);
      int dow = dt.day_of_week; // 0=Sun
      if(dow == 0)
         dow = 7;
      return d0 - (datetime)((dow - 1) * 86400);
     }

   datetime MonthStart(const datetime t) const
     {
      MqlDateTime dt;
      TimeToStruct(t, dt);
      dt.day = 1; dt.hour = 0; dt.min = 0; dt.sec = 0;
      return StructToTime(dt);
     }

   void EnsureAtr(const string symbol)
     {
      if(m_atr_handle != INVALID_HANDLE && m_atr_symbol == symbol)
         return;
      if(m_atr_handle != INVALID_HANDLE)
         IndicatorRelease(m_atr_handle);
      m_atr_symbol = symbol;
      m_atr_handle = iATR(symbol, GM_ATR_TIMEFRAME, GM_ATR_PERIOD);
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

   void CollectLive(SGmAnalyticsSnapshot &o)
     {
      o.running_trades = (m_bridge != NULL) ? m_bridge.OwnPositions() : 0;
      o.pending_orders = (m_bridge != NULL) ? m_bridge.OwnPendings() : 0;
      o.buy_open = 0;
      o.sell_open = 0;
      o.floating_profit = 0.0;
      o.floating_loss = 0.0;

      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         const ulong ticket = PositionGetTicket(i);
         if(ticket == 0)
            continue;
         if(PositionGetInteger(POSITION_MAGIC) != o.magic)
            continue;
         if(StringLen(o.symbol) > 0 && PositionGetString(POSITION_SYMBOL) != o.symbol)
            continue;
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            o.buy_open++;
         else
            o.sell_open++;
         const double pnl = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
         if(pnl >= 0.0)
            o.floating_profit += pnl;
         else
            o.floating_loss += -pnl;
        }

      if(m_recovery != NULL)
        {
         const SGmRecoverySnapshot rs = m_recovery.LastSnapshot();
         o.recovery_trades = rs.own_positions;
        }
     }

   void CollectOrdersHistory(SGmAnalyticsSnapshot &o, const datetime from, const datetime to)
     {
      o.cancelled_orders = 0;
      o.expired_orders = 0;
      if(!HistorySelect(from, to + 60))
         return;
      const int n = HistoryOrdersTotal();
      for(int i = 0; i < n; i++)
        {
         const ulong ticket = HistoryOrderGetTicket(i);
         if(ticket == 0)
            continue;
         if(HistoryOrderGetInteger(ticket, ORDER_MAGIC) != o.magic)
            continue;
         if(StringLen(o.symbol) > 0 &&
            HistoryOrderGetString(ticket, ORDER_SYMBOL) != o.symbol)
            continue;
         const long st = HistoryOrderGetInteger(ticket, ORDER_STATE);
         if(st == ORDER_STATE_CANCELED)
            o.cancelled_orders++;
         else if(st == ORDER_STATE_EXPIRED)
            o.expired_orders++;
        }
     }

   void CollectDeals(SGmAnalyticsSnapshot &o)
     {
      const datetime now = TimeCurrent();
      const datetime day0 = DayStart(now);
      const datetime week0 = WeekStart(now);
      const datetime month0 = MonthStart(now);
      const datetime from = now - (datetime)GM_ANALYTICS_HISTORY_DAYS * 86400;

      CollectOrdersHistory(o, from, now);

      if(!HistorySelect(from, now + 60))
         return;

      int today_w = 0, today_l = 0, today_n = 0;
      int week_w = 0, week_l = 0, week_n = 0;
      int month_w = 0, month_l = 0, month_n = 0;
      int buy_w = 0, buy_n = 0, sell_w = 0, sell_n = 0;
      int sess_w = 0, sess_l = 0, sess_n = 0;
      double sum_win = 0.0, sum_loss = 0.0, gross_p = 0.0, gross_l = 0.0;
      double peak = 0.0, curve = 0.0, max_dd_money = 0.0;
      double sum_dur = 0.0, sum_win_dur = 0.0, sum_loss_dur = 0.0, sum_pips = 0.0;
      int dur_n = 0, win_dur_n = 0, loss_dur_n = 0, pip_n = 0;
      double fastest = 0.0, longest = 0.0;
      o.largest_win = 0.0;
      o.largest_loss = 0.0;

      // Position open time map for duration (deal IN -> OUT)
      // Simplified: use DEAL_TIME on OUT vs position - HistoryDealGetInteger DEAL_POSITION_ID
      const ulong sess_start = o.current_session_id;

      const int deals = HistoryDealsTotal();
      // First pass: map position open times (deal IN)
      ulong  open_ids[];
      datetime open_times[];
      double open_prices[];
      int open_n = 0;
      for(int i = 0; i < deals; i++)
        {
         const ulong deal = HistoryDealGetTicket(i);
         if(deal == 0)
            continue;
         if(HistoryDealGetInteger(deal, DEAL_MAGIC) != o.magic)
            continue;
         if(HistoryDealGetInteger(deal, DEAL_ENTRY) != DEAL_ENTRY_IN)
            continue;
         if(StringLen(o.symbol) > 0 &&
            HistoryDealGetString(deal, DEAL_SYMBOL) != o.symbol)
            continue;
         ArrayResize(open_ids, open_n + 1);
         ArrayResize(open_times, open_n + 1);
         ArrayResize(open_prices, open_n + 1);
         open_ids[open_n] = (ulong)HistoryDealGetInteger(deal, DEAL_POSITION_ID);
         open_times[open_n] = (datetime)HistoryDealGetInteger(deal, DEAL_TIME);
         open_prices[open_n] = HistoryDealGetDouble(deal, DEAL_PRICE);
         open_n++;
        }

      for(int i = 0; i < deals; i++)
        {
         const ulong deal = HistoryDealGetTicket(i);
         if(deal == 0)
            continue;
         if(HistoryDealGetInteger(deal, DEAL_MAGIC) != o.magic)
            continue;
         if(StringLen(o.symbol) > 0 &&
            HistoryDealGetString(deal, DEAL_SYMBOL) != o.symbol)
            continue;

         const long entry = HistoryDealGetInteger(deal, DEAL_ENTRY);
         if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY)
            continue;

         const datetime t = (datetime)HistoryDealGetInteger(deal, DEAL_TIME);
         const double profit = HistoryDealGetDouble(deal, DEAL_PROFIT)
                               + HistoryDealGetDouble(deal, DEAL_SWAP)
                               + HistoryDealGetDouble(deal, DEAL_COMMISSION);
         const long dtype = HistoryDealGetInteger(deal, DEAL_TYPE);
         const bool is_buy_close = (dtype == DEAL_TYPE_SELL);
         const bool is_sell_close = (dtype == DEAL_TYPE_BUY);

         o.total_trades++;
         if(is_buy_close)
           {
            o.buy_trades++;
            buy_n++;
           }
         else if(is_sell_close)
           {
            o.sell_trades++;
            sell_n++;
           }

         double dur = 0.0;
         double open_price = 0.0;
         const ulong pos_id = (ulong)HistoryDealGetInteger(deal, DEAL_POSITION_ID);
         for(int k = 0; k < open_n; k++)
           {
            if(open_ids[k] == pos_id)
              {
               if(open_times[k] > 0 && t >= open_times[k])
                  dur = (double)(t - open_times[k]);
               open_price = open_prices[k];
               break;
              }
           }
         if(dur > 0.0)
           {
            sum_dur += dur;
            dur_n++;
            if(fastest <= 0.0 || dur < fastest)
               fastest = dur;
            if(dur > longest)
               longest = dur;
           }

         const double price = HistoryDealGetDouble(deal, DEAL_PRICE);
         if(open_price > 0.0 && price > 0.0)
           {
            const double pip = CGmPipTools::PipSize(o.symbol);
            if(pip > 0.0)
              {
               double pips = 0.0;
               if(dtype == DEAL_TYPE_SELL)
                  pips = (price - open_price) / pip;
               else
                  pips = (open_price - price) / pip;
               sum_pips += pips;
               pip_n++;
              }
           }

         const bool win = (profit >= 0.0);
         if(win)
           {
            o.winning_trades++;
            sum_win += profit;
            gross_p += profit;
            if(profit > o.largest_win)
               o.largest_win = profit;
            if(dur > 0.0)
              {
               sum_win_dur += dur;
               win_dur_n++;
              }
            if(is_buy_close)
               buy_w++;
            if(is_sell_close)
               sell_w++;
           }
         else
           {
            o.losing_trades++;
            sum_loss += -profit;
            gross_l += -profit;
            if(-profit > o.largest_loss)
               o.largest_loss = -profit;
            if(dur > 0.0)
              {
               sum_loss_dur += dur;
               loss_dur_n++;
              }
           }

         if(t >= day0)
           {
            today_n++;
            if(win)
              {
               today_w++;
               o.today_profit += profit;
              }
            else
              {
               today_l++;
               o.today_loss += -profit;
              }
           }
         if(t >= week0)
           {
            week_n++;
            if(win)
              {
               week_w++;
               o.week_profit += profit;
              }
            else
              {
               week_l++;
               o.week_loss += -profit;
              }
           }
         if(t >= month0)
           {
            month_n++;
            if(win)
              {
               month_w++;
               o.month_profit += profit;
              }
            else
              {
               month_l++;
               o.month_loss += -profit;
              }
           }

         if(sess_start > 0 && (ulong)t >= sess_start &&
            (ulong)t < sess_start + (ulong)PeriodSeconds(PERIOD_H4))
           {
            sess_n++;
            if(win)
              {
               sess_w++;
               o.session_profit += profit;
              }
            else
              {
               sess_l++;
               o.session_loss += -profit;
              }
           }

         curve += profit;
         if(curve > peak)
            peak = curve;
         const double dd = peak - curve;
         if(dd > max_dd_money)
            max_dd_money = dd;
        }

      o.total_net_profit = gross_p - gross_l;
      if(o.winning_trades > 0)
         o.avg_profit_per_trade = sum_win / (double)o.winning_trades;
      if(o.losing_trades > 0)
         o.avg_loss_per_trade = sum_loss / (double)o.losing_trades;
      if(o.total_trades > 0)
         o.overall_win_rate = 100.0 * (double)o.winning_trades / (double)o.total_trades;
      if(today_n > 0)
        {
         o.today_win_rate = 100.0 * (double)today_w / (double)today_n;
         o.today_loss_rate = 100.0 * (double)today_l / (double)today_n;
        }
      if(week_n > 0)
         o.week_win_rate = 100.0 * (double)week_w / (double)week_n;
      if(month_n > 0)
         o.month_win_rate = 100.0 * (double)month_w / (double)month_n;
      if(buy_n > 0)
         o.buy_win_rate = 100.0 * (double)buy_w / (double)buy_n;
      if(sell_n > 0)
         o.sell_win_rate = 100.0 * (double)sell_w / (double)sell_n;
      if(gross_l > 0.0)
         o.profit_factor = gross_p / gross_l;
      else if(gross_p > 0.0)
         o.profit_factor = 999.0;
      if(max_dd_money > 0.0)
         o.recovery_factor = curve / max_dd_money;
      if(o.avg_loss_per_trade > 0.0)
         o.risk_reward_ratio = o.avg_profit_per_trade / o.avg_loss_per_trade;

      if(dur_n > 0)
        {
         o.avg_trade_duration_sec = sum_dur / (double)dur_n;
         o.avg_holding_sec = o.avg_trade_duration_sec;
        }
      o.fastest_trade_sec = fastest;
      o.longest_trade_sec = longest;
      if(win_dur_n > 0)
         o.avg_win_duration_sec = sum_win_dur / (double)win_dur_n;
      if(loss_dur_n > 0)
         o.avg_loss_duration_sec = sum_loss_dur / (double)loss_dur_n;
      if(pip_n > 0)
         o.avg_pips = sum_pips / (double)pip_n;

      if(sess_n > 0)
         o.session_win_rate = 100.0 * (double)sess_w / (double)sess_n;

      // Approximate completed sessions from H4 span of history
      if(from > 0)
         o.completed_sessions = (int)((now - from) / PeriodSeconds(PERIOD_H4));
      o.winning_sessions = (o.session_win_rate >= 50.0 && sess_n > 0) ? 1 : 0;
      o.losing_sessions = (o.session_win_rate < 50.0 && sess_n > 0) ? 1 : 0;
     }

   void CollectAttemptRates(SGmAnalyticsSnapshot &o)
     {
      // Registry-based approximation for open/managed trades by attempt
      int a1_n = 0, a1_w = 0, a2_n = 0, a2_w = 0;
      if(m_bridge == NULL)
         return;
      const int n = m_bridge.RegistryCount();
      for(int i = 0; i < n; i++)
        {
         SGmTradeRecord rec;
         if(!m_bridge.GetRegistryAt(i, rec))
            continue;
         if(rec.trade_attempts <= 1)
           {
            a1_n++;
            if(rec.current_profit > 0.0 || rec.status == GM_TRADE_STATUS_CLOSED)
              {
               // closed profit not always on record — use stage
               if(rec.current_profit > rec.current_loss)
                  a1_w++;
              }
           }
         else
           {
            a2_n++;
            if(rec.current_profit > rec.current_loss)
               a2_w++;
           }
        }
      if(a1_n > 0)
         o.first_attempt_win_rate = 100.0 * (double)a1_w / (double)a1_n;
      if(a2_n > 0)
         o.second_attempt_win_rate = 100.0 * (double)a2_w / (double)a2_n;
     }

   void CollectRisk(SGmAnalyticsSnapshot &o)
     {
      o.balance = AccountInfoDouble(ACCOUNT_BALANCE);
      o.equity = AccountInfoDouble(ACCOUNT_EQUITY);
      SGmAccountSnapshot acc;
      if(m_bridge != NULL && m_bridge.ReadAccount(acc) && acc.valid)
        {
         o.balance = acc.balance;
         o.equity = acc.equity;
        }

      o.current_risk_pct = (o.balance > 0.0)
                           ? MathAbs(o.equity - o.balance) / o.balance * 100.0
                           : 0.0;
      o.average_risk_pct = GM_RISK_EQUITY_FRACTION * 100.0;
      m_risk_sum += o.current_risk_pct;
      m_risk_samples++;
      if(m_risk_samples > 0)
         o.average_risk_pct = m_risk_sum / (double)m_risk_samples;
      if(o.current_risk_pct > m_peak_risk_pct)
         m_peak_risk_pct = o.current_risk_pct;
      o.maximum_risk_pct = MathMax(m_peak_risk_pct, GM_RISK_EQUITY_FRACTION * 100.0);

      SGmDrawdownState dd;
      if(m_bridge != NULL && m_bridge.ReadDrawdown(dd))
        {
         o.current_dd_pct = dd.current_dd_pct;
         o.maximum_dd_pct = dd.max_dd_pct;
         o.daily_dd_pct = dd.daily_dd_pct;
         o.weekly_dd_pct = dd.weekly_dd_pct;
         o.monthly_dd_pct = dd.monthly_dd_pct;
        }
     }

public:
                     CGmAnalyticsEngine(void)
                       : m_bridge(NULL), m_recovery(NULL),
                         m_last_hist(0), m_atr_handle(INVALID_HANDLE),
                         m_atr_symbol(""), m_peak_risk_pct(0.0),
                         m_risk_sum(0.0), m_risk_samples(0)
     {
      m_snap.Reset();
      m_module_name = "AnalyticsEngine";
     }

                    ~CGmAnalyticsEngine(void)
     {
      if(m_atr_handle != INVALID_HANDLE)
        {
         IndicatorRelease(m_atr_handle);
         m_atr_handle = INVALID_HANDLE;
        }
     }

   bool InitFull(CGmLogger *logger,
                 CGmPhase2Bridge *bridge,
                 CGmRecoveryBase *recovery)
     {
      CGmAnalyticsBase::Init(logger);
      m_bridge = bridge;
      m_recovery = recovery;
      m_export.Init(logger);
      m_snap.Reset();
      m_status = GM_MODULE_READY;
      if(m_logger != NULL)
         m_logger.Success("Analytics Started | Enterprise Analytics Engine | READ-ONLY",
                          m_module_name);
      Collect();
      return true;
     }

   virtual bool Init(CGmLogger *logger)
     {
      return InitFull(logger, NULL, NULL);
     }

   virtual void Shutdown(void)
     {
      if(m_atr_handle != INVALID_HANDLE)
        {
         IndicatorRelease(m_atr_handle);
         m_atr_handle = INVALID_HANDLE;
        }
      CGmAnalyticsBase::Shutdown();
     }

   SGmAnalyticsSnapshot Snapshot(void) const { return m_snap; }
   CGmAnalyticsExport *ExportApi(void) { return GetPointer(m_export); }

   /// @brief IGmAnalyticsEngine-compatible JSON snapshot.
   string SnapshotJson(void) const
     {
      return m_export.BuildJson(m_snap);
     }

   virtual bool Collect(void)
     {
      const ulong t0 = GetMicrosecondCount();
      SGmAnalyticsSnapshot o;
      o.Reset();
      if(m_bridge == NULL)
        {
         m_snap = o;
         return false;
        }

      o.magic = m_bridge.Magic();
      o.symbol = m_bridge.Symbol();
      o.current_session_id = m_bridge.SessionId();
      if(o.current_session_id == 0)
         o.current_session_id = (ulong)m_bridge.H4Cycle();

      const datetime h4 = m_bridge.H4Cycle();
      const datetime next = (h4 > 0) ? h4 + PeriodSeconds(PERIOD_H4) : 0;
      o.session_countdown_sec = (next > TimeCurrent()) ? (int)(next - TimeCurrent()) : 0;

      CollectLive(o);
      CollectRisk(o);

      // Throttle heavy history
      if(m_last_hist == 0 || TimeCurrent() - m_last_hist >= GM_ANALYTICS_HISTORY_THROTTLE_S)
        {
         CollectDeals(o);
         CollectAttemptRates(o);
         m_last_hist = TimeCurrent();
         // keep previous history fields if needed — CollectDeals fills them
        }
      else
        {
         // reuse prior history metrics
         o.total_trades = m_snap.total_trades;
         o.winning_trades = m_snap.winning_trades;
         o.losing_trades = m_snap.losing_trades;
         o.buy_trades = m_snap.buy_trades;
         o.sell_trades = m_snap.sell_trades;
         o.cancelled_orders = m_snap.cancelled_orders;
         o.expired_orders = m_snap.expired_orders;
         o.today_profit = m_snap.today_profit;
         o.today_loss = m_snap.today_loss;
         o.week_profit = m_snap.week_profit;
         o.week_loss = m_snap.week_loss;
         o.month_profit = m_snap.month_profit;
         o.month_loss = m_snap.month_loss;
         o.total_net_profit = m_snap.total_net_profit;
         o.avg_profit_per_trade = m_snap.avg_profit_per_trade;
         o.avg_loss_per_trade = m_snap.avg_loss_per_trade;
         o.largest_win = m_snap.largest_win;
         o.largest_loss = m_snap.largest_loss;
         o.overall_win_rate = m_snap.overall_win_rate;
         o.today_win_rate = m_snap.today_win_rate;
         o.today_loss_rate = m_snap.today_loss_rate;
         o.week_win_rate = m_snap.week_win_rate;
         o.month_win_rate = m_snap.month_win_rate;
         o.buy_win_rate = m_snap.buy_win_rate;
         o.sell_win_rate = m_snap.sell_win_rate;
         o.first_attempt_win_rate = m_snap.first_attempt_win_rate;
         o.second_attempt_win_rate = m_snap.second_attempt_win_rate;
         o.profit_factor = m_snap.profit_factor;
         o.recovery_factor = m_snap.recovery_factor;
         o.risk_reward_ratio = m_snap.risk_reward_ratio;
         o.avg_trade_duration_sec = m_snap.avg_trade_duration_sec;
         o.fastest_trade_sec = m_snap.fastest_trade_sec;
         o.longest_trade_sec = m_snap.longest_trade_sec;
         o.avg_pips = m_snap.avg_pips;
         o.avg_holding_sec = m_snap.avg_holding_sec;
         o.avg_win_duration_sec = m_snap.avg_win_duration_sec;
         o.avg_loss_duration_sec = m_snap.avg_loss_duration_sec;
         o.completed_sessions = m_snap.completed_sessions;
         o.winning_sessions = m_snap.winning_sessions;
         o.losing_sessions = m_snap.losing_sessions;
         o.session_profit = m_snap.session_profit;
         o.session_loss = m_snap.session_loss;
         o.session_win_rate = m_snap.session_win_rate;
        }

      o.atr14 = ReadAtr(o.symbol);
      const double ask = SymbolInfoDouble(o.symbol, SYMBOL_ASK);
      const double bid = SymbolInfoDouble(o.symbol, SYMBOL_BID);
      const double point = SymbolInfoDouble(o.symbol, SYMBOL_POINT);
      o.spread_points = (point > 0.0) ? (ask - bid) / point : 0.0;

      o.last_collect_us = GetMicrosecondCount() - t0;
      m_perf.Record(o.last_collect_us);
      o.avg_tick_us = m_perf.AvgUs();
      o.last_tick_us = m_perf.LastUs();
      o.memory_kb = m_perf.MemoryKb();
      o.cpu_load_pct = m_perf.CpuLoadPct();
      o.refresh_us = o.last_collect_us;
      o.module_health = m_perf.Health(o.last_collect_us);
      o.stamped_at = TimeCurrent();
      o.fingerprint = o.ComputeFingerprint();
      o.valid = true;
      m_snap = o;

      if(m_logger != NULL)
         m_logger.Debug(StringFormat("Analytics Updated | %I64u us | health=%s | trades=%d",
                                     o.last_collect_us, o.module_health, o.total_trades),
                        m_module_name);
      return true;
     }
  };

#endif // GM_CANALYTICS_ENGINE_MQH
//+------------------------------------------------------------------+
