//+------------------------------------------------------------------+
//|                        CAIExecutionSupervisorEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 5 Sprint 8 — Execution Supervisor Facade              |
//+------------------------------------------------------------------+
#ifndef GM_CAI_EXECUTION_SUPERVISOR_ENGINE_MQH
#define GM_CAI_EXECUTION_SUPERVISOR_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ExecutionSupervisorConstants.mqh"
#include "SGmExecutionSupervisorResult.mqh"
#include "CAIExecutionSupervisor.mqh"
#include "CTradeLifecycleEngine.mqh"
#include "CRealtimeDecisionMonitor.mqh"
#include "CTradeQualityValidator.mqh"
#include "CAIAlertCenter.mqh"
#include "CFutureExecutionSupervisorInterfaces.mqh"
#include "CExecutionSupervisorDatabase.mqh"
#include "CExecutionSupervisorScheduler.mqh"
#include "../Assistant/CAISupervisorEngine.mqh"
#include "../Trend/CAITrendEngine.mqh"
#include "../Volatility/CAIVolatilityEngine.mqh"
#include "../OrderFlow/CAIOrderFlowIntelligenceEngine.mqh"
#include "../NewsIntelligence/CAINewsIntelligenceEngine.mqh"
#include "../RecoveryIntelligence/CAIRecoveryIntelligenceEngine.mqh"
#include "../../Analytics/CAnalyticsEngine.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../SGmAISnapshot.mqh"

