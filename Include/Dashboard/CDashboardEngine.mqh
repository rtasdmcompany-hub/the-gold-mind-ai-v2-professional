//+------------------------------------------------------------------+
//|                                        CDashboardEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CDASHBOARD_ENGINE_MQH
#define GM_CDASHBOARD_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "IDashboardApi.mqh"
#include "SGmDashboardSettings.mqh"
#include "CDashboardDataProvider.mqh"
#include "CDashboardEventManager.mqh"
#include "CDashboardRefreshEngine.mqh"
#include "CDashboardRenderer.mqh"
#include "CDashboardEventHandler.mqh"
#include "CNotificationEngine.mqh"
#include "CPerformanceGauges.mqh"
#include "DashboardConstants.mqh"
#include "QA/Module.DashboardQA.mqh"
#include "../Logging/CLogger.mqh"
#include "../Phase2/CPhase2Bridge.mqh"
#include "../Recovery/CRecoveryBase.mqh"
#include "../Analytics/CAnalyticsEngine.mqh"
#include "../Journal/CJournalEngine.mqh"
#include "../AI/CAIDashboardEngine.mqh"
#include "../MultiInstance/CMultiInstanceEngine.mqh"
#include "../UI/CPersonalizationEngine.mqh"
#include "../Core/CFileManager.mqh"
#include "../Protection/ProtectionConstants.mqh"

/// @file CDashboardEngine.mqh
/// @brief Phase 2 Sprint 9 — Enterprise Dashboard + QA/RC-1 (READ-ONLY).
/// @warning NEVER opens/closes/modifies trades or orders.

