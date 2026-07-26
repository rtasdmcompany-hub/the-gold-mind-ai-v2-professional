//+------------------------------------------------------------------+
//|                                   CAIDecisionSupportEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     Phase 3 Sprint 8 — Decision Support & Explainable AI        |
//|     ADVISORY ONLY — NEVER executes / rejects / modifies trades  |
//+------------------------------------------------------------------+
#ifndef GM_CAI_DECISION_SUPPORT_ENGINE_MQH
#define GM_CAI_DECISION_SUPPORT_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "DecisionAIConstants.mqh"
#include "SGmDecisionSupportResult.mqh"
#include "CDecisionMatrixEngine.mqh"
#include "CExplainableAI.mqh"
#include "CHistoricalSimilarityEngine.mqh"
#include "CStrategyValidationEngine.mqh"
#include "CFutureAutonomyInterfaces.mqh"
#include "CDecisionEventEngine.mqh"
#include "CDecisionHistoryDatabase.mqh"
#include "../Trend/CAITrendEngine.mqh"
#include "../Volatility/CAIVolatilityEngine.mqh"
#include "../News/CAINewsEngine.mqh"
#include "../Confidence/CAIConfidenceEngine.mqh"
#include "../Learning/CAILearningEngine.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../SGmAISnapshot.mqh"

/// @file CAIDecisionSupportEngine.mqh
/// @brief H4 decision support + XAI — NEVER execution authority.

