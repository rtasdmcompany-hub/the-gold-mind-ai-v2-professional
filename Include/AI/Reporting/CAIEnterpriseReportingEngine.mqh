//+------------------------------------------------------------------+
//|                               CAIEnterpriseReportingEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 4 Sprint 4 — Enterprise Reporting Facade              |
//+------------------------------------------------------------------+
#ifndef GM_CAI_ENTERPRISE_REPORTING_ENGINE_MQH
#define GM_CAI_ENTERPRISE_REPORTING_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ReportingAIConstants.mqh"
#include "SGmReportingResult.mqh"
#include "CAIReportGenerationEngine.mqh"
#include "CExecutiveSummaryEngine.mqh"
#include "CSessionAnalyticsEngine.mqh"
#include "CAIPerformanceScorecard.mqh"
#include "CEnterpriseAnalyticsEngine.mqh"
#include "CAIAuditTrailSystem.mqh"
#include "CReportingDatabase.mqh"
#include "CReportingBatchScheduler.mqh"
#include "../Learning/CAILearningEngine.mqh"
#include "../Assistant/CAISupervisorEngine.mqh"
#include "../Intelligence/CAIDecisionIntelligenceEngine.mqh"
#include "../Memory/CAILearningMemoryEngine.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Analytics/CAnalyticsEngine.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../SGmAISnapshot.mqh"

