//+------------------------------------------------------------------+
//|                                    CAIMasterControlEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 4 Sprint 10 — Master Control Center Facade            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_MASTER_CONTROL_ENGINE_MQH
#define GM_CAI_MASTER_CONTROL_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "MasterControlAIConstants.mqh"
#include "SGmMasterControlResult.mqh"
#include "CAIMasterControlCenter.mqh"
#include "CUnifiedAIStatusEngine.mqh"
#include "CAIIntegrationManager.mqh"
#include "CPhase4AuditEngine.mqh"
#include "CAIProductionValidator.mqh"
#include "CAISecurityValidator.mqh"
#include "CAIEnterpriseDatabaseManager.mqh"
#include "CMasterControlDatabase.mqh"
#include "CMasterControlScheduler.mqh"
#include "../Assistant/CAISupervisorEngine.mqh"
#include "../Intelligence/CAIDecisionIntelligenceEngine.mqh"
#include "../Memory/CAILearningMemoryEngine.mqh"
#include "../Reporting/CAIEnterpriseReportingEngine.mqh"
#include "../RiskIntelligence/CAIRiskIntelligenceEngine.mqh"
#include "../Forecasting/CAIForecastingEngine.mqh"
#include "../Conversation/CAIConversationalAssistantEngine.mqh"
#include "../Enterprise/CAIEnterpriseMonitoringEngine.mqh"
#include "../Orchestration/CAIOrchestrationEngine.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../SGmAISnapshot.mqh"

