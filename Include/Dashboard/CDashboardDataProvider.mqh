//+------------------------------------------------------------------+
//|                                   CDashboardDataProvider.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CDASHBOARD_DATA_PROVIDER_MQH
#define GM_CDASHBOARD_DATA_PROVIDER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmDashboardSnapshot.mqh"
#include "../Phase2/CPhase2Bridge.mqh"
#include "../Recovery/CRecoveryBase.mqh"
#include "../Analytics/CAnalyticsEngine.mqh"
#include "../Protection/SGmDrawdownState.mqh"
#include "../Risk/RiskConstants.mqh"
#include "../Protection/ProtectionConstants.mqh"
#include "../Trading/SGmTradeRecord.mqh"
#include "../TradeManagement/CPipTools.mqh"
#include "CPerformanceGauges.mqh"
#include "../Journal/CJournalEngine.mqh"
#include "../AI/CAIDashboardEngine.mqh"
#include "../MultiInstance/CMultiInstanceEngine.mqh"

/// @file CDashboardDataProvider.mqh
/// @brief Sprint 3 — merges Analytics Engine into dashboard snapshot (READ-ONLY).

class CGmDashboardDataProvider
  {
private:
   CGmPhase2Bridge     *m_bridge;
   CGmRecoveryBase     *m_recovery;
   CGmAnalyticsEngine  *m_analytics;
   CGmJournalEngine    *m_journal;
   CGmAIDashboardEngine *m_ai;
   CGmMultiInstanceEngine *m_multi;
   SGmDashboardSnapshot m_last;
   int                  m_atr_handle;
   string               m_atr_symbol;

   string TfName(const ENUM_TIMEFRAMES tf) const
     {
      return StringSubstr(EnumToString(tf), 7);
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

   void ApplyAnalytics(SGmDashboardSnapshot &out)
     {
      if(m_analytics == NULL)
         return;
      m_analytics.Collect();
      const SGmAnalyticsSnapshot a = m_analytics.Snapshot();
      if(!a.valid)
         return;

      out.running_trades = a.running_trades;
      out.pending_orders = a.pending_orders;
      out.buy_trades = a.buy_open;
      out.sell_trades = a.sell_open;
      out.floating_profit = a.floating_profit;
      out.floating_loss = a.floating_loss;
      out.today_profit = a.today_profit;
      out.today_loss = a.today_loss;
      out.today_net = a.today_profit - a.today_loss;
      out.today_win_rate = a.today_win_rate;
      out.today_loss_rate = a.today_loss_rate;
      out.total_trades = a.total_trades;
      out.total_winners = a.winning_trades;
      out.total_losers = a.losing_trades;
      out.overall_win_rate = a.overall_win_rate;
      out.profit_factor = a.profit_factor;
      out.recovery_factor = a.recovery_factor;
      out.avg_win = a.avg_profit_per_trade;
      out.avg_loss = a.avg_loss_per_trade;
      out.risk_reward = a.risk_reward_ratio;
      out.week_win_rate = a.week_win_rate;
      out.month_win_rate = a.month_win_rate;
      out.current_risk_pct = a.current_risk_pct;
      out.current_dd_pct = a.current_dd_pct;
      out.max_dd_pct = a.maximum_dd_pct;
      out.balance = a.balance;
      out.equity = a.equity;
      out.atr14 = a.atr14;
      out.spread_points = a.spread_points;
      out.h4_countdown_sec = a.session_countdown_sec;
      out.cancelled_orders = a.cancelled_orders;
      out.expired_orders = a.expired_orders;
      out.trade_counter = a.total_trades + a.running_trades;
      out.analytics_refresh_us = (double)a.refresh_us;
      out.analytics_health = a.module_health;
      out.terminal_memory_kb = a.memory_kb;
      out.week_net = a.week_profit - a.week_loss;
      out.month_net = a.month_profit - a.month_loss;
      out.total_net = a.total_net_profit;
      out.avg_trade_duration_sec = a.avg_trade_duration_sec;
      out.trade_success_rate = a.overall_win_rate;
     }

   void CollectRegistryMonitor(SGmDashboardSnapshot &out)
     {
      out.be_status = "IDLE";
      out.trail_status = "IDLE";
      out.trade_stage = "—";
      out.active_hedge = 0;
      out.hedge_status = "N/A";
      out.winning_open = 0;
      out.losing_open = 0;

      if(m_bridge == NULL)
         return;

      bool any_be = false;
      bool any_trail = false;
      string stage = "—";
      for(int i = 0; i < out.registry_count; i++)
        {
         SGmTradeRecord rec;
         if(!m_bridge.GetRegistryAt(i, rec))
            continue;
         if(rec.status != GM_TRADE_STATUS_ACTIVE)
            continue;
         if(rec.be_done)
            any_be = true;
         if(rec.trailing_active)
            any_trail = true;
         stage = EnumToString(rec.stage);
         StringReplace(stage, "GM_TRADE_STAGE_", "");
         if(rec.current_profit > rec.current_loss)
            out.winning_open++;
         else if(rec.current_loss > 0.0)
            out.losing_open++;
        }
      out.be_status = any_be ? "ACTIVE" : "IDLE";
      out.trail_status = any_trail ? "ACTIVE" : "IDLE";
      out.trade_stage = stage;
     }

public:
                     CGmDashboardDataProvider(void)
                       : m_bridge(NULL), m_recovery(NULL), m_analytics(NULL),
                         m_journal(NULL), m_ai(NULL), m_multi(NULL),
                         m_atr_handle(INVALID_HANDLE), m_atr_symbol("")
     {
      m_last.Reset();
     }

                    ~CGmDashboardDataProvider(void)
     {
      if(m_atr_handle != INVALID_HANDLE)
        {
         IndicatorRelease(m_atr_handle);
         m_atr_handle = INVALID_HANDLE;
        }
     }

   void Init(CGmPhase2Bridge *bridge,
             CGmRecoveryBase *recovery,
             CGmAnalyticsEngine *analytics = NULL,
             CGmJournalEngine *journal = NULL,
             CGmAIDashboardEngine *ai = NULL,
             CGmMultiInstanceEngine *multi = NULL)
     {
      m_bridge = bridge;
      m_recovery = recovery;
      m_analytics = analytics;
      m_journal = journal;
      m_ai = ai;
      m_multi = multi;
      m_last.Reset();
     }

   SGmDashboardSnapshot Last(void) const { return m_last; }

   bool Collect(SGmDashboardSnapshot &out)
     {
      const ulong t0 = GetMicrosecondCount();
      out.Reset();
      if(m_bridge == NULL)
         return false;

      out.magic = m_bridge.Magic();
      out.symbol = m_bridge.Symbol();
      out.registry_count = m_bridge.RegistryCount();
      out.session_id = m_bridge.SessionId();
      out.h4_cycle = m_bridge.H4Cycle();
      out.protection_ready = m_bridge.ProtectionReady();
      out.core_frozen = m_bridge.CoreFrozen();
      out.timeframe = TfName(PERIOD_H4);

      out.account_login = AccountInfoInteger(ACCOUNT_LOGIN);
      out.broker_name = AccountInfoString(ACCOUNT_COMPANY);
      out.server_name = AccountInfoString(ACCOUNT_SERVER);
      out.currency = AccountInfoString(ACCOUNT_CURRENCY);
      out.leverage = (int)AccountInfoInteger(ACCOUNT_LEVERAGE);
      const long atype = AccountInfoInteger(ACCOUNT_TRADE_MODE);
      if(atype == ACCOUNT_TRADE_MODE_DEMO)
         out.account_type = "DEMO";
      else if(atype == ACCOUNT_TRADE_MODE_CONTEST)
         out.account_type = "CONTEST";
      else
         out.account_type = "REAL";

      SGmAccountSnapshot acc;
      if(m_bridge.ReadAccount(acc) && acc.valid)
        {
         out.balance = acc.balance;
         out.equity = acc.equity;
         out.free_margin = acc.free_margin;
         out.margin = acc.margin;
         out.margin_level = acc.margin_level;
        }
      else
        {
         out.balance = AccountInfoDouble(ACCOUNT_BALANCE);
         out.equity = AccountInfoDouble(ACCOUNT_EQUITY);
         out.free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
         out.margin = AccountInfoDouble(ACCOUNT_MARGIN);
         out.margin_level = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
        }

      out.auto_risk_pct = GM_RISK_EQUITY_FRACTION * 100.0;
      out.max_daily_risk_pct = GM_PROT_MAX_DAILY_LOSS_WARN_DEFAULT;

      SGmDrawdownState dd;
      if(m_bridge.ReadDrawdown(dd))
        {
         out.current_dd_pct = dd.current_dd_pct;
         out.max_dd_pct = dd.max_dd_pct;
         out.risk_status = (dd.warn_dd || dd.warn_daily) ? "WARNING" : "HEALTHY";
        }
      else
         out.risk_status = out.protection_ready ? "HEALTHY" : "WAITING";

      ApplyAnalytics(out);

      if(out.atr14 <= 0.0)
         out.atr14 = ReadAtr(out.symbol);
      if(out.spread_points <= 0.0)
        {
         const double ask = SymbolInfoDouble(out.symbol, SYMBOL_ASK);
         const double bid = SymbolInfoDouble(out.symbol, SYMBOL_BID);
         const double point = SymbolInfoDouble(out.symbol, SYMBOL_POINT);
         out.spread_points = (point > 0.0) ? (ask - bid) / point : 0.0;
        }

      CollectRegistryMonitor(out);
      out.trade_engine_status = "RUNNING";
      out.ea_status = "RUNNING";
      out.ea_module_status = "RUNNING";

      out.next_h4 = out.h4_cycle > 0 ? out.h4_cycle + PeriodSeconds(PERIOD_H4) : 0;
      if(out.h4_countdown_sec <= 0 && out.next_h4 > TimeCurrent())
         out.h4_countdown_sec = (int)(out.next_h4 - TimeCurrent());

      out.market_status = (SymbolInfoInteger(out.symbol, SYMBOL_TRADE_MODE) != SYMBOL_TRADE_MODE_DISABLED)
                          ? "OPEN" : "CLOSED";
      out.market_module_status = out.market_status;
      out.broker_connected = (TerminalInfoInteger(TERMINAL_CONNECTED) != 0);
      out.internet_ok = out.broker_connected;
      out.internet_module_status = out.internet_ok ? "CONNECTED" : "DISCONNECTED";
      out.broker_module_status = out.broker_connected ? "CONNECTED" : "DISCONNECTED";
      out.trade_allowed = (TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) != 0)
                          && (MQLInfoInteger(MQL_TRADE_ALLOWED) != 0);
      out.autotrading = (TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) != 0);
      out.trading_perm_status = out.trade_allowed ? "ALLOWED" : "BLOCKED";
      out.logging_ok = true;
      out.logging_module_status = "OK";
      out.dashboard_ok = true;
      out.dashboard_module_status = "OK";
      out.analytics_module_status = out.analytics_health;
      if(m_recovery != NULL)
        {
         out.recovery_ok = m_recovery.LastSnapshot().state_restored;
         out.recovery_module_status = out.recovery_ok ? "READY" : "WAITING";
        }
      else
         out.recovery_module_status = "N/A";

      out.clock_local = TimeToString(TimeLocal(), TIME_DATE | TIME_SECONDS);
      out.clock_server = TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);

      out.gauge_risk = CGmPerformanceGauges::RiskGauge(out.current_risk_pct);
      out.gauge_dd = CGmPerformanceGauges::DrawdownGauge(out.current_dd_pct);
      out.gauge_wr = CGmPerformanceGauges::WinRateGauge(out.overall_win_rate);
      out.gauge_pf = CGmPerformanceGauges::ProfitFactorGauge(out.profit_factor);
      out.gauge_rf = CGmPerformanceGauges::RecoveryFactorGauge(out.recovery_factor);
      out.gauge_speed = CGmPerformanceGauges::ExecutionSpeedGauge((ulong)out.analytics_refresh_us);
      out.gauge_conn = CGmPerformanceGauges::ConnectionGauge(out.broker_connected, out.trade_allowed);
      out.gauge_health = CGmPerformanceGauges::SystemHealthGauge(out.analytics_health);

      if(m_journal != NULL)
        {
         m_journal.Process();
         const SGmJournalReportStats st = m_journal.Stats();
         out.rpt_today_summary = st.today_summary;
         out.rpt_last_win = st.last_winning_trade;
         out.rpt_last_loss = st.last_losing_trade;
         out.rpt_largest_win = st.largest_win;
         out.rpt_largest_loss = st.largest_loss;
         out.rpt_win_streak = st.longest_win_streak;
         out.rpt_loss_streak = st.longest_loss_streak;
         out.rpt_session_result = st.current_session_result;
         out.rpt_avg_trade_time = st.average_trade_time;
         out.rpt_alert_count = st.alert_count;
         out.rpt_last_alert = st.last_alert;
        }

      if(m_ai != NULL)
        {
         m_ai.Process();
         const SGmAISnapshot ai = m_ai.Snapshot();
         if(ai.valid)
           {
            out.ai_status = ai.ai_status;
            out.ai_version = ai.ai_version;
            out.ai_engine = ai.ai_engine;
            out.ai_learning_status = ai.learning_status;
            out.ai_decision_status = ai.decision_status;
            out.ai_prediction_status = ai.prediction_status;
            out.ai_confidence_status = ai.confidence_status;
            out.ai_current_mode = ai.current_mode;
            out.ai_future_score = ai.future_ai_score;
            out.ai_market_analyzer = ai.w_market_analyzer;
            out.ai_trend_analyzer = ai.w_trend_detector;
            out.ai_volatility_analyzer = ai.w_volatility_scanner;
            out.ai_news_analyzer = ai.w_news_analyzer;
            out.ai_recovery = ai.w_recovery_ai;
            if(ai.atr14 > 0.0)
               out.atr14 = ai.atr14;
            out.mkt_candle_cur = ai.candle_size_cur;
            out.mkt_candle_prev = ai.candle_size_prev;
            out.mkt_daily_range = ai.daily_range;
            out.mkt_weekly_range = ai.weekly_range;
            out.mkt_volatility = ai.market_volatility;
            out.mkt_activity = ai.market_activity;
           }
        }

      if(m_multi != NULL)
        {
         m_multi.Process();
         const SGmGlobalMonitorSnapshot g = m_multi.Snapshot();
         if(g.valid)
           {
            out.mi_instance_id = g.local_instance_id;
            out.mi_chart_id = g.local_chart_id;
            out.mi_running_instances = g.total_instances;
            out.mi_symbol = g.local_symbol;
            out.mi_timeframe = g.local_timeframe;
            out.mi_instance_health = g.local_health;
            out.mi_global_health = g.global_health;
            out.mi_global_floating_profit = g.overall_floating_profit;
            out.mi_global_floating_loss = g.overall_floating_loss;
            out.mi_global_open_trades = g.total_open_trades;
            out.mi_active_symbols = g.active_symbols;
           }
        }

      out.stamped_at = TimeCurrent();
      out.last_refresh_us = GetMicrosecondCount() - t0;
      out.fingerprint = out.ComputeFingerprint();
      out.valid = true;
      m_last = out;
      return true;
     }
  };

#endif // GM_CDASHBOARD_DATA_PROVIDER_MQH
//+------------------------------------------------------------------+
