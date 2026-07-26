//+------------------------------------------------------------------+
//|                                          CAILearningEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     Phase 3 Sprint 7 — AI Learning & Pattern Recognition        |
//|     ANALYTICAL ONLY — NEVER modifies strategy / risk / orders   |
//+------------------------------------------------------------------+
#ifndef GM_CAI_LEARNING_ENGINE_MQH
#define GM_CAI_LEARNING_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "LearningAIConstants.mqh"
#include "SGmLearningAnalysisResult.mqh"
#include "CTradeStudyCollector.mqh"
#include "CPatternRecognition.mqh"
#include "COutcomeAnalyzer.mqh"
#include "CAiKnowledgeBase.mqh"
#include "CSelfImprovementFramework.mqh"
#include "CModelPerformanceAnalyzer.mqh"
#include "CFutureMlInterface.mqh"
#include "CLearningEventEngine.mqh"
#include "CLearningHistoryDatabase.mqh"
#include "../Trend/CAITrendEngine.mqh"
#include "../Volatility/CAIVolatilityEngine.mqh"
#include "../News/CAINewsEngine.mqh"
#include "../Confidence/CAIConfidenceEngine.mqh"
#include "../../Analytics/CAnalyticsEngine.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../SGmAISnapshot.mqh"

/// @file CAILearningEngine.mqh
/// @brief Continuous analytical learning — NEVER execution / strategy authority.

