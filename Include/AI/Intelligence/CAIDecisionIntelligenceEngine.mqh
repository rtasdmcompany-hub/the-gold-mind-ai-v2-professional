//+------------------------------------------------------------------+
//|                             CAIDecisionIntelligenceEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 4 Sprint 2 — Decision Intelligence (ADVISORY ONLY)    |
//+------------------------------------------------------------------+
#ifndef GM_CAI_DECISION_INTELLIGENCE_ENGINE_MQH
#define GM_CAI_DECISION_INTELLIGENCE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "IntelligenceAIConstants.mqh"
#include "SGmIntelligenceResult.mqh"
#include "CMarketIntelligenceEngine.mqh"
#include "CHistoricalPatternAnalyzer.mqh"
#include "CStrategyPerformanceAnalyzer.mqh"
#include "CAIRiskAdvisor.mqh"
#include "CMarketScoreEngine.mqh"
#include "CAIExplanationEngine.mqh"
#include "CIntelligenceDatabase.mqh"
#include "CIntelligenceQueue.mqh"
#include "../Trend/CAITrendEngine.mqh"
#include "../Volatility/CAIVolatilityEngine.mqh"
#include "../News/CAINewsEngine.mqh"
#include "../Confidence/CAIConfidenceEngine.mqh"
#include "../Learning/CAILearningEngine.mqh"
#include "../Assistant/CAISupervisorEngine.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Analytics/CAnalyticsEngine.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../SGmAISnapshot.mqh"