class CGmAIExecutionSupervisorEngine
  {
private:
   CGmLogger             *m_logger;
   CGmPhase2Bridge       *m_bridge;
   CGmAnalyticsEngine    *m_analytics;
   CGmAISupervisorEngine *m_supervisor;
   CGmAITrendEngine      *m_trend;
   CGmAIVolatilityEngine *m_vol;
   CGmAIOrderFlowIntelligenceEngine *m_orderflow;
   CGmAINewsIntelligenceEngine *m_newsintel;
   CGmAIRecoveryIntelligenceEngine *m_recintel;

   CGmAIExecutionSupervisor            m_core;
   CGmTradeLifecycleEngine             m_lifecycle;
   CGmRealtimeDecisionMonitor          m_decision;
   CGmTradeQualityValidator            m_quality;
   CGmAIAlertCenter                    m_alerts;
   CGmFutureExecutionSupervisorLayer   m_future;
   CGmExecutionSupervisorDatabase      m_db;
   CGmExecutionSupervisorScheduler     m_sched;

   SGmExecutionSupervisorResult m_last;
   long                         m_magic;
   bool                         m_ready;

   string BuildSummary(const SGmExecutionSupervisorResult &r) const
     {
      return StringFormat("%s | Health=%.0f Quality=%s(%.0f) Dec=%.0f Env=%.0f | %s | %s",
                          r.lifecycle_status,
                          r.execution_health_score,
                          GmEsGradeName(r.trade_quality_grade),
                          r.trade_quality_score,
                          r.decision_stability_score,
                          r.environment_stability_score,
                          r.latest_alert,
                          GM_ES_ADVISORY);
     }

public:
                     CGmAIExecutionSupervisorEngine(void)
                       : m_logger(NULL), m_bridge(NULL), m_analytics(NULL),
                         m_supervisor(NULL), m_trend(NULL), m_vol(NULL),
                         m_orderflow(NULL), m_newsintel(NULL), m_recintel(NULL),
                         m_magic(0), m_ready(false)
     {
      m_last.Reset();
     }

   bool Init(CGmLogger *logger,
             CGmFileManager *files,
             CGmPhase2Bridge *bridge,
             CGmAnalyticsEngine *analytics,
             const long magic,
             const string symbol)
     {
      m_logger = logger;
      m_bridge = bridge;
      m_analytics = analytics;
      m_magic = magic;
      m_db.Init(logger, files, magic, symbol);
      m_sched.Reset();
      m_last.Reset();
      m_ready = true;
      if(m_logger != NULL)
        {
         m_logger.Success("Execution Supervisor Started | " + GM_ES_VERSION +
                          " | " + GM_ES_ANALYSIS_ONLY, "AIES");
         m_logger.Info("POLICY | " + GM_ES_ADVISORY, "AIES");
         m_logger.Info("CONTEXT | " + GM_ES_CONTEXT, "AIES");
         m_logger.Info(m_future.Banner(), "AIES");
        }
      return true;
     }

   void BindSources(CGmAISupervisorEngine *supervisor,
                    CGmAITrendEngine *trend,
                    CGmAIVolatilityEngine *vol,
                    CGmAIOrderFlowIntelligenceEngine *orderflow,
                    CGmAINewsIntelligenceEngine *newsintel,
                    CGmAIRecoveryIntelligenceEngine *recintel)
     {
      m_supervisor = supervisor;
      m_trend = trend;
      m_vol = vol;
      m_orderflow = orderflow;
      m_newsintel = newsintel;
      m_recintel = recintel;
      if(m_logger != NULL)
         m_logger.Info("Execution Supervisor sources bound | Assist+Trend+Vol+OF+News+Rec", "AIES");
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmExecutionSupervisorResult Last(void) const { return m_last; }
   CGmFutureExecutionSupervisorLayer *FutureLayer(void) { return GetPointer(m_future); }

   bool Analyze(void)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      m_sched.Signal();
      if(!m_sched.ShouldRun(now, GM_ES_THROTTLE_MS))
        {
         if(m_last.valid && m_sched.CacheValid(now))
           {
            m_last.from_cache = true;
            m_last.status = GM_ES_STATUS_CACHED;
            return true;
           }
         return m_last.valid;
        }

      m_sched.Begin(now);

      SGmExecutionSupervisorResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.status = GM_ES_STATUS_RUNNING;
      r.may_execute = false;
      r.may_modify_risk = false;
      r.advisory_status = GM_ES_ADVISORY;

      if(m_bridge != NULL)
        {
         r.symbol = m_bridge.Symbol();
         r.session_id = m_bridge.SessionId();
        }
      if(StringLen(r.symbol) == 0)
        {
         r.status = GM_ES_STATUS_ERROR;
         m_sched.Complete(now);
         return false;
        }

      SGmAssistantResult sup;
      SGmAnalyticsSnapshot a;
      SGmTrendAnalysisResult trend;
      SGmVolatilityAnalysisResult vol;
      SGmOrderFlowResult of;
      SGmNewsIntelligenceResult ni;
      SGmRecoveryIntelligenceResult ri;
      sup.Reset(); a.Reset(); trend.Reset(); vol.Reset();
      of.Reset(); ni.Reset(); ri.Reset();

      if(m_supervisor != NULL && m_supervisor.IsReady()) sup = m_supervisor.Last();
      if(m_analytics != NULL) a = m_analytics.Snapshot();
      if(m_trend != NULL && m_trend.IsReady()) trend = m_trend.Last();
      if(m_vol != NULL && m_vol.IsReady()) vol = m_vol.Last();
      if(m_orderflow != NULL && m_orderflow.IsReady()) of = m_orderflow.Last();
      if(m_newsintel != NULL && m_newsintel.IsReady()) ni = m_newsintel.Last();
      if(m_recintel != NULL && m_recintel.IsReady()) ri = m_recintel.Last();

      const int own_pos = (m_bridge != NULL) ? m_bridge.OwnPositions() : 0;
      const int own_pend = (m_bridge != NULL) ? m_bridge.OwnPendings() : 0;

      m_core.Analyze(sup, a, own_pos, own_pend, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Trade Lifecycle Started | Health=%.0f Pending=%d Active=%d",
                                    r.execution_health_score, r.pending_orders, r.active_trades), "AIES");

      m_lifecycle.Analyze(sup, a, r);
      if(m_logger != NULL)
        {
         if(r.lifecycle_stage == GM_ES_STAGE_ACTIVATED)
            m_logger.Info("Pending Order Activated | " + r.lifecycle_status, "AIES");
         else if(r.lifecycle_stage == GM_ES_STAGE_BREAK_EVEN)
            m_logger.Info("Break Even Activated", "AIES");
         else if(r.lifecycle_stage == GM_ES_STAGE_PARTIAL)
            m_logger.Info("Partial Close Executed (observed)", "AIES");
         else if(r.lifecycle_stage == GM_ES_STAGE_TRAILING)
            m_logger.Info("Trailing Updated (observed)", "AIES");
         else if(r.lifecycle_stage == GM_ES_STAGE_RECOVERY)
            m_logger.Info("Recovery Activated (observed)", "AIES");
         else if(r.lifecycle_stage == GM_ES_STAGE_CLOSED)
            m_logger.Info("Trade Closed (observed)", "AIES");
        }

      m_decision.Analyze(trend, vol, of, ni, sup, r);
      m_quality.Analyze(sup, a, ri, r);
      m_alerts.Analyze(sup, of, r);

      r.ai_supervisor_status = "EXECUTION SUPERVISOR READY";
      r.ai_supervisor_summary = BuildSummary(r);
      r.center_status = r.ai_supervisor_status;
      r.status = GM_ES_STATUS_READY;
      r.insight = StringFormat("%s | %s Health=%.0f Grade=%s Dec=%.0f | %s",
                               r.center_status,
                               r.lifecycle_status,
                               r.execution_health_score,
                               GmEsGradeName(r.trade_quality_grade),
                               r.decision_stability_score,
                               GM_ES_ADVISORY);
      r.valid = true;

      m_db.Record(r);
      m_last = r;
      m_sched.Complete(GetTickCount());

      if(m_logger != NULL)
         m_logger.Info("Dashboard Updated | Execution Supervisor pending=" +
                       IntegerToString(m_sched.Pending()), "AIES");
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = m_last.center_status;
      s.ai_engine = "GoldMind AI Execution Supervisor";
      s.current_mode = "AI_EXECUTION_SUPERVISOR";
      s.confidence_pct = m_last.execution_health_score;
      s.confidence_status = StringFormat("%.0f", m_last.execution_health_score);

      // Phase 5 Sprint 8 widgets (last-wins)
      s.w_trend_detector = StringFormat("%.0f", m_last.execution_health_score);      // Execution Health
      s.future_ai_score = m_last.lifecycle_status;                                   // Trade Lifecycle
      s.w_recovery_ai = StringFormat("%.0f", m_last.decision_stability_score);       // Decision Stability
      s.prediction_status = StringFormat("%.0f", m_last.environment_stability_score); // Environment Stability
      s.learning_status = StringFormat("%s %.0f",
                                       GmEsGradeName(m_last.trade_quality_grade),
                                       m_last.trade_quality_score);                  // Trade Quality
      s.w_volatility_scanner = m_last.execution_timeline;                            // Execution Timeline
      s.w_market_analyzer = m_last.alert_center;                                     // Real-Time Alerts
      s.w_news_analyzer = StringFormat("%.0fs", m_last.trade_duration_sec);           // Trade Duration
      s.w_trade_confidence = m_last.recovery_timeline;                               // Recovery Timeline
      s.ai_version = m_last.ai_supervisor_summary;                                   // AI Supervisor Summary
      s.decision_status = GM_ES_ADVISORY;
     }
  };

#endif // GM_CAI_EXECUTION_SUPERVISOR_ENGINE_MQH
//+------------------------------------------------------------------+
