//+------------------------------------------------------------------+
//|                                 CAILearningMemoryEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 4 Sprint 3 — Learning Memory Facade (NON-EXECUTION)   |
//+------------------------------------------------------------------+
#ifndef GM_CAI_LEARNING_MEMORY_ENGINE_MQH
#define GM_CAI_LEARNING_MEMORY_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "MemoryAIConstants.mqh"
#include "SGmMemoryLearningResult.mqh"
#include "CAIMemoryEngine.mqh"
#include "CAdaptiveLearningEngine.mqh"
#include "CMarketBehaviorLearningEngine.mqh"
#include "CAIPatternDiscoveryEngine.mqh"
#include "CConfidenceCalibrationEngine.mqh"
#include "CAIKnowledgeGraph.mqh"
#include "CLearningMemoryDatabase.mqh"
#include "CLearningBatchScheduler.mqh"
#include "../Trend/CAITrendEngine.mqh"
#include "../Volatility/CAIVolatilityEngine.mqh"
#include "../News/CAINewsEngine.mqh"
#include "../Learning/CAILearningEngine.mqh"
#include "../Assistant/CAISupervisorEngine.mqh"
#include "../Intelligence/CAIDecisionIntelligenceEngine.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Analytics/CAnalyticsEngine.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../SGmAISnapshot.mqh"

