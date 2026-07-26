//+------------------------------------------------------------------+
//|                         CAIEnterpriseMonitoringEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 4 Sprint 6 — Enterprise Monitoring Facade             |
//+------------------------------------------------------------------+
#ifndef GM_CAI_ENTERPRISE_MONITORING_ENGINE_MQH
#define GM_CAI_ENTERPRISE_MONITORING_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "EnterpriseAIConstants.mqh"
#include "SGmEnterpriseResult.mqh"
#include "CAccountProfileManager.mqh"
#include "CAIMultiAccountSupervisor.mqh"
#include "CCloudMonitoringEngine.mqh"
#include "CAccountComparisonEngine.mqh"
#include "CAIFleetHealthMonitor.mqh"
#include "CEnterpriseObservationApi.mqh"
#include "CEnterpriseDatabase.mqh"
#include "CEnterpriseBatchScheduler.mqh"
#include "../Assistant/CAISupervisorEngine.mqh"
#include "../Intelligence/CAIDecisionIntelligenceEngine.mqh"
#include "../Memory/CAILearningMemoryEngine.mqh"
#include "../Reporting/CAIEnterpriseReportingEngine.mqh"
#include "../Conversation/CAIConversationalAssistantEngine.mqh"
#include "../../MultiInstance/SGmGlobalMonitorSnapshot.mqh"
#include "../../MultiInstance/CMultiInstanceEngine.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../SGmAISnapshot.mqh"

