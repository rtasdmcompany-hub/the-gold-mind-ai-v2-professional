//+------------------------------------------------------------------+
//|                                   CAIOrchestrationEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 4 Sprint 9 — Command Center / Orchestration Facade    |
//+------------------------------------------------------------------+
#ifndef GM_CAI_ORCHESTRATION_ENGINE_MQH
#define GM_CAI_ORCHESTRATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "OrchestrationAIConstants.mqh"
#include "SGmOrchestrationResult.mqh"
#include "CAIKnowledgeOrchestrationEngine.mqh"
#include "CAdvancedDecisionSupportEngine.mqh"
#include "CAIIntelligenceFusionEngine.mqh"
#include "CAIKnowledgePriorityEngine.mqh"
#include "CAIInsightGenerationEngine.mqh"
#include "CAIOrchestrationKnowledgeGraph.mqh"
#include "COrchestrationDatabase.mqh"
#include "COrchestrationScheduler.mqh"
#include "../Intelligence/CAIDecisionIntelligenceEngine.mqh"
#include "../RiskIntelligence/CAIRiskIntelligenceEngine.mqh"
#include "../Forecasting/CAIForecastingEngine.mqh"
#include "../Memory/CAILearningMemoryEngine.mqh"
#include "../Assistant/CAISupervisorEngine.mqh"
#include "../Reporting/CAIEnterpriseReportingEngine.mqh"
#include "../Volatility/CAIVolatilityEngine.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../SGmAISnapshot.mqh"