/// @brief Advanced AI Decision Intelligence Layer — OBSERVE / ANALYZE / ADVISE / REPORT.
class CGmAIDecisionIntelligenceEngine
  {
private:
   CGmLogger              *m_logger;
   CGmPhase2Bridge        *m_bridge;
   CGmAnalyticsEngine     *m_analytics;
   CGmAITrendEngine       *m_trend;
   CGmAIVolatilityEngine  *m_vol;
   CGmAINewsEngine        *m_news;
   CGmAIConfidenceEngine  *m_conf;
   CGmAILearningEngine    *m_learn;
   CGmAISupervisorEngine  *m_supervisor;

   CGmMarketIntelligenceEngine   m_market_intel;
   CGmHistoricalPatternAnalyzer  m_hist;
   CGmStrategyPerformanceAnalyzer m_strat;
   CGmAIRiskAdvisor              m_risk;
   CGmMarketScoreEngine          m_score;
   CGmAIExplanationEngine        m_xai;
   CGmIntelligenceDatabase       m_db;
   CGmIntelligenceQueue          m_queue;

   SGmIntelligenceResult  m_last;
   long                   m_magic;
   bool                   m_ready;

public:
                     CGmAIDecisionIntelligenceEngine(void)
                       : m_logger(NULL), m_bridge(NULL), m_analytics(NULL),
                         m_trend(NULL), m_vol(NULL), m_news(NULL), m_conf(NULL),
                         m_learn(NULL), m_supervisor(NULL), m_magic(0), m_ready(false)
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
      m_queue.Reset();
      m_last.Reset();
      m_ready = true;
      if(m_logger != NULL)
        {
         m_logger.Success("AI Intelligence Started | " + GM_INTEL_VERSION +
                          " | " + GM_INTEL_ANALYSIS_ONLY, "AIIntel");
         m_logger.Info("POLICY | " + GM_INTEL_ADVISORY +
                       " | Core remains sole execution authority", "AIIntel");
        }
      return true;
     }

   void BindSources(CGmAITrendEngine *trend,
                    CGmAIVolatilityEngine *vol,
                    CGmAINewsEngine *news,
                    CGmAIConfidenceEngine *conf,
                    CGmAILearningEngine *learn,
                    CGmAISupervisorEngine *supervisor)
     {
      m_trend = trend;
      m_vol = vol;
      m_news = news;
      m_conf = conf;
      m_learn = learn;
      m_supervisor = supervisor;
      if(m_logger != NULL)
         m_logger.Info("Intelligence sources bound | Trend+Vol+News+Conf+Learn+Supervisor",
                       "AIIntel");
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmIntelligenceResult Last(void) const { return m_last; }

   bool Analyze(void)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      m_queue.Enqueue();

      if(!m_queue.ShouldRun(now, GM_INTEL_THROTTLE_MS))
        {
         if(m_last.valid && m_queue.CacheValid(now))
           {
            m_last.from_cache = true;
            m_last.status = GM_INTEL_STATUS_CACHED;
            return true;
           }
         return m_last.valid;
        }

      m_queue.Begin(now);

      SGmIntelligenceResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.status = GM_INTEL_STATUS_RUNNING;
      r.may_execute = false;
      r.may_modify_risk = false;
      r.advisory_status = GM_INTEL_ADVISORY;
      r.from_cache = false;

      if(m_bridge != NULL)
        {
         r.symbol = m_bridge.Symbol();
         r.session_id = m_bridge.SessionId();
        }
      if(StringLen(r.symbol) == 0)
        {
         r.status = GM_INTEL_STATUS_ERROR;
         m_queue.Complete(now);
         if(m_logger != NULL)
            m_logger.Warning("Intelligence aborted | no symbol", "AIIntel");
         return false;
        }

      SGmTrendAnalysisResult trend;
      SGmVolatilityAnalysisResult vol;
      SGmNewsAnalysisResult news;
      SGmConfidenceAnalysisResult conf;
      SGmLearningAnalysisResult learn;
      SGmAssistantResult sup;
      trend.Reset(); vol.Reset(); news.Reset(); conf.Reset(); learn.Reset();
      sup.Reset();
      if(m_trend != NULL && m_trend.IsReady()) trend = m_trend.Last();
      if(m_vol != NULL && m_vol.IsReady()) vol = m_vol.Last();
      if(m_news != NULL && m_news.IsReady()) news = m_news.Last();
      if(m_conf != NULL && m_conf.IsReady()) conf = m_conf.Last();
      if(m_learn != NULL && m_learn.IsReady()) learn = m_learn.Last();
      if(m_supervisor != NULL && m_supervisor.IsReady()) sup = m_supervisor.Last();

      m_market_intel.Analyze(trend, vol, conf, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Market Analysis Completed | %s conf=%.0f",
                                    GmMktConditionName(r.market_condition),
                                    r.market_confidence), "AIIntel");

      m_hist.Analyze(learn, trend, vol, m_analytics, r);
      if(m_logger != NULL)
         m_logger.Info("Historical Pattern Found | " + r.pattern_insight, "AIIntel");

      m_strat.Analyze(m_analytics, sup, r);
      if(m_logger != NULL)
         m_logger.Info("Performance Report Created | " + r.performance_report, "AIIntel");

      m_risk.Analyze(m_bridge, sup, news, r, r);
      if(m_logger != NULL)
         m_logger.Info("Risk Advisory Generated | " + GmRiskAdvName(r.risk_advisory),
                       "AIIntel");

      m_score.Analyze(r);

      m_xai.Analyze(trend, vol, r);
      if(m_logger != NULL)
         m_logger.Info("AI Explanation Generated | " + r.explanation_short, "AIIntel");

      r.ai_confidence = GmIntelClamp(
                           0.40 * r.market_confidence +
                           0.25 * r.historical_similarity +
                           0.20 * r.strategy_performance_score +
                           0.15 * GmIntelClamp(100.0 - r.risk_score));
      r.strategy_health = r.strategy_performance_score;
      r.recovery_intelligence = r.recovery_success_rate;
      r.intelligence_status = "INTEL READY";
      r.status = GM_INTEL_STATUS_READY;
      r.insight = StringFormat("%s | Mkt=%.0f/%s Strat=%.0f Hist=%.0f Risk=%s Conf=%.0f | %s",
                               r.intelligence_status,
                               r.market_score,
                               GmIntelGradeName(r.market_grade),
                               r.strategy_performance_score,
                               r.historical_similarity,
                               GmRiskAdvName(r.risk_advisory),
                               r.ai_confidence,
                               GM_INTEL_ANALYSIS_ONLY);
      r.valid = true;

      m_db.Record(r);
      m_last = r;
      m_queue.Complete(GetTickCount());

      if(m_logger != NULL)
         m_logger.Info("Dashboard Intelligence Updated | queue_pending=" +
                       IntegerToString(m_queue.Pending()), "AIIntel");
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = m_last.intelligence_status;
      s.ai_engine = "GoldMind AI Intelligence";
      s.current_mode = "AI_INTELLIGENCE";
      s.confidence_pct = m_last.ai_confidence;
      s.confidence_status = StringFormat("%.0f%%", m_last.ai_confidence);

      // Intelligence Center widget pack (last-wins)
      s.w_trend_detector = StringFormat("%.0f/%s", m_last.market_score,
                                        GmIntelGradeName(m_last.market_grade));
      s.future_ai_score = StringFormat("%.0f", m_last.strategy_performance_score);
      s.w_recovery_ai = StringFormat("%.0f%%", m_last.historical_similarity);
      s.prediction_status = GmRiskAdvName(m_last.risk_advisory);
      s.learning_status = GmMktConditionName(m_last.market_condition);
      s.w_volatility_scanner = StringFormat("%.0f%%", m_last.ai_confidence);
      s.w_market_analyzer = StringFormat("%.0f", m_last.strategy_health);
      s.w_news_analyzer = StringFormat("%.0f%%", m_last.recovery_intelligence);
      s.w_trade_confidence = m_last.explanation_short;
      s.ai_version = StringFormat("%.0f", m_last.market_score);
      s.decision_status = GM_INTEL_ADVISORY;
      if(m_vol != NULL && m_vol.IsReady() && m_vol.Last().valid)
         s.atr14 = m_vol.Last().atr14;
     }
  };

#endif // GM_CAI_DECISION_INTELLIGENCE_ENGINE_MQH
//+------------------------------------------------------------------+