class CGmAIMasterControlEngine
  {
private:
   CGmLogger             *m_logger;
   CGmPhase2Bridge       *m_bridge;
   CGmAISupervisorEngine *m_supervisor;
   CGmAIDecisionIntelligenceEngine *m_intel;
   CGmAILearningMemoryEngine *m_memlearn;
   CGmAIEnterpriseReportingEngine *m_aireport;
   CGmAIRiskIntelligenceEngine *m_riskintel;
   CGmAIForecastingEngine *m_forecast;
   CGmAIConversationalAssistantEngine *m_aichat;
   CGmAIEnterpriseMonitoringEngine *m_entmon;
   CGmAIOrchestrationEngine *m_orch;

   CGmAIMasterControlCenter       m_center;
   CGmUnifiedAIStatusEngine       m_unified;
   CGmAIIntegrationManager        m_integration;
   CGmPhase4AuditEngine           m_audit;
   CGmAIProductionValidator       m_prod;
   CGmAISecurityValidator         m_security;
   CGmAIEnterpriseDatabaseManager m_dbmgr;
   CGmMasterControlDatabase       m_db;
   CGmMasterControlScheduler      m_sched;

   SGmMasterControlResult m_last;
   long                   m_magic;
   bool                   m_ready;

public:
                     CGmAIMasterControlEngine(void)
                       : m_logger(NULL), m_bridge(NULL), m_supervisor(NULL), m_intel(NULL),
                         m_memlearn(NULL), m_aireport(NULL), m_riskintel(NULL),
                         m_forecast(NULL), m_aichat(NULL), m_entmon(NULL), m_orch(NULL),
                         m_magic(0), m_ready(false)
     {
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
         m_logger.Success("AI Master Control Center Started | " + GM_MCC_VERSION +
                          " | " + GM_MCC_ANALYSIS_ONLY, "AIMCC");
         m_logger.Info("POLICY | " + GM_MCC_ADVISORY, "AIMCC");
        }
      return true;
     }

   void BindSources(CGmAISupervisorEngine *supervisor,
                    CGmAIDecisionIntelligenceEngine *intel,
                    CGmAILearningMemoryEngine *memlearn,
                    CGmAIEnterpriseReportingEngine *aireport,
                    CGmAIRiskIntelligenceEngine *riskintel,
                    CGmAIForecastingEngine *forecast,
                    CGmAIConversationalAssistantEngine *aichat,
                    CGmAIEnterpriseMonitoringEngine *entmon,
                    CGmAIOrchestrationEngine *orch)
     {
      m_supervisor = supervisor;
      m_intel = intel;
      m_memlearn = memlearn;
      m_aireport = aireport;
      m_riskintel = riskintel;
      m_forecast = forecast;
      m_aichat = aichat;
      m_entmon = entmon;
      m_orch = orch;
      if(m_logger != NULL)
         m_logger.Info("All AI Modules Connected | Master Control sources bound", "AIMCC");
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmMasterControlResult Last(void) const { return m_last; }

   bool Analyze(void)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      m_sched.Signal();
      if(!m_sched.ShouldRun(now, GM_MCC_THROTTLE_MS))
        {
         if(m_last.valid && m_sched.CacheValid(now))
           {
            m_last.from_cache = true;
            m_last.status = GM_MCC_STATUS_CACHED;
            return true;
           }
         return m_last.valid;
        }

      m_sched.Begin(now);
      if(m_logger != NULL)
         m_logger.Info("Production Validation Started", "AIMCC");

      SGmMasterControlResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.status = GM_MCC_STATUS_RUNNING;
      r.may_execute = false;
      r.may_modify_risk = false;
      r.may_modify_strategy = false;
      r.advisory_status = GM_MCC_ADVISORY;

      if(m_bridge != NULL)
        {
         r.symbol = m_bridge.Symbol();
         r.session_id = m_bridge.SessionId();
        }
      if(StringLen(r.symbol) == 0)
        {
         r.status = GM_MCC_STATUS_ERROR;
         m_sched.Complete(now);
         return false;
        }

      SGmAssistantResult sup;
      SGmIntelligenceResult intel;
      SGmMemoryLearningResult mem;
      SGmReportingResult rpt;
      SGmRiskIntelligenceResult risk;
      SGmForecastResult fcst;
      SGmConversationResult chat;
      SGmEnterpriseResult ent;
      SGmOrchestrationResult orch;
      sup.Reset(); intel.Reset(); mem.Reset(); rpt.Reset();
      risk.Reset(); fcst.Reset(); chat.Reset(); ent.Reset(); orch.Reset();

      if(m_supervisor != NULL && m_supervisor.IsReady()) sup = m_supervisor.Last();
      if(m_intel != NULL && m_intel.IsReady()) intel = m_intel.Last();
      if(m_memlearn != NULL && m_memlearn.IsReady()) mem = m_memlearn.Last();
      if(m_aireport != NULL && m_aireport.IsReady()) rpt = m_aireport.Last();
      if(m_riskintel != NULL && m_riskintel.IsReady()) risk = m_riskintel.Last();
      if(m_forecast != NULL && m_forecast.IsReady()) fcst = m_forecast.Last();
      if(m_aichat != NULL && m_aichat.IsReady()) chat = m_aichat.Last();
      if(m_entmon != NULL && m_entmon.IsReady()) ent = m_entmon.Last();
      if(m_orch != NULL && m_orch.IsReady()) orch = m_orch.Last();

      m_center.Analyze(sup, intel, risk, fcst, mem, orch, ent, rpt, chat, r);
      m_unified.Analyze(sup, mem, rpt, risk, fcst, chat, ent, orch, r);

      m_integration.Analyze(sup.valid, intel.valid, mem.valid, risk.valid, fcst.valid,
                            rpt.valid, chat.valid, ent.valid, orch.valid, r);
      if(m_logger != NULL)
         m_logger.Info("System Integration Completed | connected=" +
                       IntegerToString(r.modules_connected), "AIMCC");

      m_security.Analyze(chat, r);
      if(m_logger != NULL)
         m_logger.Info("Security Validation Completed | " +
                       (r.security_pass ? "PASS" : "FAIL"), "AIMCC");

      m_dbmgr.Analyze(sup.valid, intel.valid, mem.valid, rpt.valid, risk.valid,
                      fcst.valid, chat.valid, ent.valid, orch.valid, r);
      if(m_logger != NULL)
         m_logger.Info("Database Audit Completed | " + r.database_status, "AIMCC");

      m_audit.Analyze(r, r);
      if(m_logger != NULL)
         m_logger.Info("Phase 4 Audit Completed | score=" +
                       DoubleToString(r.audit_score, 0), "AIMCC");

      m_prod.Analyze(r, (m_logger != NULL), r);
      if(m_logger != NULL)
         m_logger.Info("Performance Optimization Completed", "AIMCC");

      r.phase4_status = (r.audit_pass && r.security_pass && r.production_readiness >= 90.0)
                        ? "PHASE 4 COMPLETE"
                        : "PHASE 4 REVIEW";
      r.center_status = "MASTER CONTROL READY";
      r.status = GM_MCC_STATUS_READY;
      r.insight = StringFormat("%s | Health=%.0f Intel=%.0f Prod=%.0f%% %s | %s",
                               r.center_status,
                               r.ai_health_score,
                               r.ai_intelligence,
                               r.production_readiness,
                               r.phase4_status,
                               GM_MCC_ANALYSIS_ONLY);
      r.valid = true;

      m_db.Record(r);
      m_last = r;
      m_sched.Complete(GetTickCount());

      if(m_logger != NULL)
         m_logger.Info("Final AI Status Generated | " + r.phase4_status, "AIMCC");
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = m_last.center_status;
      s.ai_engine = "GoldMind AI Master Control Center";
      s.current_mode = "AI_MASTER_CONTROL";
      s.confidence_pct = m_last.ai_health_score;
      s.confidence_status = StringFormat("%.0f", m_last.production_readiness);

      // AI Operations Center widgets (last-wins)
      s.w_trend_detector = m_last.panel_master;                 // Master AI Status
      s.future_ai_score = m_last.panel_system_health;           // System Health Overview
      s.w_recovery_ai = m_last.panel_market;                    // Market Intelligence
      s.prediction_status = m_last.panel_risk;                  // Risk Intelligence
      s.learning_status = m_last.panel_forecast;                // Forecast Intelligence
      s.w_volatility_scanner = m_last.panel_learning;           // Learning Intelligence
      s.w_market_analyzer = m_last.panel_reports;               // AI Reports
      s.w_news_analyzer = m_last.panel_assistant;               // Assistant Panel
      s.w_trade_confidence = m_last.panel_enterprise;           // Enterprise Monitoring
      s.ai_version = m_last.panel_audit;                        // Audit Trail
      s.decision_status = GM_MCC_ADVISORY;
     }
  };

#endif // GM_CAI_MASTER_CONTROL_ENGINE_MQH
//+------------------------------------------------------------------+
