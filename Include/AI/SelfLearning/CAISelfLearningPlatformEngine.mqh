//+------------------------------------------------------------------+
//|                             CAISelfLearningPlatformEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 5 Sprint 9 — Self-Learning / Knowledge Evolution      |
//+------------------------------------------------------------------+
#ifndef GM_CAI_SELF_LEARNING_PLATFORM_ENGINE_MQH
#define GM_CAI_SELF_LEARNING_PLATFORM_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SelfLearningConstants.mqh"
#include "SGmSelfLearningResult.mqh"
#include "CAISelfLearningCore.mqh"
#include "CKnowledgeEvolutionEngine.mqh"
#include "CAIRecommendationEngineSL.mqh"
#include "CEnterpriseOptimizationAnalyzer.mqh"
#include "CLearningValidationEngine.mqh"
#include "CFutureSelfLearningInterfaces.mqh"
#include "CSelfLearningDatabase.mqh"
#include "CSelfLearningScheduler.mqh"
#include "../Learning/CAILearningEngine.mqh"
#include "../Memory/CAILearningMemoryEngine.mqh"
#include "../Assistant/CAISupervisorEngine.mqh"
#include "../OrderFlow/CAIOrderFlowIntelligenceEngine.mqh"
#include "../NewsIntelligence/CAINewsIntelligenceEngine.mqh"
#include "../RecoveryIntelligence/CAIRecoveryIntelligenceEngine.mqh"
#include "../PredictiveIntelligence/CAIPredictiveIntelligenceEngine.mqh"
#include "../ExecutionSupervisor/CAIExecutionSupervisorEngine.mqh"
#include "../AIValidation/CAIValidationEngine.mqh"
#include "../../Analytics/CAnalyticsEngine.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../SGmAISnapshot.mqh"

