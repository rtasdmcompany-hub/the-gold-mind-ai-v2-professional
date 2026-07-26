//+------------------------------------------------------------------+
//|                        CEnterpriseInfrastructureEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 6 Sprint 4 — VPS / Multi-Terminal Control facade      |
//|     MONITOR ONLY — NEVER executes trades remotely               |
//+------------------------------------------------------------------+
#ifndef GM_CENTERPRISE_INFRASTRUCTURE_ENGINE_MQH
#define GM_CENTERPRISE_INFRASTRUCTURE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "InfrastructureConstants.mqh"
#include "SGmInfrastructureResult.mqh"
#include "CEifInfrastructureSecurity.mqh"
#include "CEifDeviceGroupManager.mqh"
#include "CEifVpsManagementEngine.mqh"
#include "CEifMultiTerminalManager.mqh"
#include "CEifBackgroundSync.mqh"
#include "CEifControlCenter.mqh"
#include "CEifInfrastructureDatabase.mqh"
#include "../CEnterpriseCloudEngine.mqh"
#include "../RemoteMonitor/CEnterpriseRemoteMonitorEngine.mqh"
#include "../Notifications/CEnterpriseNotificationEngine.mqh"
#include "../CCloudSecurity.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Core/Version.mqh"
#include "../../Logging/CLogger.mqh"
#include "../../AI/SGmAISnapshot.mqh"