class CGmAIDecisionSupportEngine
  {
private:
   CGmLogger                       *m_logger;
   CGmPhase2Bridge                 *m_bridge;
   CGmAITrendEngine                *m_trend;
   CGmAIVolatilityEngine           *m_vol;
   CGmAINewsEngine                 *m_news;
   CGmAIConfidenceEngine           *m_conf;
   CGmAILearningEngine             *m_learn;

   CGmDecisionMatrixEngine          m_matrix;
   CGmExplainableAI                 m_xai;
   CGmHistoricalSimilarityEngine    m_sim;
   CGmStrategyValidationEngine      m_valid;
   CGmFutureAutonomyLayer           m_autonomy;
   CGmDecisionEventEngine           m_events;
   CGmDecisionHistoryDatabase       m_db;

   SGmDecisionSupportResult         m_last;
   datetime                         m_h4_bar;
   ulong                            m_last_ms;
   bool                             m_ready;

   string ShortExpl(const string s, const int max_len) const
     {
      if(StringLen(s) <= max_len)
         return s;
      return StringSubstr(s, 0, max_len - 3) + "...";
     }

public:
                     CGmAIDecisionSupportEngine(void)
                       : m_logger(NULL), m_bridge(NULL),
                         m_trend(NULL), m_vol(NULL), m_news(NULL),
                         m_conf(NULL), m_learn(NULL),
                         m_h4_bar(0), m_last_ms(0), m_ready(false)
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
      m_events.Init(logger);
      m_db.Init(logger, files, magic, symbol);
      m_last.Reset();
      m_h4_bar = 0;
      m_last_ms = 0;
      m_ready = true;
      if(m_logger != NULL)
        {
         m_logger.Success("AI Decision Support ready | " + GM_DEC_ADVISORY_ONLY +
                          " | " + GM_DEC_AI_VERSION, "AIDec");
         m_logger.Info("POLICY | " + GM_DEC_NO_EXECUTION, "AIDec");
         m_logger.Info(m_autonomy.Banner(), "AIDec");
        }
      return true;
     }

   void BindSources(CGmAITrendEngine *trend,
                    CGmAIVolatilityEngine *vol,
                    CGmAINewsEngine *news,
                    CGmAIConfidenceEngine *conf,
                    CGmAILearningEngine *learn)
     {
      m_trend = trend;
      m_vol = vol;
      m_news = news;
      m_conf = conf;
      m_learn = learn;
      if(m_logger != NULL)
         m_logger.Info("Decision sources bound | Trend+Vol+News+Conf+Learn", "AIDec");
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmDecisionSupportResult Last(void) const { return m_last; }
   CGmFutureAutonomyLayer *AutonomyLayer(void) { return GetPointer(m_autonomy); }

   bool Analyze(void)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_DEC_THROTTLE_MS && m_last.valid)
         return true;
      m_last_ms = now;

      SGmDecisionSupportResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.may_execute = false;
      r.may_reject_trades = false;
      r.may_modify_trades = false;

      if(m_bridge != NULL)
        {
         r.symbol = m_bridge.Symbol();
         r.session_id = m_bridge.SessionId();
        }
      if(StringLen(r.symbol) == 0)
        {
         if(m_logger != NULL)
            m_logger.Warning("Decision analysis aborted | no symbol", "AIDec");
         return false;
        }

      SGmTrendAnalysisResult trend;
      SGmVolatilityAnalysisResult vol;
      SGmNewsAnalysisResult news;
      SGmConfidenceAnalysisResult conf;
      SGmLearningAnalysisResult learn;
      trend.Reset(); vol.Reset(); news.Reset(); conf.Reset(); learn.Reset();
      if(m_trend != NULL && m_trend.IsReady()) trend = m_trend.Last();
      if(m_vol != NULL && m_vol.IsReady()) vol = m_vol.Last();
      if(m_news != NULL && m_news.IsReady()) news = m_news.Last();
      if(m_conf != NULL && m_conf.IsReady()) conf = m_conf.Last();
      if(m_learn != NULL && m_learn.IsReady()) learn = m_learn.Last();

      const datetime h4 = iTime(r.symbol, PERIOD_H4, 0);
      r.h4_bar_time = h4;
      r.new_h4_cycle = (h4 > 0 && h4 != m_h4_bar);
      if(r.new_h4_cycle)
         m_h4_bar = h4;

      // Fingerprint current environment for similarity
      SGmDecHistoryFinger cur;
      cur.Reset();
      cur.t = r.stamped_at;
      cur.trend = trend.valid ? trend.confidence : 50.0;
      cur.atr = vol.valid ? vol.atr_strength : 50.0;
      cur.vol = vol.valid ? vol.vol_stability : 50.0;
      cur.spread = GmDecClamp(100.0 - MathMax(0.0, (double)SymbolInfoInteger(r.symbol, SYMBOL_SPREAD) - 12.0) * 2.0);
      cur.news = news.valid ? GmDecClamp(100.0 - news.news_risk_score * 0.55) : 60.0;
      cur.structure = trend.valid ? trend.agreement_score : 50.0;
      cur.conf = conf.valid ? conf.overall_confidence : 50.0;
      cur.success_proxy = learn.valid ? learn.historical_success_rate : 50.0;
      cur.used = true;

      m_sim.Search(cur, r);
      m_events.OnSimilarity(r.historical_similarity);

      m_matrix.Build(trend, vol, news, conf, learn, r);
      m_valid.Validate(conf, learn, r);
      m_events.OnValidation(r.strategy_match);

      m_xai.Explain(trend, vol, news, conf, r);
      m_events.OnExplanation();
      m_events.OnDecision(r);

      r.insight = StringFormat("%s | conf=%.0f | sim=%.0f | %s | %s",
                               GmDecRecoName(r.recommendation),
                               r.overall_confidence,
                               r.historical_similarity,
                               GmDecMatchName(r.strategy_match),
                               GM_DEC_ADVISORY_ONLY);
      r.valid = true;

      m_sim.Remember(cur);
      m_db.Record(r);
      m_last = r;

      if(m_logger != NULL)
        {
         m_logger.Info("Decision Generated | " + GmDecRecoName(r.recommendation), "AIDec");
         m_logger.Info("Dashboard Updated | Decision Support widgets", "AIDec");
         m_logger.Debug(StringFormat("Performance | factors=%d reasons=%d matches=%d",
                                     r.factor_count, r.reason_count, r.match_count),
                        "AIDec");
        }
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = "DECISION READY";
      s.ai_engine = "GoldMind Decision XAI";
      s.current_mode = "DECISION_SUPPORT";
      s.confidence_pct = m_last.overall_confidence;
      s.confidence_status = StringFormat("%.0f%%", m_last.overall_confidence);

      s.w_trend_detector = GmDecRecoName(m_last.recommendation);
      s.future_ai_score = StringFormat("%.0f%%", m_last.overall_confidence);
      s.w_recovery_ai = StringFormat("%.0f%%", m_last.historical_similarity);
      s.prediction_status = StringFormat("%.0f", m_last.market_health);
      s.learning_status = GmDecMatchName(m_last.strategy_match);
      s.w_volatility_scanner = StringFormat("%.0f", m_last.environment_score);
      s.w_market_analyzer = (m_last.reason_count > 0) ? ShortExpl(m_last.reasons[0], 36) : "—";
      s.w_news_analyzer = ShortExpl(m_last.explanation, 40);
      s.decision_status = ShortExpl(m_last.top_factors_summary, 36);
      s.w_trade_confidence = StringFormat("%.0f%%", m_last.overall_confidence);
      s.ai_version = TimeToString(m_last.stamped_at, TIME_DATE | TIME_MINUTES);
     }
  };

#endif // GM_CAI_DECISION_SUPPORT_ENGINE_MQH
//+------------------------------------------------------------------+