class CGmDashboardEngine
  {
private:
   CGmLogger                 *m_logger;
   CGmPhase2Bridge           *m_bridge;
   CGmAnalyticsEngine        *m_analytics;
   CGmFileManager            *m_files;
   SGmDashboardSettings       m_settings;
   CGmDashboardDataProvider   m_data;
   CGmDashboardEventManager   m_events;
   CGmDashboardRefreshEngine  m_refresh;
   CGmDashboardRenderer       m_renderer;
   CGmDashboardEventHandler   m_handler;
   CGmNotificationEngine      m_notify;
   CGmJournalEngine          *m_journal;
   CGmAIDashboardEngine      *m_ai;
   CGmMultiInstanceEngine    *m_multi;
   CGmPersonalizationEngine   m_ui;
   CGmDashboardQAEngine       m_qa;
   SGmDashboardSnapshot       m_snap;
   SGmDashboardSnapshot       m_prev;
   bool                       m_ready;
   bool                       m_have_prev;
   bool                       m_recovery_announced;

   void FillTimelineLines(SGmDashboardSnapshot &snap)
     {
      snap.notify_banner = m_notify.Banner();
      CGmActivityTimeline *tl = m_notify.Timeline();
      snap.timeline_line0 = "";
      snap.timeline_line1 = "";
      snap.timeline_line2 = "";
      snap.timeline_line3 = "";
      snap.timeline_line4 = "";
      snap.timeline_line5 = "";
      snap.timeline_line6 = "";
      snap.timeline_line7 = "";
      if(tl == NULL)
         return;
      SGmTimelineEntry e;
      if(tl.GetRecent(0, e)) snap.timeline_line0 = tl.FormatLine(e);
      if(tl.GetRecent(1, e)) snap.timeline_line1 = tl.FormatLine(e);
      if(tl.GetRecent(2, e)) snap.timeline_line2 = tl.FormatLine(e);
      if(tl.GetRecent(3, e)) snap.timeline_line3 = tl.FormatLine(e);
      if(tl.GetRecent(4, e)) snap.timeline_line4 = tl.FormatLine(e);
      if(tl.GetRecent(5, e)) snap.timeline_line5 = tl.FormatLine(e);
      if(tl.GetRecent(6, e)) snap.timeline_line6 = tl.FormatLine(e);
      if(tl.GetRecent(7, e)) snap.timeline_line7 = tl.FormatLine(e);
     }

   void PushEnterpriseAlert(const ENUM_GM_ALERT_CATEGORY cat,
                            const string description,
                            const ulong session_id,
                            const int priority)
     {
      if(m_journal == NULL)
         return;
      m_journal.RaiseAlert(cat, "Dashboard", description, priority, 0, "", session_id);
     }

   void DetectSmartAlerts(const SGmDashboardSnapshot &cur)
     {
      if(!m_have_prev)
        {
         m_prev = cur;
         m_have_prev = true;
         return;
        }

      // Connection
      if(m_prev.broker_connected && !cur.broker_connected)
        {
         m_notify.Notify(GM_NOTIFY_CONNECTION_LOST, cur.symbol, 0, "", cur.session_id);
         PushEnterpriseAlert(GM_ALERT_CRITICAL, "Connection Lost", cur.session_id, 5);
        }
      else if(!m_prev.broker_connected && cur.broker_connected)
        {
         m_notify.Notify(GM_NOTIFY_CONNECTION_RESTORED, cur.symbol, 0, "", cur.session_id);
         PushEnterpriseAlert(GM_ALERT_SUCCESS, "Connection Restored", cur.session_id, 2);
        }

      // Spread warning
      if(cur.spread_points >= GM_DASH_SPREAD_WARN_POINTS &&
         m_prev.spread_points < GM_DASH_SPREAD_WARN_POINTS)
        {
         m_notify.Notify(GM_NOTIFY_SPREAD_WARNING,
                         StringFormat("%.1f points", cur.spread_points),
                         0, "", cur.session_id);
         PushEnterpriseAlert(GM_ALERT_WARNING,
                             StringFormat("Spread Warning | %.1f", cur.spread_points),
                             cur.session_id, 4);
        }

      // Pending created
      if(cur.pending_orders > m_prev.pending_orders)
        {
         m_notify.Notify(GM_NOTIFY_PENDING_CREATED,
                         StringFormat("%d pending", cur.pending_orders),
                         0, "", cur.session_id);
         PushEnterpriseAlert(GM_ALERT_INFO,
                             StringFormat("Pending Created | %d", cur.pending_orders),
                             cur.session_id, 2);
        }

      // Trade activated (running increased)
      if(cur.running_trades > m_prev.running_trades)
        {
         m_notify.Notify(GM_NOTIFY_TRADE_ACTIVATED,
                         StringFormat("%d open", cur.running_trades),
                         0, "", cur.session_id);
         PushEnterpriseAlert(GM_ALERT_SUCCESS,
                             StringFormat("Trade Activated | open=%d", cur.running_trades),
                             cur.session_id, 2);
        }

      // BE / Trail from registry monitor flags
      if(m_prev.be_status != "ACTIVE" && cur.be_status == "ACTIVE")
        {
         m_notify.Notify(GM_NOTIFY_BREAK_EVEN, "", 0, "", cur.session_id);
         PushEnterpriseAlert(GM_ALERT_SUCCESS, "Break Even Activated", cur.session_id, 2);
        }
      if(m_prev.trail_status != "ACTIVE" && cur.trail_status == "ACTIVE")
        {
         m_notify.Notify(GM_NOTIFY_TRAILING, "", 0, "", cur.session_id);
         PushEnterpriseAlert(GM_ALERT_INFO, "Trailing Activated", cur.session_id, 2);
        }

      // Daily loss warning (drawdown / net)
      if(cur.today_net < 0.0)
        {
         const double loss_pct = (cur.balance > 0.0) ? (-cur.today_net / cur.balance * 100.0) : 0.0;
         if(loss_pct >= GM_PROT_MAX_DAILY_LOSS_WARN_DEFAULT &&
            (m_prev.today_net >= 0.0 ||
             (-m_prev.today_net / MathMax(m_prev.balance, 1.0) * 100.0) < GM_PROT_MAX_DAILY_LOSS_WARN_DEFAULT))
           {
            m_notify.Notify(GM_NOTIFY_DAILY_LOSS_WARNING,
                            StringFormat("%.2f%%", loss_pct), 0, "", cur.session_id);
            PushEnterpriseAlert(GM_ALERT_ERROR,
                                StringFormat("Daily Loss Warning | %.2f%%", loss_pct),
                                cur.session_id, 5);
           }
        }
      else if(cur.today_net > 0.0)
        {
         const double win_pct = (cur.balance > 0.0) ? (cur.today_net / cur.balance * 100.0) : 0.0;
         if(win_pct >= 3.0 &&
            (m_prev.today_net / MathMax(m_prev.balance, 1.0) * 100.0) < 3.0)
           {
            m_notify.Notify(GM_NOTIFY_DAILY_PROFIT_TARGET,
                            StringFormat("+%.2f%%", win_pct), 0, "", cur.session_id);
            PushEnterpriseAlert(GM_ALERT_SUCCESS,
                                StringFormat("Daily Profit Target | +%.2f%%", win_pct),
                                cur.session_id, 2);
           }
        }

      // Recovery
      if(!m_prev.recovery_ok && cur.recovery_ok)
        {
         m_notify.Notify(GM_NOTIFY_RECOVERY_COMPLETED, "", 0, "", cur.session_id);
         PushEnterpriseAlert(GM_ALERT_SUCCESS, "Recovery Completed", cur.session_id, 2);
         m_recovery_announced = true;
        }
      else if(m_prev.recovery_ok && !cur.recovery_ok && !m_recovery_announced)
        {
         m_notify.Notify(GM_NOTIFY_RECOVERY_STARTED, "", 0, "", cur.session_id);
         PushEnterpriseAlert(GM_ALERT_WARNING, "Recovery Started", cur.session_id, 4);
        }

      // Broker trading permission
      if(m_prev.trade_allowed && !cur.trade_allowed)
        {
         m_notify.Notify(GM_NOTIFY_BROKER_WARNING, "Trading not allowed", 0, "", cur.session_id);
         PushEnterpriseAlert(GM_ALERT_ERROR, "Broker Warning | Trading not allowed",
                             cur.session_id, 5);
        }

      m_prev = cur;
     }

   void Paint(SGmDashboardSnapshot &snap)
     {
      DetectSmartAlerts(snap);
      FillTimelineLines(snap);
      m_snap = snap;
      m_renderer.ApplySnapshot(m_snap);
      if(m_qa.IsReady())
         m_qa.OnSnapshot(m_snap);
     }

   void LogPerf(const string action, const ulong us)
     {
      if(m_logger == NULL)
         return;
      m_logger.Info(StringFormat("%s | refreshUs=%I64u | memKB=%I64u | cpuEst=0 | skips=%I64u",
                                 action, us,
                                 (ulong)TerminalInfoInteger(TERMINAL_MEMORY_USED),
                                 m_refresh.SkipCount()),
                    "Dashboard");
     }

   void ApplyAdaptiveRefresh(void)
     {
      if(!m_qa.IsReady())
         return;
      CGmDashboardPerfMonitor *perf = m_qa.Perf();
      if(perf == NULL)
         return;
      const int suggested = perf.SuggestedRefreshMs(m_settings.refresh_ms);
      if(suggested == m_settings.refresh_ms)
         return;
      // Soft adaptive only under load — does not persist profile
      if(suggested > m_settings.refresh_ms)
        {
         m_settings.refresh_ms = suggested;
         m_refresh.SetSettings(m_settings);
         if(m_logger != NULL)
            m_logger.Info(StringFormat("Adaptive Refresh | %d ms (load)",
                                       m_settings.refresh_ms),
                          "DashPerf");
        }
     }

public:
                     CGmDashboardEngine(void)
                       : m_logger(NULL), m_bridge(NULL), m_analytics(NULL), m_files(NULL),
                         m_journal(NULL), m_ai(NULL), m_multi(NULL),
                         m_ready(false),
                         m_have_prev(false), m_recovery_announced(false)
     {
      m_settings.Defaults();
      m_snap.Reset();
      m_prev.Reset();
     }

                    ~CGmDashboardEngine(void)
     {
      Shutdown();
     }

   bool Init(CGmLogger *logger,
             CGmPhase2Bridge *bridge,
             CGmRecoveryBase *recovery,
             const SGmDashboardSettings &settings,
             CGmAnalyticsEngine *analytics = NULL,
             CGmJournalEngine *journal = NULL,
             CGmAIDashboardEngine *ai = NULL,
             CGmMultiInstanceEngine *multi = NULL,
             CGmFileManager *files = NULL,
             const long magic = 0)
     {
      m_logger = logger;
      m_bridge = bridge;
      m_analytics = analytics;
      m_files = files;
      m_journal = journal;
      m_ai = ai;
      m_multi = multi;
      m_settings = settings;
      m_settings.Clamp();

      if(!m_settings.enable_dashboard)
        {
         m_ready = false;
         if(m_logger != NULL)
            m_logger.Info("Dashboard disabled by configuration", "Dashboard");
         return true;
        }

      if(m_logger != NULL)
         m_logger.Info("Dashboard Started | QA + Performance | " + GM_DASH_QA_RC_LABEL,
                       "Dashboard");

      m_ui.Init(logger, files, magic, m_settings);
      m_ui.SyncSettings(m_settings);

      m_data.Init(bridge, recovery, analytics, journal, ai, multi);
      m_events.Init(logger);
      m_notify.Init(logger);
      m_refresh.Init(GetPointer(m_data), GetPointer(m_events), m_settings);
      m_renderer.Init(m_settings);
      m_handler.Init(logger, GetPointer(m_renderer), m_settings, GetPointer(m_ui));
      m_settings = m_handler.Settings();
      m_renderer.ApplySettings(m_settings);
      m_qa.Init(logger, files);

      ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);

      m_ready = true;
      m_notify.Notify(GM_NOTIFY_INFO, "Dashboard Loaded");
      m_events.Publish(GM_DASH_EVT_LOADED, "Dashboard Loaded");
      if(m_logger != NULL)
         m_logger.Success("Dashboard Loaded | " + GM_DASH_QA_RC_LABEL + " | MONITOR ONLY",
                          "Dashboard");

      Show();
      RefreshNow();
      m_qa.RunFullSuite(GetPointer(m_data), m_bridge, m_analytics, m_settings);
      return true;
     }

   void Shutdown(void)
     {
      if(m_ready && m_renderer.Visible())
        {
         m_events.Publish(GM_DASH_EVT_HIDDEN, "Dashboard Hidden");
         if(m_logger != NULL)
            m_logger.Info("Panel Hidden", "Dashboard");
        }
      m_qa.Shutdown();
      m_ui.Shutdown();
      m_renderer.Destroy();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   bool IsVisible(void) const { return m_renderer.Visible(); }

   bool Show(void)
     {
      if(!m_ready)
         return false;
      const bool ok = m_renderer.Show();
      m_events.Publish(GM_DASH_EVT_LOADED, "Panel Shown");
      if(m_logger != NULL)
         m_logger.Info("Panel Shown", "Dashboard");
      return ok;
     }

   bool Hide(void)
     {
      if(!m_ready)
         return false;
      m_events.Publish(GM_DASH_EVT_HIDDEN, "Panel Hidden");
      if(m_logger != NULL)
         m_logger.Info("Panel Hidden", "Dashboard");
      return m_renderer.Hide();
     }

   bool RefreshNow(void)
     {
      if(!m_ready)
         return false;
      m_refresh.RequestImmediate();
      SGmDashboardSnapshot snap;
      if(!m_refresh.Tick(snap))
        {
         if(!m_data.Collect(snap))
            return false;
        }
      Paint(snap);
      LogPerf("Dashboard Refresh / Widget Updated", m_snap.last_refresh_us);
      return true;
     }

   bool GetSnapshot(SGmDashboardSnapshot &out) const
     {
      out = m_snap;
      return m_snap.valid;
     }

   void PublishEvent(const ENUM_GM_DASH_EVENT type, const string message)
     {
      m_events.Publish(type, message);
     }

   void Process(void)
     {
      if(!m_ready || !m_renderer.Visible())
         return;
      m_ui.Process();
      m_qa.Process();
      m_settings = m_handler.Settings();
      ApplyAdaptiveRefresh();
      m_refresh.SetSettings(m_settings);
      SGmDashboardSnapshot snap;
      if(!m_refresh.Tick(snap))
         return;
      Paint(snap);
      if(m_logger != NULL)
         m_logger.Debug(StringFormat("Performance Updated | %I64u us | mem=%I64u",
                                     m_snap.last_refresh_us, m_snap.terminal_memory_kb),
                        "Dashboard");
     }

   void OnNewH4(void)
     {
      PublishEvent(GM_DASH_EVT_NEW_H4, "New H4 Candle");
      m_notify.Notify(GM_NOTIFY_NEW_H4_SESSION, "H4 rollover", 0, "",
                      m_snap.session_id);
      m_refresh.RequestImmediate();
     }

   void OnSessionChanged(const ulong session_id)
     {
      PublishEvent(GM_DASH_EVT_SESSION_CHANGED,
                   StringFormat("Session Changed | SID=%I64u", session_id));
      m_notify.Notify(GM_NOTIFY_NEW_H4_SESSION,
                      StringFormat("SID=%I64u", session_id), 0, "", session_id);
      m_refresh.RequestImmediate();
     }

   void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
     {
      if(!m_ready)
         return;
      m_handler.OnChartEvent(id, lparam, dparam, sparam);
     }

   void OnTradeTransaction(const MqlTradeTransaction &trans)
     {
      if(!m_ready)
         return;

      if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
        {
         if(trans.deal_type == DEAL_TYPE_BUY || trans.deal_type == DEAL_TYPE_SELL)
           {
            PublishEvent(GM_DASH_EVT_TRADE_OPENED,
                         StringFormat("deal=%I64u", trans.deal));
            if(trans.deal > 0 && HistoryDealSelect(trans.deal))
              {
               const double profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
               const long reason = HistoryDealGetInteger(trans.deal, DEAL_REASON);
               if(reason == DEAL_REASON_TP)
                  m_notify.Notify(GM_NOTIFY_TP_HIT, StringFormat("%.2f", profit),
                                  trans.deal, "", m_snap.session_id);
               else if(reason == DEAL_REASON_SL)
                  m_notify.Notify(GM_NOTIFY_SL_HIT, StringFormat("%.2f", profit),
                                  trans.deal, "", m_snap.session_id);
               else
                  m_notify.Notify(GM_NOTIFY_TRADE_ACTIVATED,
                                  StringFormat("deal=%I64u", trans.deal),
                                  trans.deal, "", m_snap.session_id);
              }
            else
               m_notify.Notify(GM_NOTIFY_TRADE_ACTIVATED,
                               StringFormat("deal=%I64u", trans.deal),
                               trans.deal, "", m_snap.session_id);
           }
        }
      else if(trans.type == TRADE_TRANSACTION_HISTORY_ADD)
        {
         PublishEvent(GM_DASH_EVT_TRADE_CLOSED, "Trade closed / history");
        }
      else if(trans.type == TRADE_TRANSACTION_ORDER_ADD)
        {
         PublishEvent(GM_DASH_EVT_PENDING_ADDED,
                      StringFormat("order=%I64u", trans.order));
         m_notify.Notify(GM_NOTIFY_PENDING_CREATED,
                         StringFormat("order=%I64u", trans.order),
                         trans.order, "", m_snap.session_id);
        }
      else if(trans.type == TRADE_TRANSACTION_ORDER_DELETE)
        {
         PublishEvent(GM_DASH_EVT_PENDING_DELETED,
                      StringFormat("order=%I64u", trans.order));
        }

      m_refresh.RequestImmediate();
     }

   /// @brief External hooks for lifecycle events (still read-only display).
   void NotifyBreakEven(const ulong trade_id = 0)
     {
      m_notify.Notify(GM_NOTIFY_BREAK_EVEN, "", trade_id, "", m_snap.session_id);
     }

   void NotifyPartial(const ulong trade_id = 0)
     {
      m_notify.Notify(GM_NOTIFY_PARTIAL_CLOSE, "", trade_id, "", m_snap.session_id);
     }

   void NotifyTrail(const ulong trade_id = 0)
     {
      m_notify.Notify(GM_NOTIFY_TRAILING, "", trade_id, "", m_snap.session_id);
     }

   void NotifyLevelReactivated(const string level_id)
     {
      m_notify.Notify(GM_NOTIFY_LEVEL_REACTIVATED, level_id, 0, level_id, m_snap.session_id);
     }

   bool RunQaSuite(void)
     {
      if(!m_ready)
         return false;
      return m_qa.RunFullSuite(GetPointer(m_data), m_bridge, m_analytics, m_settings);
     }

   SGmDashboardQAReport QaReport(void) const { return m_qa.Report(); }
   bool QaPassed(void) const
     {
      return (m_qa.HasRun() && m_qa.Report().decision == "PASS");
     }
  };

#endif // GM_CDASHBOARD_ENGINE_MQH
//+------------------------------------------------------------------+