class CGmEnterpriseInfrastructureEngine
  {
private:
   CGmLogger                        *m_logger;
   CGmEnterpriseCloudEngine         *m_cloud;
   CGmEnterpriseRemoteMonitorEngine *m_remote;
   CGmEnterpriseNotificationEngine  *m_notify;
   CGmCloudSecurity                  m_sec_core;
   CGmEifInfrastructureSecurity      m_sec;
   CGmEifDeviceGroupManager          m_groups;
   CGmEifVpsManagementEngine         m_vps;
   CGmEifMultiTerminalManager        m_terminals;
   CGmEifBackgroundSync              m_sync;
   CGmEifControlCenter               m_control;
   CGmEifInfrastructureDatabase      m_db;
   SGmInfrastructureResult           m_last;
   ENUM_GM_EIF_DEVICE_STATE          m_prev_local_state;
   bool                              m_prev_valid;
   ulong                             m_last_ms;
   ulong                             m_cycle_us;
   bool                              m_ready;

   string AccountTypeName(void) const
     {
      const long mode = AccountInfoInteger(ACCOUNT_TRADE_MODE);
      if(mode == ACCOUNT_TRADE_MODE_DEMO) return "Demo";
      if(mode == ACCOUNT_TRADE_MODE_CONTEST) return "Contest";
      return "Live";
     }

public:
                     CGmEnterpriseInfrastructureEngine(void)
                       : m_logger(NULL), m_cloud(NULL), m_remote(NULL), m_notify(NULL),
                         m_prev_local_state(GM_EIF_DEV_UNKNOWN), m_prev_valid(false),
                         m_last_ms(0), m_cycle_us(0), m_ready(false)
     {
      m_last.Reset();
     }

   bool Init(CGmLogger *logger,
             CGmFileManager *files,
             const long magic,
             const string symbol)
     {
      m_logger = logger;
      m_db.Init(logger, files, magic, symbol);
      const string seed = StringFormat("EIF|%I64d|%s|%s", magic, symbol, GM_EIF_VERSION);
      m_sec_core.Init(seed);
      m_sec.Init(GetPointer(m_sec_core));
      m_groups.Init();
      m_vps.Init();
      m_terminals.Init(GetPointer(m_groups), GetPointer(m_sec));
      m_sync.Init(GetPointer(m_sec));
      m_control.Init();
      m_last.Reset();
      m_ready = true;
      if(m_logger != NULL)
        {
         m_logger.Success("Infrastructure Engine Started | " + GM_EIF_VERSION, "EIF");
         m_logger.Info("POLICY | " + GM_EIF_POLICY, "EIF");
         m_logger.Info("SAFE | " + GM_EIF_SAFE, "EIF");
         m_logger.Info("Device Connected | local node registering", "EIF");
        }
      return true;
     }

   void BindCloud(CGmEnterpriseCloudEngine *cloud)
     {
      m_cloud = cloud;
      if(m_logger != NULL && cloud != NULL)
         m_logger.Info("Infrastructure bound to Cloud (observe only)", "EIF");
     }

   void BindRemote(CGmEnterpriseRemoteMonitorEngine *remote)
     {
      m_remote = remote;
      if(m_logger != NULL && remote != NULL)
         m_logger.Info("Infrastructure bound to Remote Monitor (observe only)", "EIF");
     }

   void BindNotify(CGmEnterpriseNotificationEngine *notify)
     {
      m_notify = notify;
      if(m_logger != NULL && notify != NULL)
         m_logger.Info("Infrastructure bound to Notification Center (observe only)", "EIF");
     }

   void SetGroupFilter(const ENUM_GM_EIF_DEVICE_GROUP g) { m_groups.SetFilter(g); }
   void SetSearch(const string q) { m_groups.SetSearch(q); }

   void Shutdown(void)
     {
      if(m_ready && m_logger != NULL)
         m_logger.Info("Device Disconnected | infrastructure shutdown", "EIF");
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmInfrastructureResult Last(void) const { return m_last; }

   bool Process(const bool force = false)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(!force && m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_EIF_THROTTLE_MS)
         return true;

      const ulong t0 = GetMicrosecondCount();
      m_last_ms = now;

      SGmCloudStatus cloud_st;
      cloud_st.Reset();
      if(m_cloud != NULL && m_cloud.IsReady())
         cloud_st = m_cloud.Last();

      SGmRemoteMonitorResult rm_st;
      rm_st.Reset();
      if(m_remote != NULL && m_remote.IsReady())
         rm_st = m_remote.Last();

      SGmNotificationCenterResult ntf_st;
      ntf_st.Reset();
      if(m_notify != NULL && m_notify.IsReady())
         ntf_st = m_notify.Last();

      SGmInfrastructureResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();

      const bool ea_running = true;
      string term_path = TerminalInfoString(TERMINAL_PATH);
      string data_path = TerminalInfoString(TERMINAL_DATA_PATH);
      const bool is_vps = (StringFind(term_path, "VPS") >= 0 ||
                           StringFind(term_path, "vps") >= 0 ||
                           StringFind(data_path, "VPS") >= 0 ||
                           StringFind(data_path, "vps") >= 0);

      m_vps.Measure(cloud_st, rm_st, ea_running, r);

      if(m_logger != NULL)
        {
         if(r.vps_online_status == "Online")
            m_logger.Info("VPS Online | " + r.vps_online_status, "EIF");
         else
            m_logger.Warning("VPS Offline/Degraded | " + r.vps_online_status, "EIF");
         m_logger.Info("Heartbeat Received | " + r.heartbeat_status, "EIF");
         m_logger.Info("Synchronization Started", "EIF");
        }

      m_terminals.UpsertLocal(cloud_st,
                              AccountInfoString(ACCOUNT_COMPANY),
                              AccountInfoInteger(ACCOUNT_LOGIN),
                              AccountTypeName(),
                              AccountInfoString(ACCOUNT_SERVER),
                              ea_running,
                              is_vps);
      m_terminals.EnsureDemoSlots();
      m_terminals.Aggregate(r);

      m_sync.Synchronize(cloud_st, rm_st, ntf_st, r);
      if(m_logger != NULL)
         m_logger.Info("Synchronization Completed | " + r.synchronization_status, "EIF");

      m_control.Compose(cloud_st, r);

      // Connection transition logs
      ENUM_GM_EIF_DEVICE_STATE local_state = GM_EIF_DEV_ONLINE;
      if(r.online_devices <= 0)
         local_state = GM_EIF_DEV_OFFLINE;
      else if(r.vps_online_status != "Online")
         local_state = GM_EIF_DEV_DEGRADED;

      if(m_prev_valid && m_logger != NULL)
        {
         if(m_prev_local_state != GM_EIF_DEV_ONLINE && local_state == GM_EIF_DEV_ONLINE)
            m_logger.Info("Device Connected | enterprise node online", "EIF");
         if(m_prev_local_state == GM_EIF_DEV_ONLINE && local_state != GM_EIF_DEV_ONLINE)
            m_logger.Warning("Device Disconnected | enterprise node degraded/offline", "EIF");
        }
      m_prev_local_state = local_state;
      m_prev_valid = true;

      if(m_sec.UnauthorizedAttempts() > 0 && m_logger != NULL)
         m_logger.Warning(StringFormat("Unauthorized Access Attempt | count=%d",
                                       m_sec.UnauthorizedAttempts()), "EIF");

      const string audit = m_sec.AuditLine() +
                           " | may_execute=false | may_modify_risk=false";
      m_db.Record(r, r.device_summary, audit);
      m_last = r;
      m_cycle_us = GetMicrosecondCount() - t0;

      if(m_logger != NULL)
        {
         m_logger.Debug(StringFormat("Performance Statistics | cycle=%I64u us | score=%.0f",
                                     m_cycle_us, r.enterprise_score), "EIF");
        }
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = m_last.center_status;
      s.ai_engine = "GoldMind Enterprise Infrastructure";
      s.current_mode = "CLOUD_INFRASTRUCTURE";
      s.confidence_pct = m_last.enterprise_score;
      s.confidence_status = StringFormat("%.0f", m_last.enterprise_score);

      // Phase 6 Sprint 4 widgets
      s.w_trend_detector = IntegerToString(m_last.connected_devices);   // Connected Devices
      s.future_ai_score = IntegerToString(m_last.online_vps);           // Online VPS
      s.w_recovery_ai = IntegerToString(m_last.offline_vps);            // Offline VPS
      s.prediction_status = StringFormat("%.0f", m_last.cloud_health);  // Cloud Health
      s.learning_status = StringFormat("%.0f ms", m_last.avg_latency_ms); // Avg Latency
      s.w_volatility_scanner = StringFormat("%.0f%%", m_last.avg_cpu_pct); // Avg CPU
      s.w_market_analyzer = StringFormat("%.0f%%", m_last.avg_ram_pct); // Avg RAM
      s.w_news_analyzer = StringFormat("%.0f", m_last.sync_health);     // Sync Health
      s.w_trade_confidence = m_last.heartbeat_status;                   // Heartbeat
      s.ai_version = m_last.enterprise_status;                          // Enterprise Status
      s.decision_status = GM_EIF_POLICY;
      s.valid = true;
     }
  };

#endif // GM_CENTERPRISE_INFRASTRUCTURE_ENGINE_MQH
//+------------------------------------------------------------------+