class CGmAISelfLearningPlatformEngine
  {
private:
   CGmLogger             *m_logger;
   CGmPhase2Bridge       *m_bridge;
   CGmAnalyticsEngine    *m_analytics;
   CGmAILearningEngine   *m_learn;
   CGmAILearningMemoryEngine *m_memlearn;
   CGmAISupervisorEngine *m_supervisor;
   CGmAIOrderFlowIntelligenceEngine *m_orderflow;
   CGmAINewsIntelligenceEngine *m_newsintel;
   CGmAIRecoveryIntelligenceEngine *m_recintel;
   CGmAIPredictiveIntelligenceEngine *m_predintel;
   CGmAIExecutionSupervisorEngine *m_execsup;
   CGmAIValidationEngine *m_aival;

   CGmAISelfLearningCore              m_core;
   CGmKnowledgeEvolutionEngine        m_knowledge;
   CGmAIRecommendationEngineSL        m_recommend;
   CGmEnterpriseOptimizationAnalyzer  m_optimize;
   CGmLearningValidationEngine        m_validate;
   CGmFutureSelfLearningLayer         m_future;
   CGmSelfLearningDatabase            m_db;
   CGmSelfLearningScheduler           m_sched;

   SGmSelfLearningResult m_last;
   long                  m_magic;
   bool                  m_ready;

   string BuildSummary(const SGmSelfLearningResult &r) const
     {
      return StringFormat("%s | Conf=%.0f Idx=%.0f Growth=%.0f Stab=%.0f Opt=%.0f Cert=%s | %s",
                          r.ai_evolution_status,
                          r.learning_confidence, r.knowledge_index,
                          r.knowledge_growth, r.learning_stability,
                          r.optimization_score, GmSlCertName(r.learning_certification),
                          GM_SL_ADVISORY);
     }

public:
                     CGmAISelfLearningPlatformEngine(void)
                       : m_logger(NULL), m_bridge(NULL), m_analytics(NULL),
                         m_learn(NULL), m_memlearn(NULL), m_supervisor(NULL),
                         m_orderflow(NULL), m_newsintel(NULL), m_recintel(NULL),
                         m_predintel(NULL), m_execsup(NULL), m_aival(NULL),
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
         m_logger.Success("Self-Learning Platform Started | " + GM_SL_VERSION +
                          " | " + GM_SL_ANALYSIS_ONLY, "AISL");
         m_logger.Info("POLICY | " + GM_SL_ADVISORY, "AISL");
         m_logger.Info("CONTEXT | " + GM_SL_CONTEXT, "AISL");
         m_logger.Info(m_future.Banner(), "AISL");
        }
      return true;
     }

   void BindSources(CGmAILearningEngine *learn,
                    CGmAILearningMemoryEngine *memlearn,
                    CGmAISupervisorEngine *supervisor,
                    CGmAIOrderFlowIntelligenceEngine *orderflow,
                    CGmAINewsIntelligenceEngine *newsintel,
                    CGmAIRecoveryIntelligenceEngine *recintel,
                    CGmAIPredictiveIntelligenceEngine *predintel,
                    CGmAIExecutionSupervisorEngine *execsup,
                    CGmAIValidationEngine *aival)
     {
      m_learn = learn;
      m_memlearn = memlearn;
      m_supervisor = supervisor;
      m_orderflow = orderflow;
      m_newsintel = newsintel;
      m_recintel = recintel;
      m_predintel = predintel;
      m_execsup = execsup;
      m_aival = aival;
      if(m_logger != NULL)
         m_logger.Info("Self-Learning sources bound | Learn+Mem+Assist+OF+News+Rec+Pred+Exec+Val", "AISL");
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmSelfLearningResult Last(void) const { return m_last; }
   CGmFutureSelfLearningLayer *FutureLayer(void) { return GetPointer(m_future); }

   bool Analyze(void)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      m_sched.Signal();
      if(!m_sched.ShouldRun(now, GM_SL_THROTTLE_MS))
        {
         if(m_last.valid && m_sched.CacheValid(now))
           {
            m_last.from_cache = true;
            m_last.status = GM_SL_STATUS_CACHED;
            return true;
           }
         return m_last.valid;
        }

      m_sched.Begin(now);

      SGmSelfLearningResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.status = GM_SL_STATUS_RUNNING;
      r.may_execute = false;
      r.may_modify_strategy = false;
      r.may_modify_risk = false;
      r.advisory_status = GM_SL_ADVISORY;

      if(m_bridge != NULL)
        {
         r.symbol = m_bridge.Symbol();
         r.session_id = m_bridge.SessionId();
        }
      if(StringLen(r.symbol) == 0)
        {
         r.status = GM_SL_STATUS_ERROR;
         m_sched.Complete(now);
         return false;
        }

      SGmAnalyticsSnapshot a;
      SGmLearningAnalysisResult learn;
      SGmMemoryLearningResult mem;
      SGmAssistantResult sup;
      SGmOrderFlowResult of;
      SGmNewsIntelligenceResult ni;
      SGmRecoveryIntelligenceResult ri;
      SGmPredictiveIntelligenceResult pred;
      SGmExecutionSupervisorResult es;
      SGmAIValidationResult aival;
      a.Reset(); learn.Reset(); mem.Reset(); sup.Reset();
      of.Reset(); ni.Reset(); ri.Reset(); pred.Reset();
      es.Reset(); aival.Reset();

      if(m_analytics != NULL) a = m_analytics.Snapshot();
      if(m_learn != NULL && m_learn.IsReady()) learn = m_learn.Last();
      if(m_memlearn != NULL && m_memlearn.IsReady()) mem = m_memlearn.Last();
      if(m_supervisor != NULL && m_supervisor.IsReady()) sup = m_supervisor.Last();
      if(m_orderflow != NULL && m_orderflow.IsReady()) of = m_orderflow.Last();
      if(m_newsintel != NULL && m_newsintel.IsReady()) ni = m_newsintel.Last();
      if(m_recintel != NULL && m_recintel.IsReady()) ri = m_recintel.Last();
      if(m_predintel != NULL && m_predintel.IsReady()) pred = m_predintel.Last();
      if(m_execsup != NULL && m_execsup.IsReady()) es = m_execsup.Last();
      if(m_aival != NULL && m_aival.IsReady()) aival = m_aival.Last();

      m_core.Analyze(a, learn, mem, sup, es, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Learning Cycle Completed | Conf=%.0f Growth=%.0f Stab=%.0f",
                                    r.learning_confidence, r.knowledge_growth, r.learning_stability), "AISL");

      m_knowledge.Analyze(a, learn, mem, ri, of, pred, r);
      if(m_logger != NULL)
        {
         m_logger.Info(StringFormat("Knowledge Updated | Index=%.0f Quality=%.0f",
                                    r.knowledge_index, r.knowledge_quality), "AISL");
         if(r.patterns_discovered > 0)
            m_logger.Info("Pattern Discovered | " + r.pattern_library, "AISL");
        }

      m_recommend.Analyze(sup, of, ri, pred, ni, r);
      if(m_logger != NULL)
         m_logger.Info("Recommendation Generated | " + r.recommendation_center, "AISL");

      m_optimize.Analyze(a, sup, es, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Optimization Completed | Score=%.0f Eff=%.0f",
                                    r.optimization_score, r.system_efficiency_rating), "AISL");

      m_validate.Analyze(a, learn, mem, pred, aival, r);

      r.ai_evolution_status = "SELF-LEARNING PLATFORM READY";
      r.ai_evolution_summary = BuildSummary(r);
      r.center_status = r.ai_evolution_status;
      r.status = GM_SL_STATUS_READY;
      r.insight = StringFormat("%s | Conf=%.0f Idx=%.0f Cert=%s Opt=%.0f | %s",
                               r.center_status,
                               r.learning_confidence,
                               r.knowledge_index,
                               GmSlCertName(r.learning_certification),
                               r.optimization_score,
                               GM_SL_ADVISORY);
      r.valid = true;

      m_db.Record(r);
      m_last = r;
      m_sched.Complete(GetTickCount());

      if(m_logger != NULL)
         m_logger.Info("Dashboard Updated | Self-Learning pending=" +
                       IntegerToString(m_sched.Pending()), "AISL");
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = m_last.center_status;
      s.ai_engine = "GoldMind AI Self-Learning Platform";
      s.current_mode = "AI_SELF_LEARNING";
      s.confidence_pct = m_last.learning_confidence;
      s.confidence_status = StringFormat("%.0f", m_last.learning_confidence);

      // Phase 5 Sprint 9 widgets (last-wins)
      s.w_trend_detector = StringFormat("%.0f", m_last.learning_confidence);     // Learning Confidence
      s.future_ai_score = StringFormat("%.0f", m_last.knowledge_index);          // Knowledge Index
      s.w_recovery_ai = m_last.pattern_library;                                  // Pattern Library
      s.prediction_status = StringFormat("%.0f", m_last.knowledge_growth);       // Knowledge Growth
      s.learning_status = m_last.recommendation_center;                          // Recommendation Center
      s.w_volatility_scanner = StringFormat("%.0f", m_last.optimization_score);  // Optimization Score
      s.w_market_analyzer = StringFormat("%.0f", m_last.learning_stability);     // Learning Stability
      s.w_news_analyzer = m_last.ai_evolution_status;                            // AI Evolution Status
      s.w_trade_confidence = m_last.historical_intelligence;                     // Historical Intelligence
      s.ai_version = m_last.ai_evolution_summary;                                // Learning Summary
      s.decision_status = GM_SL_ADVISORY;
     }
  };

#endif // GM_CAI_SELF_LEARNING_PLATFORM_ENGINE_MQH
//+------------------------------------------------------------------+
