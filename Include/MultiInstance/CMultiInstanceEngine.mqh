//+------------------------------------------------------------------+
//|                                      CMultiInstanceEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     Phase 2 Sprint 7 — Multi-Instance Management (READ-ONLY)    |
//+------------------------------------------------------------------+
#ifndef GM_CMULTI_INSTANCE_ENGINE_MQH
#define GM_CMULTI_INSTANCE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CInstanceManager.mqh"
#include "CGlobalMonitor.mqh"
#include "CSyncEngine.mqh"
#include "CMultiInstanceApi.mqh"
#include "../Core/CFileManager.mqh"
#include "../Phase2/CPhase2Bridge.mqh"
#include "../Analytics/CAnalyticsEngine.mqh"
#include "../Analytics/SGmAnalyticsSnapshot.mqh"
#include "../Protection/SGmAccountSnapshot.mqh"
#include "../Protection/SGmDrawdownState.mqh"
#include "../Recovery/CRecoveryBase.mqh"
#include "../Logging/CLogger.mqh"

/// @file CMultiInstanceEngine.mqh
/// @brief Orchestrates instance registration, health, global monitor, sync.
/// @warning Isolation: each instance owns its magic/symbol/chart only.
/// @warning Never synchronizes trading actions across instances.

class CGmMultiInstanceEngine
  {
private:
   CGmLogger              *m_logger;
   CGmFileManager         *m_files;
   CGmPhase2Bridge        *m_bridge;
   CGmAnalyticsEngine     *m_analytics;
   CGmRecoveryBase        *m_recovery;

   CGmInstanceManager      m_instances;
   CGmGlobalMonitor        m_global;
   CGmSyncEngine           m_sync;
   CGmMultiInstanceApi     m_api;

   SGmGlobalMonitorSnapshot m_snap;
   bool                     m_ready;
   bool                     m_dashboard_ok;

public:
                     CGmMultiInstanceEngine(void)
                       : m_logger(NULL), m_files(NULL), m_bridge(NULL),
                         m_analytics(NULL), m_recovery(NULL),
                         m_ready(false), m_dashboard_ok(true)
     {
      m_snap.Reset();
     }

                    ~CGmMultiInstanceEngine(void) { Shutdown(); }

   bool Init(CGmLogger *logger,
             CGmFileManager *files,
             CGmPhase2Bridge *bridge,
             CGmAnalyticsEngine *analytics,
             CGmRecoveryBase *recovery,
             const string symbol,
             const ENUM_TIMEFRAMES tf,
             const long magic)
     {
      m_logger = logger;
      m_files = files;
      m_bridge = bridge;
      m_analytics = analytics;
      m_recovery = recovery;

      const ulong sid = (bridge != NULL) ? bridge.SessionId() : 0;
      m_instances.Init(logger, files, symbol, tf, magic, sid);
      m_global.Init(logger);
      m_sync.Init(logger);
      m_api.Init(logger);
      m_ready = true;
      m_dashboard_ok = true;

      Process(true);

      if(m_logger != NULL)
         m_logger.Success("Multi-Instance Engine ready | isolation + global monitor | READ-ONLY",
                          "MultiInstance");
      return true;
     }

   void Shutdown(void)
     {
      if(!m_ready)
         return;
      m_instances.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmGlobalMonitorSnapshot Snapshot(void) const { return m_snap; }
   string InstanceId(void) const { return m_instances.InstanceId(); }
   long ChartId(void) const { return m_instances.ChartId(); }
   CGmMultiInstanceApi *Api(void) { return GetPointer(m_api); }
   CGmGlobalMonitor *Global(void) { return GetPointer(m_global); }

   void SetDashboardOk(const bool ok) { m_dashboard_ok = ok; }

   void Process(const bool force)
     {
      if(!m_ready)
         return;
      if(!force && !m_sync.ShouldSync())
         return;

      const ulong t0 = GetMicrosecondCount();

      int open_tr = 0;
      int pending = 0;
      double fp = 0.0, fl = 0.0, equity = 0.0, risk = 0.0, dd = 0.0;
      string dash = m_dashboard_ok ? "OK" : "OFF";
      string trade_st = "RUNNING";
      string analytics_st = "—";
      string recovery_st = "N/A";
      bool trading_en = (TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) != 0) &&
                        (MQLInfoInteger(MQL_TRADE_ALLOWED) != 0);
      bool internet = (TerminalInfoInteger(TERMINAL_CONNECTED) != 0);
      bool broker = internet;
      ulong sid = 0;

      if(m_bridge != NULL)
        {
         open_tr = m_bridge.OwnPositions();
         pending = m_bridge.OwnPendings();
         sid = m_bridge.SessionId();
         SGmAccountSnapshot acc;
         if(m_bridge.ReadAccount(acc) && acc.valid)
            equity = acc.equity;
         SGmDrawdownState dds;
         if(m_bridge.ReadDrawdown(dds) && dds.valid)
            dd = dds.current_dd_pct;
        }

      if(m_analytics != NULL)
        {
         m_analytics.Collect();
         const SGmAnalyticsSnapshot a = m_analytics.Snapshot();
         if(a.valid)
           {
            analytics_st = a.module_health;
            fp = a.floating_profit;
            fl = a.floating_loss;
            if(equity <= 0.0)
               equity = a.equity;
            risk = a.current_risk_pct;
            if(dd <= 0.0)
               dd = a.current_dd_pct;
            if(open_tr <= 0)
               open_tr = a.running_trades;
            if(pending <= 0)
               pending = a.pending_orders;
           }
        }

      if(m_recovery != NULL)
         recovery_st = m_recovery.LastSnapshot().state_restored ? "READY" : "WAITING";

      m_instances.UpdateRuntime(sid, open_tr, pending, fp, fl, equity, risk, dd,
                                dash, trade_st, analytics_st, recovery_st,
                                trading_en, internet, broker);
      m_instances.PublishHeartbeat();

      m_global.Refresh(m_instances.Local());
      m_snap = m_global.Snapshot();
      m_sync.MarkSynced(GetMicrosecondCount() - t0, m_snap);
     }

   void Process(void)
     {
      Process(false);
     }
  };

#endif // GM_CMULTI_INSTANCE_ENGINE_MQH
//+------------------------------------------------------------------+