/// @brief Enterprise AI Learning Memory Layer — OBSERVE / LEARN / ADVISE / REPORT.
class CGmAILearningMemoryEngine
  {
private:
   CGmLogger             *m_logger;
   CGmPhase2Bridge       *m_bridge;
   CGmAnalyticsEngine    *m_analytics;
   CGmAITrendEngine      *m_trend;
   CGmAIVolatilityEngine *m_vol;
   CGmAINewsEngine       *m_news;
   CGmAILearningEngine   *m_learn;
   CGmAISupervisorEngine *m_supervisor;
   CGmAIDecisionIntelligenceEngine *m_intel;

   CGmAIMemoryEngine                 m_memory;
   CGmAdaptiveLearningEngine         m_adaptive;
   CGmMarketBehaviorLearningEngine   m_behavior;
   CGmAIPatternDiscoveryEngine       m_patterns;
   CGmConfidenceCalibrationEngine    m_calib;
   CGmAIKnowledgeGraph               m_graph;
   CGmLearningMemoryDatabase         m_db;
   CGmLearningBatchScheduler         m_sched;

   SGmMemoryLearningResult m_last;
   long                    m_magic;
   bool                    m_ready;

public:
                     CGmAILearningMemoryEngine(void)
                       : m_logger(NULL), m_bridge(NULL), m_analytics(NULL),
                         m_trend(NULL), m_vol(NULL), m_news(NULL), m_learn(NULL),
                         m_supervisor(NULL), m_intel(NULL), m_magic(0), m_ready(false)
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
      m_graph.RebuildFoundation();
      m_sched.Reset();
      m_last.Reset();
      m_ready = true;
      if(m_logger != NULL)
        {
         m_logger.Success("AI Memory Engine Started | " + GM_MEM_VERSION +
                          " | " + GM_MEM_ANALYSIS_ONLY, "AIMem");
         m_logger.Info("POLICY | " + GM_MEM_ADVISORY, "AIMem");
         m_logger.Info("Knowledge Graph Updated | " + m_graph.Status(), "AIMem");
        }
      return true;
     }

   void BindSources(CGmAITrendEngine *trend,
                    CGmAIVolatilityEngine *vol,
                    CGmAINewsEngine *news,
                    CGmAILearningEngine *learn,
                    CGmAISupervisorEngine *supervisor,
                    CGmAIDecisionIntelligenceEngine *intel)
     {
      m_trend = trend;
      m_vol = vol;
      m_news = news;
      m_learn = learn;
      m_supervisor = supervisor;
      m_intel = intel;
      if(m_logger != NULL)
         m_logger.Info("Memory sources bound | Trend+Vol+News+Learn+Supervisor+Intel",
                       "AIMem");
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmMemoryLearningResult Last(void) const { return m_last; }
   CGmAIKnowledgeGraph *KnowledgeGraph(void) { return GetPointer(m_graph); }

   bool Analyze(void)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      m_sched.Signal();
      if(!m_sched.ShouldRun(now, GM_MEM_THROTTLE_MS))
        {
         if(m_last.valid && m_sched.CacheValid(now))
           {
            m_last.from_cache = true;
            m_last.status = GM_MEM_STATUS_CACHED;
            return true;
           }
         return m_last.valid;
        }

      m_sched.Begin(now);
      if(m_logger != NULL)
         m_logger.Info("Learning Cycle Started", "AIMem");

      SGmMemoryLearningResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.status = GM_MEM_STATUS_RUNNING;
      r.may_execute = false;
      r.may_modify_strategy = false;
      r.advisory_status = GM_MEM_ADVISORY;
      r.from_cache = false;

      if(m_bridge != NULL)
        {
         r.symbol = m_bridge.Symbol();
         r.session_id = m_bridge.SessionId();
        }
      if(StringLen(r.symbol) == 0)
        {
         r.status = GM_MEM_STATUS_ERROR;
         m_sched.Complete(now);
         if(m_logger != NULL)
            m_logger.Warning("Memory cycle aborted | no symbol", "AIMem");
         return false;
        }

      SGmTrendAnalysisResult trend;
      SGmVolatilityAnalysisResult vol;
      SGmNewsAnalysisResult news;
      SGmLearningAnalysisResult learn;
      SGmAssistantResult sup;
      SGmIntelligenceResult intel;
      trend.Reset(); vol.Reset(); news.Reset(); learn.Reset();
      sup.Reset(); intel.Reset();
      if(m_trend != NULL && m_trend.IsReady()) trend = m_trend.Last();
      if(m_vol != NULL && m_vol.IsReady()) vol = m_vol.Last();
      if(m_news != NULL && m_news.IsReady()) news = m_news.Last();
      if(m_learn != NULL && m_learn.IsReady()) learn = m_learn.Last();
      if(m_supervisor != NULL && m_supervisor.IsReady()) sup = m_supervisor.Last();
      if(m_intel != NULL && m_intel.IsReady()) intel = m_intel.Last();

      if(m_logger != NULL)
         m_logger.Info("Historical Data Processed | sessions/patterns ingest", "AIMem");

      m_memory.Analyze(m_analytics, intel, sup, learn, r);
      m_adaptive.Analyze(m_analytics, intel, sup, learn, r);
      m_behavior.Analyze(intel, sup, news, trend, vol, r);
      m_patterns.Analyze(intel, sup, learn, r, r);
      if(m_logger != NULL)
         m_logger.Info("Pattern Discovery Completed | " + r.pattern_report, "AIMem");

      m_calib.Analyze(intel, sup, r, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Confidence Calibration Updated | %.0f -> %.0f | %s",
                                    r.previous_confidence, r.calibrated_confidence,
                                    r.calibration_reason), "AIMem");

      m_graph.RebuildFoundation();
      r.graph_nodes = m_graph.NodeCount();
      r.graph_relationships = m_graph.EdgeCount();
      r.graph_status = m_graph.Status();
      if(m_logger != NULL)
         m_logger.Info("Knowledge Graph Updated | " + r.graph_status, "AIMem");

      r.knowledge_growth = GmMemClamp(
                              35.0 + MathMin(40.0, (double)r.market_patterns_stored * 0.05) +
                              MathMin(25.0, r.confidence_improvement_pct));
      r.historical_intelligence = GmMemClamp(
                                     0.5 * r.learning_accuracy +
                                     0.3 * r.behavior_match_pct +
                                     0.2 * (r.top_pattern.active ? r.top_pattern.success_rate : 50.0));
      r.improvement_score = GmMemClamp(
                               50.0 + r.analysis_improvement_pct * 2.0 +
                               r.confidence_improvement_pct * 0.4);

      r.memory_status = "MEMORY READY";
      r.status = GM_MEM_STATUS_READY;
      r.insight = StringFormat("%s | Acc=%.0f Cal=%.0f Beh=%s Improve=%.0f | %s",
                               r.memory_status,
                               r.learning_accuracy,
                               r.calibrated_confidence,
                               r.behavior_label,
                               r.improvement_score,
                               GM_MEM_ANALYSIS_ONLY);
      r.valid = true;

      m_db.Record(r, m_graph);
      m_last = r;
      m_sched.Complete(GetTickCount());

      if(m_logger != NULL)
        {
         m_logger.Info("Learning Report Generated | " + r.learning_report, "AIMem");
         m_logger.Info("Dashboard Learning Updated | pending=" +
                       IntegerToString(m_sched.Pending()), "AIMem");
        }
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = m_last.memory_status;
      s.ai_engine = "GoldMind AI Learning Memory";
      s.current_mode = "AI_LEARNING_MEMORY";
      s.confidence_pct = m_last.calibrated_confidence;
      s.confidence_status = StringFormat("%.0f%%", m_last.calibrated_confidence);

      // Learning Center widgets (last-wins)
      s.w_trend_detector = m_last.memory_status;                                  // AI Memory Status
      s.future_ai_score = StringFormat("%.0f%%", m_last.learning_accuracy);       // Learning Accuracy
      s.w_recovery_ai = StringFormat("%d", m_last.patterns_discovered);           // Pattern Discovery
      s.prediction_status = m_last.behavior_label;                                // Market Behavior Map
      s.learning_status = StringFormat("%.0f->%.0f",
                                       m_last.previous_confidence,
                                       m_last.calibrated_confidence);             // Confidence Calibration
      s.w_volatility_scanner = StringFormat("%.0f", m_last.knowledge_growth);     // Knowledge Growth
      s.w_market_analyzer = StringFormat("%.0f", m_last.historical_intelligence); // Historical Intelligence
      s.w_news_analyzer = StringFormat("%.0f", m_last.improvement_score);         // AI Improvement Score
      s.w_trade_confidence = m_last.pattern_report;                               // Pattern detail
      s.ai_version = StringFormat("+%.0f%%", m_last.confidence_improvement_pct);
      s.decision_status = GM_MEM_ADVISORY;
      if(m_vol != NULL && m_vol.IsReady() && m_vol.Last().valid)
         s.atr14 = m_vol.Last().atr14;
     }
  };

#endif // GM_CAI_LEARNING_MEMORY_ENGINE_MQH
//+------------------------------------------------------------------+