class CGmAIOrchestrationEngine
  {
private:
   CGmLogger             *m_logger;
   CGmPhase2Bridge       *m_bridge;
   CGmAIDecisionIntelligenceEngine *m_intel;
   CGmAIRiskIntelligenceEngine *m_riskintel;
   CGmAIForecastingEngine *m_forecast;
   CGmAILearningMemoryEngine *m_memlearn;
   CGmAISupervisorEngine *m_supervisor;
   CGmAIEnterpriseReportingEngine *m_aireport;
   CGmAIVolatilityEngine *m_vol;

   CGmAIKnowledgeOrchestrationEngine m_knowledge;
   CGmAdvancedDecisionSupportEngine  m_decision_support;
   CGmAIIntelligenceFusionEngine     m_fusion;
   CGmAIKnowledgePriorityEngine      m_priority;
   CGmAIInsightGenerationEngine      m_insights;
   CGmAIOrchestrationKnowledgeGraph  m_graph;
   CGmOrchestrationDatabase          m_db;
   CGmOrchestrationScheduler         m_sched;

   SGmOrchestrationResult m_last;
   long                   m_magic;
   bool                   m_ready;

public:
                     CGmAIOrchestrationEngine(void)
                       : m_logger(NULL), m_bridge(NULL), m_intel(NULL), m_riskintel(NULL),
                         m_forecast(NULL), m_memlearn(NULL), m_supervisor(NULL),
                         m_aireport(NULL), m_vol(NULL), m_magic(0), m_ready(false)
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
      m_graph.Reset();
      m_last.Reset();
      m_ready = true;
      if(m_logger != NULL)
        {
         m_logger.Success("AI Orchestration Started | " + GM_ORCH_VERSION +
                          " | " + GM_ORCH_ANALYSIS_ONLY, "AIOrch");
         m_logger.Info("POLICY | " + GM_ORCH_ADVISORY, "AIOrch");
        }
      return true;
     }

   void BindSources(CGmAIDecisionIntelligenceEngine *intel,
                    CGmAIRiskIntelligenceEngine *riskintel,
                    CGmAIForecastingEngine *forecast,
                    CGmAILearningMemoryEngine *memlearn,
                    CGmAISupervisorEngine *supervisor,
                    CGmAIEnterpriseReportingEngine *aireport,
                    CGmAIVolatilityEngine *vol = NULL)
     {
      m_intel = intel;
      m_riskintel = riskintel;
      m_forecast = forecast;
      m_memlearn = memlearn;
      m_supervisor = supervisor;
      m_aireport = aireport;
      m_vol = vol;
      if(m_logger != NULL)
         m_logger.Info("Knowledge Sources Connected | Intel+Risk+Forecast+Memory+Supervisor+Report+Vol",
                       "AIOrch");
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmOrchestrationResult Last(void) const { return m_last; }

   bool Analyze(void)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      m_sched.Signal();
      if(!m_sched.ShouldRun(now, GM_ORCH_THROTTLE_MS))
        {
         if(m_last.valid && m_sched.CacheValid(now))
           {
            m_last.from_cache = true;
            m_last.status = GM_ORCH_STATUS_CACHED;
            return true;
           }
         return m_last.valid;
        }

      m_sched.Begin(now);

      SGmOrchestrationResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.status = GM_ORCH_STATUS_RUNNING;
      r.may_execute = false;
      r.may_modify_strategy = false;
      r.may_modify_risk = false;
      r.advisory_status = GM_ORCH_ADVISORY;

      if(m_bridge != NULL)
        {
         r.symbol = m_bridge.Symbol();
         r.session_id = m_bridge.SessionId();
        }
      if(StringLen(r.symbol) == 0)
        {
         r.status = GM_ORCH_STATUS_ERROR;
         m_sched.Complete(now);
         return false;
        }

      SGmIntelligenceResult intel;
      SGmRiskIntelligenceResult risk;
      SGmForecastResult fcst;
      SGmMemoryLearningResult mem;
      SGmAssistantResult sup;
      SGmReportingResult rpt;
      SGmVolatilityAnalysisResult vol;
      intel.Reset(); risk.Reset(); fcst.Reset(); mem.Reset();
      sup.Reset(); rpt.Reset(); vol.Reset();

      if(m_intel != NULL && m_intel.IsReady()) intel = m_intel.Last();
      if(m_riskintel != NULL && m_riskintel.IsReady()) risk = m_riskintel.Last();
      if(m_forecast != NULL && m_forecast.IsReady()) fcst = m_forecast.Last();
      if(m_memlearn != NULL && m_memlearn.IsReady()) mem = m_memlearn.Last();
      if(m_supervisor != NULL && m_supervisor.IsReady()) sup = m_supervisor.Last();
      if(m_aireport != NULL && m_aireport.IsReady()) rpt = m_aireport.Last();
      if(m_vol != NULL && m_vol.IsReady()) vol = m_vol.Last();

      m_knowledge.Analyze(intel, risk, fcst, mem, sup, rpt, r);
      m_fusion.Analyze(intel, risk, fcst, mem, sup, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Intelligence Fusion Completed | %.0f/100 %s",
                                    r.intelligence_score, GmOrchGradeName(r.intelligence_grade)),
                       "AIOrch");

      m_decision_support.Analyze(vol, risk, fcst, intel, mem, r, r);
      if(m_logger != NULL)
         m_logger.Info("Decision Support Generated", "AIOrch");

      m_priority.Analyze(risk, fcst, sup, vol, mem, r);
      if(m_logger != NULL)
         m_logger.Info("Priority Queue Updated | count=" + IntegerToString(r.priority_count),
                       "AIOrch");

      m_insights.Analyze(intel, risk, fcst, mem, sup, rpt, r, r);
      if(m_logger != NULL)
         m_logger.Info("AI Insights Generated", "AIOrch");

      m_graph.Rebuild(intel, risk, fcst, mem, sup, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Knowledge Graph Updated | nodes=%d edges=%d",
                                    r.graph_nodes, r.graph_edges), "AIOrch");

      r.center_status = "COMMAND CENTER READY";
      r.status = GM_ORCH_STATUS_READY;
      r.insight = StringFormat("%s | Intel=%.0f/%s Conf=%.0f%% Pri=%d | %s",
                               r.center_status,
                               r.intelligence_score,
                               GmOrchGradeName(r.intelligence_grade),
                               r.unified_confidence,
                               r.priority_count,
                               GM_ORCH_ANALYSIS_ONLY);
      r.valid = true;

      m_db.Record(r);
      m_last = r;
      m_sched.Complete(GetTickCount());

      if(m_logger != NULL)
         m_logger.Info("Command Center Updated | pending=" +
                       IntegerToString(m_sched.Pending()), "AIOrch");
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = m_last.center_status;
      s.ai_engine = "GoldMind AI Command Center";
      s.current_mode = "AI_COMMAND_CENTER";
      s.confidence_pct = m_last.intelligence_score;
      s.confidence_status = StringFormat("%.0f", m_last.unified_confidence);

      // Enterprise AI Command Center widgets (last-wins)
      s.w_trend_detector = StringFormat("M=%s R=%s L=%s S=%s | Conf=%.0f%%",
                                        m_last.market_status, m_last.risk_status,
                                        m_last.learning_status, m_last.system_status,
                                        m_last.unified_confidence);              // Unified AI Status
      s.future_ai_score = StringFormat("%.0f/100 | %s | %s",
                                       m_last.intelligence_score,
                                       GmOrchGradeName(m_last.intelligence_grade),
                                       m_last.intelligence_status);              // Intelligence Score
      s.w_recovery_ai = m_last.advisory;                                         // Decision Support Panel
      s.prediction_status = (m_last.priority_count > 0 ? m_last.priorities[0] : "—");
      if(m_last.priority_count > 1)
         s.prediction_status += " | " + m_last.priorities[1];                    // Priority Insights
      s.learning_status = m_last.knowledge_network;                              // Knowledge Network
      s.w_volatility_scanner = m_last.market_intel_panel;                        // Market Intelligence
      s.w_market_analyzer = m_last.risk_intel_panel;                             // Risk Intelligence
      s.w_news_analyzer = m_last.forecast_intel_panel;                           // Forecast Intelligence
      s.w_trade_confidence = m_last.learning_intel_panel;                        // Learning Intelligence
      s.ai_version = m_last.primary_insight;
      s.decision_status = GM_ORCH_ADVISORY;
     }
  };

#endif // GM_CAI_ORCHESTRATION_ENGINE_MQH
//+------------------------------------------------------------------+