class CGmAILearningEngine
  {
private:
   CGmLogger                     *m_logger;
   CGmPhase2Bridge               *m_bridge;
   CGmAnalyticsEngine            *m_analytics;
   CGmAITrendEngine              *m_trend;
   CGmAIVolatilityEngine         *m_vol;
   CGmAINewsEngine               *m_news;
   CGmAIConfidenceEngine         *m_conf;

   CGmTradeStudyCollector         m_study;
   CGmPatternRecognitionEngine    m_patterns;
   CGmOutcomeAnalyzer             m_outcomes;
   CGmAiKnowledgeBase             m_kb;
   CGmSelfImprovementFramework    m_improve;
   CGmModelPerformanceAnalyzer    m_perf;
   CGmFutureMlInterface           m_ml;
   CGmLearningEventEngine         m_events;
   CGmLearningHistoryDatabase     m_db;

   SGmLearningAnalysisResult      m_last;
   long                           m_magic;
   int                            m_cycles;
   ulong                          m_last_ms;
   bool                           m_ready;

public:
                     CGmAILearningEngine(void)
                       : m_logger(NULL), m_bridge(NULL), m_analytics(NULL),
                         m_trend(NULL), m_vol(NULL), m_news(NULL), m_conf(NULL),
                         m_magic(0), m_cycles(0), m_last_ms(0), m_ready(false)
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
      m_events.Init(logger);
      m_kb.Init(logger, files, magic, symbol);
      m_db.Init(logger, files, magic, symbol);
      m_last.Reset();
      m_cycles = 0;
      m_last_ms = 0;
      m_ready = true;
      if(m_logger != NULL)
        {
         m_logger.Success("AI Learning Engine ready | " + GM_LEARN_ADVISOR_ONLY +
                          " | " + GM_LEARN_AI_VERSION, "AILearn");
         m_logger.Info("POLICY | never modify strategy/risk/orders | ML training deferred",
                       "AILearn");
        }
      return true;
     }

   void BindSources(CGmAITrendEngine *trend,
                    CGmAIVolatilityEngine *vol,
                    CGmAINewsEngine *news,
                    CGmAIConfidenceEngine *conf,
                    CGmAnalyticsEngine *analytics)
     {
      m_trend = trend;
      m_vol = vol;
      m_news = news;
      m_conf = conf;
      m_analytics = analytics;
      if(m_logger != NULL)
         m_logger.Info("Learning sources bound | Trend+Vol+News+Conf+Analytics", "AILearn");
     }

   void Shutdown(void)
     {
      m_kb.Shutdown();
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmLearningAnalysisResult Last(void) const { return m_last; }
   CGmFutureMlInterface *MlInterface(void) { return GetPointer(m_ml); }
   SGmLearningCalibration Calibration(void) const { return m_last.calibration; }

   bool Analyze(void)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_LEARN_THROTTLE_MS && m_last.valid)
         return true;
      m_last_ms = now;

      m_events.OnStarted();

      SGmLearningAnalysisResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.status = GM_LEARN_STATUS_RUNNING;
      r.may_modify_strategy = false;
      r.knowledge_version = m_kb.Version();

      if(m_bridge != NULL)
        {
         r.symbol = m_bridge.Symbol();
         r.session_id = m_bridge.SessionId();
        }
      if(StringLen(r.symbol) == 0)
        {
         r.status = GM_LEARN_STATUS_ERROR;
         if(m_logger != NULL)
            m_logger.Warning("Learning aborted | no symbol", "AILearn");
         return false;
        }

      SGmTrendAnalysisResult trend;
      SGmVolatilityAnalysisResult vol;
      SGmNewsAnalysisResult news;
      SGmConfidenceAnalysisResult conf;
      trend.Reset(); vol.Reset(); news.Reset(); conf.Reset();
      if(m_trend != NULL && m_trend.IsReady()) trend = m_trend.Last();
      if(m_vol != NULL && m_vol.IsReady()) vol = m_vol.Last();
      if(m_news != NULL && m_news.IsReady()) news = m_news.Last();
      if(m_conf != NULL && m_conf.IsReady()) conf = m_conf.Last();

      double analytics_wr = 0.0;
      if(m_analytics != NULL)
        {
         const SGmAnalyticsSnapshot a = m_analytics.Snapshot();
         if(a.total_trades > 0)
            analytics_wr = a.overall_win_rate;
        }

      SGmTradeStudyStats st;
      m_study.Collect(r.symbol, m_magic, st);
      r.sl_events_observed = st.sl_like;
      r.be_events_proxy = st.be_proxy;
      r.recovery_proxy = st.recovery_proxy;
      r.second_attempt_proxy = st.second_proxy;
      r.h4_sessions_studied = st.h4_buckets;

      m_kb.BeginCycle();
      const int pat_n = m_patterns.Detect(trend, vol, news, conf,
                                          st.wins, st.losses,
                                          st.recovery_proxy, st.second_proxy);
      r.patterns_detected = pat_n;
      if(pat_n > 0)
        {
         r.last_pattern = GmLearnPatternName(m_patterns.At(0).type);
         m_events.OnPattern(r.last_pattern);
        }
      m_kb.IngestPatterns(m_patterns);
      m_events.OnKnowledge();

      // Soft "pattern hit" proxy: patterns that align with winning conditions
      int hits = 0;
      for(int i = 0; i < m_patterns.Count(); i++)
        {
         const ENUM_GM_LEARN_PATTERN t = m_patterns.At(i).type;
         if(t == GM_LEARN_PAT_WIN_H4 || t == GM_LEARN_PAT_STRONG_TREND ||
            t == GM_LEARN_PAT_RECOVERY_SUCCESS || t == GM_LEARN_PAT_SECOND_ATTEMPT)
            hits++;
        }

      m_outcomes.Analyze(st.wins, st.losses, analytics_wr, conf, hits, MathMax(1, pat_n), r);

      m_cycles++;
      r.learning_cycles = m_cycles;
      r.knowledge_entries = m_kb.Size();
      r.knowledge_growth = m_kb.GrowthPct();

      m_improve.Improve(r);
      m_perf.Analyze(r);

      r.last_cycle_at = r.stamped_at;
      r.status = GM_LEARN_STATUS_READY;
      r.insight = StringFormat("%s | prog=%.0f | pred=%.0f | kb=%d | xp=%s | %s",
                               GmLearnStatusName(r.status),
                               r.learning_progress,
                               r.prediction_accuracy,
                               r.knowledge_entries,
                               GmLearnXpName(r.experience),
                               GM_LEARN_ADVISOR_ONLY);
      r.valid = true;

      m_kb.AddEntry(StringFormat("%s | cycle=%d | trades=%d W/L=%d/%d | confBias=%.1f",
                                 TimeToString(r.stamped_at, TIME_SECONDS),
                                 r.learning_cycles, r.trades_studied,
                                 r.wins_studied, r.losses_studied,
                                 r.calibration.confidence_bias));
      m_kb.Persist();
      m_db.Record(r);

      m_events.OnAccuracy(r);
      m_events.OnCompleted(r);

      m_last = r;

      if(m_logger != NULL)
        {
         m_logger.Info(StringFormat("Learning Completed | progress=%.0f", r.learning_progress),
                       "AILearn");
         m_logger.Debug(StringFormat("Performance | trades=%d patterns=%d kb=%d",
                                     r.trades_studied, r.patterns_detected, r.knowledge_entries),
                        "AILearn");
        }
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = "LEARN READY";
      s.ai_engine = "GoldMind Learning AI";
      s.current_mode = "LEARNING_ANALYSIS";
      s.confidence_pct = m_last.confidence;
      s.confidence_status = StringFormat("%.0f%%", m_last.learning_progress);

      s.w_trend_detector = GmLearnStatusName(m_last.status);
      s.future_ai_score = StringFormat("%.0f%%", m_last.learning_progress);
      s.w_recovery_ai = IntegerToString(m_last.knowledge_entries);
      s.prediction_status = IntegerToString(m_last.patterns_detected);
      s.learning_status = StringFormat("%.0f%%", m_last.prediction_accuracy);
      s.w_volatility_scanner = StringFormat("%.0f%%", m_last.confidence_accuracy);
      s.w_market_analyzer = StringFormat("%.0f%%", m_last.recommendation_accuracy);
      s.w_news_analyzer = m_last.knowledge_version;
      s.decision_status = GmLearnXpName(m_last.experience);
      s.w_trade_confidence = StringFormat("%.0f%%", m_last.confidence);
      s.ai_version = (m_last.last_cycle_at > 0)
                     ? TimeToString(m_last.last_cycle_at, TIME_DATE | TIME_MINUTES)
                     : "—";
     }
  };

#endif // GM_CAI_LEARNING_ENGINE_MQH
//+------------------------------------------------------------------+
