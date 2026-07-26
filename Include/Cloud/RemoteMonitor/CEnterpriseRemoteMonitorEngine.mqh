//+------------------------------------------------------------------+
//|                            CEnterpriseRemoteMonitorEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 6 Sprint 2 — Remote Management facade (monitor only)  |
//+------------------------------------------------------------------+
#ifndef GM_CENTERPRISE_REMOTE_MONITOR_ENGINE_MQH
#define GM_CENTERPRISE_REMOTE_MONITOR_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "RemoteMonitorConstants.mqh"
#include "SGmRemoteMonitorResult.mqh"
#include "CRemoteManagementEngine.mqh"
#include "CRmSystemHealthEngine.mqh"
#include "CEnterpriseTelemetry.mqh"
#include "CRemoteEventCenter.mqh"
#include "CAutoHealthRecovery.mqh"
#include "CRemoteMonitorDatabase.mqh"
#include "../CEnterpriseCloudEngine.mqh"
#include "../CCloudSecurity.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../../AI/SGmAISnapshot.mqh"

class CGmEnterpriseRemoteMonitorEngine
  {
private:
   CGmLogger                   *m_logger;
   CGmEnterpriseCloudEngine    *m_cloud;
   CGmCloudSecurity             m_sec;   // independent security for telemetry integrity
   CGmRemoteManagementEngine    m_mgmt;
   CGmRmSystemHealthEngine      m_syshealth;
   CGmEnterpriseTelemetry       m_telemetry;
   CGmRemoteEventCenter         m_events;
   CGmAutoHealthRecovery        m_recovery;
   CGmRemoteMonitorDatabase     m_db;
   SGmRemoteMonitorResult       m_last;
   ulong                        m_last_ms;
   ulong                        m_cycle_us;
   bool                         m_ea_running;
   bool                         m_trading_ready;
   bool                         m_ai_ready;
   bool                         m_dashboard_ready;
   bool                         m_ready;

public:
                     CGmEnterpriseRemoteMonitorEngine(void)
                       : m_logger(NULL), m_cloud(NULL), m_last_ms(0), m_cycle_us(0),
                         m_ea_running(false), m_trading_ready(false),
                         m_ai_ready(false), m_dashboard_ready(false), m_ready(false)
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
      const string seed = StringFormat("RM|%I64d|%s|%s", magic, symbol, GM_RM_VERSION);
      m_sec.Init(seed);
      m_telemetry.Init(GetPointer(m_sec));
      m_events.Init(GetPointer(m_sec));
      m_recovery.Init();
      m_last.Reset();
      m_ready = true;
      if(m_logger != NULL)
        {
         m_logger.Success("Remote Management Engine Started | " + GM_RM_VERSION, "RM");
         m_logger.Info("POLICY | " + GM_RM_POLICY, "RM");
         m_logger.Info("SAFE | " + GM_RM_SAFE, "RM");
        }
      return true;
     }

   void BindCloud(CGmEnterpriseCloudEngine *cloud)
     {
      m_cloud = cloud;
      if(m_logger != NULL && cloud != NULL)
         m_logger.Info("Remote Monitor bound to Cloud Engine (observe only)", "RM");
     }

   void SetObservedFlags(const bool ea_running,
                         const bool trading_ready,
                         const bool ai_ready,
                         const bool dashboard_ready)
     {
      m_ea_running = ea_running;
      m_trading_ready = trading_ready;
      m_ai_ready = ai_ready;
      m_dashboard_ready = dashboard_ready;
     }

   void Shutdown(void)
     {
      m_events.OnShutdown();
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmRemoteMonitorResult Last(void) const { return m_last; }

   bool Process(const bool force = false)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(!force && m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_RM_THROTTLE_MS)
         return true;

      const ulong t0 = GetMicrosecondCount();
      m_last_ms = now;

      SGmCloudStatus cloud_st;
      cloud_st.Reset();
      if(m_cloud != NULL && m_cloud.IsReady())
         cloud_st = m_cloud.Last();

      SGmRemoteMonitorResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.status = GM_RM_STATUS_RUNNING;
      r.may_execute = false;
      r.may_modify_risk = false;

      m_mgmt.CollectStatus(cloud_st, m_ea_running, m_trading_ready, m_ai_ready, m_dashboard_ready, r);
      m_syshealth.Measure(cloud_st, m_ai_ready, m_cycle_us, r);
      m_telemetry.Collect(r);
      m_events.Emit(cloud_st, m_trading_ready, r);
      m_recovery.Evaluate(m_cloud, GetPointer(m_telemetry), GetPointer(m_events), r);

      r.center_status = "REMOTE MONITOR READY";
      r.enterprise_status = StringFormat("Health=%.0f | %s",
                                         r.overall_health_score, GM_RM_POLICY);
      r.insight = StringFormat("%s | CPU=%.0f RAM=%.0f Lat=%.0f Net=%.0f | %s",
                               r.center_status, r.cpu_usage_pct, r.ram_usage_pct,
                               r.cloud_latency_ms, r.network_quality, GM_RM_SAFE);
      r.status = (r.overall_health_score < 45.0) ? GM_RM_STATUS_DEGRADED : GM_RM_STATUS_READY;
      r.valid = true;

      m_db.Record(r, m_events.Body());
      m_last = r;
      m_cycle_us = GetMicrosecondCount() - t0;

      if(m_logger != NULL)
        {
         m_logger.Info(StringFormat("Health Updated | score=%.0f cpu=%.0f ram=%.0f",
                                    r.overall_health_score, r.cpu_usage_pct, r.ram_usage_pct), "RM");
         m_logger.Info("Telemetry Uploaded | hash=" + r.encrypted_telemetry_hash, "RM");
         if(r.heartbeat_status == "OK")
            m_logger.Info("Heartbeat Successful", "RM");
         m_logger.Info("System Event Created | " + r.latest_event, "RM");
         if(r.recovery_actions > 0 && StringFind(r.recovery_log, "No recovery") < 0)
            m_logger.Info("Recovery Completed | " + r.recovery_log, "RM");
         m_logger.Debug(StringFormat("Performance Updated | cycle=%I64u us", m_cycle_us), "RM");
        }
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = m_last.center_status;
      s.ai_engine = "GoldMind Enterprise Remote Monitor";
      s.current_mode = "CLOUD_REMOTE_MONITOR";
      s.confidence_pct = m_last.overall_health_score;
      s.confidence_status = StringFormat("%.0f", m_last.overall_health_score);

      // Phase 6 Sprint 2 widgets
      s.w_trend_detector = StringFormat("%.0f", m_last.overall_health_score);    // Overall Health
      s.future_ai_score = StringFormat("%.0f%%", m_last.cpu_usage_pct);          // CPU
      s.w_recovery_ai = StringFormat("%.0f%%", m_last.ram_usage_pct);            // RAM
      s.prediction_status = StringFormat("%.0f ms", m_last.cloud_latency_ms);    // Cloud Latency
      s.learning_status = StringFormat("%.0f", m_last.database_health);          // Database Health
      s.w_volatility_scanner = m_last.sync_status;                               // Sync Status
      s.w_market_analyzer = m_last.heartbeat_status;                             // Heartbeat
      s.w_news_analyzer = StringFormat("%.0f", m_last.network_quality);          // Network Quality
      s.w_trade_confidence = StringFormat("%.0f", m_last.system_stability);      // System Stability
      s.ai_version = m_last.telemetry_status + " | " + m_last.enterprise_status; // Telemetry/Enterprise
      s.decision_status = GM_RM_POLICY;
      s.valid = true;
     }
  };

#endif // GM_CENTERPRISE_REMOTE_MONITOR_ENGINE_MQH
//+------------------------------------------------------------------+