class CGmAIEnterpriseMonitoringEngine
  {
private:
   CGmLogger             *m_logger;
   CGmPhase2Bridge       *m_bridge;
   CGmAISupervisorEngine *m_supervisor;
   CGmAIDecisionIntelligenceEngine *m_intel;
   CGmAILearningMemoryEngine *m_memlearn;
   CGmAIEnterpriseReportingEngine *m_aireport;
   CGmAIConversationalAssistantEngine *m_aichat;
   CGmMultiInstanceEngine *m_multi_instance;

   CGmAccountProfileManager      m_profiles;
   CGmAIMultiAccountSupervisor   m_multi;
   CGmCloudMonitoringEngine      m_cloud;
   CGmAccountComparisonEngine    m_compare;
   CGmAIFleetHealthMonitor       m_fleet;
   CGmEnterpriseObservationApi   m_api;
   CGmEnterpriseDatabase         m_db;
   CGmEnterpriseBatchScheduler   m_sched;

   SGmGlobalMonitorSnapshot m_mi;
   bool                     m_have_mi;
   bool                     m_dashboard_ok;
   bool                     m_core_ok;

   SGmEnterpriseResult m_last;
   long                m_magic;
   bool                m_ready;

public:
                     CGmAIEnterpriseMonitoringEngine(void)
                       : m_logger(NULL), m_bridge(NULL), m_supervisor(NULL),
                         m_intel(NULL), m_memlearn(NULL), m_aireport(NULL),
                         m_aichat(NULL), m_multi_instance(NULL), m_have_mi(false), m_dashboard_ok(true),
                         m_core_ok(true), m_magic(0), m_ready(false)
     {
      m_mi.Reset();
      m_last.Reset();
     }

   bool Init(CGmLogger *logger,
             CGmFileManager *files,
             CGmPhase2Bridge *bridge,
             const long magic,
             const string symbol)
     {
      m_logger = logger;
      m_bridge = bridge;
      m_magic = magic;
      m_db.Init(logger, files, magic, symbol);
      m_sched.Reset();
      m_last.Reset();
      m_ready = true;
      if(m_logger != NULL)
        {
         m_logger.Success("Multi Account Supervisor Started | " + GM_ENT_VERSION +
                          " | " + GM_ENT_ANALYSIS_ONLY, "AIEnt");
         m_logger.Info("Cloud Monitoring Started | foundation telemetry", "AIEnt");
         m_logger.Info("POLICY | " + GM_ENT_ADVISORY + " | no credentials stored", "AIEnt");
        }
      return true;
     }

   void BindSources(CGmAISupervisorEngine *supervisor,
                    CGmAIDecisionIntelligenceEngine *intel,
                    CGmAILearningMemoryEngine *memlearn,
                    CGmAIEnterpriseReportingEngine *aireport,
                    CGmAIConversationalAssistantEngine *aichat,
                    CGmMultiInstanceEngine *multi_instance = NULL)
     {
      m_supervisor = supervisor;
      m_intel = intel;
      m_memlearn = memlearn;
      m_aireport = aireport;
      m_aichat = aichat;
      m_multi_instance = multi_instance;
      if(m_logger != NULL)
         m_logger.Info("Enterprise sources bound | Supervisor+Intel+Memory+Report+Chat+MultiInstance",
                       "AIEnt");
     }

   void SetDashboardOk(const bool ok) { m_dashboard_ok = ok; }
   void SetCoreOk(const bool ok) { m_core_ok = ok; }

   void BindMultiInstance(CGmMultiInstanceEngine *multi_instance)
     {
      m_multi_instance = multi_instance;
      if(m_logger != NULL && multi_instance != NULL)
         m_logger.Info("MultiInstance observer bound | MONITOR ONLY", "AIEnt");
     }

   void BindGlobalMonitorSnapshot(const SGmGlobalMonitorSnapshot &snap)
     {
      m_mi = snap;
      m_have_mi = snap.valid;
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmEnterpriseResult Last(void) const { return m_last; }
   CGmEnterpriseObservationApi *ObservationApi(void) { return GetPointer(m_api); }

   bool Analyze(void)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      m_sched.Signal();
      if(!m_sched.ShouldRun(now, GM_ENT_THROTTLE_MS))
        {
         if(m_last.valid && m_sched.CacheValid(now))
           {
            m_last.from_cache = true;
            m_last.status = GM_ENT_STATUS_CACHED;
            return true;
           }
         return m_last.valid;
        }

      m_sched.Begin(now);

      SGmEnterpriseResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.status = GM_ENT_STATUS_RUNNING;
      r.may_execute = false;
      r.may_control_accounts = false;
      r.api_execution_enabled = false;
      r.advisory_status = GM_ENT_ADVISORY;

      if(m_bridge != NULL)
        {
         r.symbol = m_bridge.Symbol();
         r.session_id = m_bridge.SessionId();
        }
      if(StringLen(r.symbol) == 0)
        {
         r.status = GM_ENT_STATUS_ERROR;
         m_sched.Complete(now);
         return false;
        }

      SGmAssistantResult sup;
      SGmIntelligenceResult intel;
      SGmMemoryLearningResult mem;
      SGmReportingResult rpt;
      SGmConversationResult chat;
      sup.Reset(); intel.Reset(); mem.Reset(); rpt.Reset(); chat.Reset();
      if(m_supervisor != NULL && m_supervisor.IsReady()) sup = m_supervisor.Last();
      if(m_intel != NULL && m_intel.IsReady()) intel = m_intel.Last();
      if(m_memlearn != NULL && m_memlearn.IsReady()) mem = m_memlearn.Last();
      if(m_aireport != NULL && m_aireport.IsReady()) rpt = m_aireport.Last();
      if(m_aichat != NULL && m_aichat.IsReady()) chat = m_aichat.Last();

      SGmEnterpriseAccountProfile profile;
      m_profiles.BuildLocal(m_bridge, (TerminalInfoInteger(TERMINAL_CONNECTED) != 0), profile);
      if(m_logger != NULL)
         m_logger.Info("Account Connected | id=" + profile.account_id +
                       " | credentials_stored=false", "AIEnt");

      SGmGlobalMonitorSnapshot mi;
      mi.Reset();
      if(m_multi_instance != NULL && m_multi_instance.IsReady())
        {
         mi = m_multi_instance.Snapshot();
         m_have_mi = mi.valid;
         m_mi = mi;
        }
      else if(m_have_mi)
         mi = m_mi;

      m_multi.Analyze(profile, sup, intel, mi, r);
      if(m_logger != NULL)
         m_logger.Info("Account Health Updated | " + GmEntAcctHealthName(r.local_health), "AIEnt");

      m_cloud.Analyze(sup, mem, rpt, chat, m_core_ok, m_dashboard_ok, r);
      m_compare.Analyze(r, intel, sup, r);
      if(m_logger != NULL)
         m_logger.Info("Comparison Report Generated", "AIEnt");

      m_fleet.Analyze(r, sup, mi, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Fleet Health Calculated | %.0f/100 | %s",
                                    r.fleet_health_score, r.fleet_status), "AIEnt");

      r.api_endpoints = m_api.EndpointCatalog();
      if(m_logger != NULL)
         m_logger.Info("API Monitoring Completed | read-only catalog", "AIEnt");

      r.enterprise_status = "ENTERPRISE READY";
      r.status = GM_ENT_STATUS_READY;
      r.insight = StringFormat("%s | Accts=%d Fleet=%.0f Local=%s Alerts=%s | %s",
                               r.enterprise_status,
                               r.accounts_monitored,
                               r.fleet_health_score,
                               GmEntAcctHealthName(r.local_health),
                               r.enterprise_alerts,
                               GM_ENT_ANALYSIS_ONLY);
      r.valid = true;

      m_db.Record(r, m_api);
      m_last = r;
      m_sched.Complete(GetTickCount());

      if(m_logger != NULL)
         m_logger.Info("Enterprise Dashboard Updated | pending=" +
                       IntegerToString(m_sched.Pending()), "AIEnt");
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = m_last.enterprise_status;
      s.ai_engine = "GoldMind AI Enterprise Monitor";
      s.current_mode = "AI_ENTERPRISE";
      s.confidence_pct = m_last.fleet_health_score;
      s.confidence_status = StringFormat("%.0f", m_last.fleet_health_score);

      // Enterprise Control Center widgets
      s.w_trend_detector = IntegerToString(m_last.accounts_monitored);            // Connected Accounts
      s.future_ai_score = StringFormat("%.0f/100 | %s", m_last.fleet_health_score,
                                       m_last.fleet_status);                      // Fleet Health
      s.w_recovery_ai = m_last.cloud_system_status;                               // Cloud System Status
      s.prediction_status = m_last.risk_overview;                                 // Account Risk Overview
      s.learning_status = m_last.performance_map;                                 // Account Performance Map
      s.w_volatility_scanner = m_last.connection_health;                          // Connection Monitoring
      s.w_market_analyzer = m_last.service_availability;                          // AI Service Availability
      s.w_news_analyzer = m_last.enterprise_alerts;                               // Enterprise Alerts
      s.w_trade_confidence = StringFormat("H%d/W%d/C%d",
                                          m_last.healthy_accounts,
                                          m_last.warning_accounts,
                                          m_last.critical_accounts);
      s.ai_version = GmEntRankName(m_last.local_rank);
      s.confidence_status = StringFormat("%.0f", m_last.fleet_health_score);
      s.decision_status = GM_ENT_ADVISORY;
     }
  };

#endif // GM_CAI_ENTERPRISE_MONITORING_ENGINE_MQH
//+------------------------------------------------------------------+