class CGmAIEnterpriseReportingEngine
  {
private:
   CGmLogger             *m_logger;
   CGmPhase2Bridge       *m_bridge;
   CGmAnalyticsEngine    *m_analytics;
   CGmAILearningEngine   *m_learn;
   CGmAISupervisorEngine *m_supervisor;
   CGmAIDecisionIntelligenceEngine *m_intel;
   CGmAILearningMemoryEngine *m_memlearn;

   CGmAIReportGenerationEngine   m_gen;
   CGmExecutiveSummaryEngine     m_exec;
   CGmSessionAnalyticsEngine     m_session;
   CGmAIPerformanceScorecard     m_score;
   CGmEnterpriseAnalyticsEngine  m_enterprise;
   CGmAIAuditTrailSystem         m_audit;
   CGmReportingDatabase          m_db;
   CGmReportingBatchScheduler    m_sched;

   SGmReportingResult m_last;
   long               m_magic;
   ulong              m_seq;
   bool               m_ready;

public:
                     CGmAIEnterpriseReportingEngine(void)
                       : m_logger(NULL), m_bridge(NULL), m_analytics(NULL),
                         m_learn(NULL), m_supervisor(NULL), m_intel(NULL),
                         m_memlearn(NULL), m_magic(0), m_seq(0), m_ready(false)
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
      m_audit.Init(logger);
      m_db.Init(logger, files, magic, symbol);
      m_sched.Reset();
      m_last.Reset();
      m_ready = true;
      if(m_logger != NULL)
        {
         m_logger.Success("AI Reporting Engine Started | " + GM_RPT_VERSION +
                          " | " + GM_RPT_ANALYSIS_ONLY, "AIRpt");
         m_logger.Info("POLICY | " + GM_RPT_ADVISORY, "AIRpt");
        }
      m_audit.Record("Reporting Engine Initialized");
      return true;
     }

   void BindSources(CGmAILearningEngine *learn,
                    CGmAISupervisorEngine *supervisor,
                    CGmAIDecisionIntelligenceEngine *intel,
                    CGmAILearningMemoryEngine *memlearn)
     {
      m_learn = learn;
      m_supervisor = supervisor;
      m_intel = intel;
      m_memlearn = memlearn;
      if(m_logger != NULL)
         m_logger.Info("Reporting sources bound | Learn+Supervisor+Intel+Memory", "AIRpt");
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmReportingResult Last(void) const { return m_last; }

   bool Analyze(void)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      m_sched.Signal();
      if(!m_sched.ShouldRun(now, GM_RPT_THROTTLE_MS))
        {
         if(m_last.valid && m_sched.CacheValid(now))
           {
            m_last.from_cache = true;
            m_last.status = GM_RPT_STATUS_CACHED;
            return true;
           }
         return m_last.valid;
        }

      m_sched.Begin(now);
      if(m_logger != NULL)
         m_logger.Info("Report Generation Started", "AIRpt");
      m_audit.Record("Analysis Generated");

      SGmReportingResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.status = GM_RPT_STATUS_RUNNING;
      r.may_execute = false;
      r.may_modify_strategy = false;
      r.advisory_status = GM_RPT_ADVISORY;
      r.from_cache = false;
      m_seq++;
      r.report_id = StringFormat("RPT-%I64d-%I64u", m_magic, m_seq);

      if(m_bridge != NULL)
        {
         r.symbol = m_bridge.Symbol();
         r.session_id = m_bridge.SessionId();
        }
      if(StringLen(r.symbol) == 0)
        {
         r.status = GM_RPT_STATUS_ERROR;
         m_sched.Complete(now);
         return false;
        }

      SGmLearningAnalysisResult learn;
      SGmAssistantResult sup;
      SGmIntelligenceResult intel;
      SGmMemoryLearningResult mem;
      learn.Reset(); sup.Reset(); intel.Reset(); mem.Reset();
      if(m_learn != NULL && m_learn.IsReady()) learn = m_learn.Last();
      if(m_supervisor != NULL && m_supervisor.IsReady()) sup = m_supervisor.Last();
      if(m_intel != NULL && m_intel.IsReady()) intel = m_intel.Last();
      if(m_memlearn != NULL && m_memlearn.IsReady()) mem = m_memlearn.Last();

      m_gen.Analyze(intel, sup, mem, r);
      m_exec.Analyze(intel, sup, mem, r);
      if(m_logger != NULL)
         m_logger.Info("Executive Summary Generated", "AIRpt");
      m_audit.Record("Report Created");

      m_session.Analyze(m_bridge, m_analytics, intel, sup, r);
      if(m_logger != NULL)
         m_logger.Info("Session Report Created | SID=" + IntegerToString((int)r.session_id), "AIRpt");

      m_score.Analyze(intel, mem, sup, learn, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Performance Score Updated | %.0f/%s",
                                    r.performance_score, GmRptGradeName(r.performance_grade)),
                       "AIRpt");

      m_enterprise.Analyze(m_analytics, intel, mem, sup, r, r);
      if(m_logger != NULL)
         m_logger.Info("Analytics Report Completed", "AIRpt");

      if(sup.valid && sup.warning_count > 0)
         m_audit.Record("Warning Issued | " + sup.warning_center);
      if(mem.valid)
         m_audit.Record("Learning Updated");
      if(mem.valid && mem.patterns_discovered > 0)
         m_audit.Record("Pattern Discovered");
      m_audit.Record(StringFormat("Confidence Changed | %.0f", r.exec_confidence));

      r.audit_events = m_audit.Count();
      r.audit_history = m_audit.History();
      r.reporting_status = "REPORT READY";
      r.status = GM_RPT_STATUS_READY;
      r.insight = StringFormat("%s | %s | Score=%.0f/%s | %s",
                               r.reporting_status,
                               r.latest_report_headline,
                               r.performance_score,
                               GmRptGradeName(r.performance_grade),
                               GM_RPT_ANALYSIS_ONLY);
      r.valid = true;

      m_db.Record(r, m_audit);
      m_last = r;
      m_sched.Complete(GetTickCount());

      if(m_logger != NULL)
         m_logger.Info("Dashboard Reporting Updated | pending=" +
                       IntegerToString(m_sched.Pending()), "AIRpt");
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = m_last.reporting_status;
      s.ai_engine = "GoldMind AI Reporting";
      s.current_mode = "AI_REPORTING";
      s.confidence_pct = m_last.exec_confidence;
      s.confidence_status = StringFormat("%.0f%%", m_last.exec_confidence);

      // Reporting Center widgets (last-wins)
      s.w_trend_detector = m_last.latest_report_headline;                         // Latest AI Report
      s.future_ai_score = StringFormat("%s/%s", m_last.market_condition_label,
                                       m_last.risk_level_label);                  // Executive Summary
      s.w_recovery_ai = m_last.session_outcome;                                   // Session Intelligence
      s.prediction_status = StringFormat("%.0f/%s", m_last.performance_score,
                                         GmRptGradeName(m_last.performance_grade)); // Scorecard
      s.learning_status = m_last.monthly_intelligence;                            // Monthly Intelligence
      s.w_volatility_scanner = m_last.risk_evolution;                             // Risk Evolution
      s.w_market_analyzer = m_last.accuracy_trend;                                // AI Accuracy Trend
      s.w_news_analyzer = m_last.learning_growth;                                 // Learning Growth
      s.w_trade_confidence = m_last.audit_history;                                // Audit History
      s.ai_version = GmRptGradeName(m_last.performance_grade);
      s.decision_status = GM_RPT_ADVISORY;
     }
  };

#endif // GM_CAI_ENTERPRISE_REPORTING_ENGINE_MQH
//+------------------------------------------------------------------+
