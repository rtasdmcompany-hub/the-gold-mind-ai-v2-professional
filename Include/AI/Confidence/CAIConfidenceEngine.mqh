//+------------------------------------------------------------------+
//|                                       CAIConfidenceEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     Phase 3 Sprint 6 — AI Trade Confidence & Decision Support   |
//|     ADVISOR ONLY — NEVER rejects / modifies / cancels trades    |
//+------------------------------------------------------------------+
#ifndef GM_CAI_CONFIDENCE_ENGINE_MQH
#define GM_CAI_CONFIDENCE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ConfidenceAIConstants.mqh"
#include "SGmConfidenceAnalysisResult.mqh"
#include "CMarketQualityAnalyzer.mqh"
#include "CMultiFactorScoringEngine.mqh"
#include "CTradeEnvironmentClassifier.mqh"
#include "CDecisionSupportEngine.mqh"
#include "CConfidenceMlApi.mqh"
#include "CConfidenceEventEngine.mqh"
#include "CConfidenceHistoryDatabase.mqh"
#include "../Trend/CAITrendEngine.mqh"
#include "../Volatility/CAIVolatilityEngine.mqh"
#include "../News/CAINewsEngine.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../SGmAISnapshot.mqh"

/// @file CAIConfidenceEngine.mqh
/// @brief H4 trade confidence advisor — NEVER execution authority.

class CGmAIConfidenceEngine
  {
private:
   CGmLogger                      *m_logger;
   CGmPhase2Bridge                *m_bridge;
   CGmAITrendEngine               *m_trend;
   CGmAIVolatilityEngine          *m_vol;
   CGmAINewsEngine                *m_news;

   CGmMarketQualityAnalyzer        m_quality;
   CGmMultiFactorScoringEngine     m_scoring;
   CGmTradeEnvironmentClassifier   m_env;
   CGmDecisionSupportEngine        m_reco;
   CGmConfidenceMlApi              m_ml;
   CGmConfidenceEventEngine        m_events;
   CGmConfidenceHistoryDatabase    m_db;

   SGmConfidenceAnalysisResult     m_last;
   SGmConfidenceAnalysisResult     m_prev;
   datetime                        m_h4_bar;
   ulong                           m_last_ms;
   bool                            m_ready;

public:
                     CGmAIConfidenceEngine(void)
                       : m_logger(NULL), m_bridge(NULL),
                         m_trend(NULL), m_vol(NULL), m_news(NULL),
                         m_h4_bar(0), m_last_ms(0), m_ready(false)
     {
      m_last.Reset();
      m_prev.Reset();
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
      SGmConfidenceWeights w;
      w.Defaults();
      m_scoring.SetWeights(w);

      m_last.Reset();
      m_prev.Reset();
      m_h4_bar = 0;
      m_last_ms = 0;
      m_ready = true;
      if(m_logger != NULL)
        {
         m_logger.Success("AI Confidence Engine ready | " + GM_CONF_ADVISOR_ONLY +
                          " | " + GM_CONF_AI_VERSION, "AIConf");
         m_logger.Info("POLICY | " + GM_CONF_NO_EXECUTION +
                       " | Gold Mind Core remains sole execution authority",
                       "AIConf");
        }
      return true;
     }

   void BindSources(CGmAITrendEngine *trend,
                    CGmAIVolatilityEngine *vol,
                    CGmAINewsEngine *news)
     {
      m_trend = trend;
      m_vol = vol;
      m_news = news;
      if(m_logger != NULL)
         m_logger.Info("Confidence sources bound | Trend+Vol+News", "AIConf");
     }

   void SetWeights(const SGmConfidenceWeights &w)
     {
      m_scoring.SetWeights(w);
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmConfidenceAnalysisResult Last(void) const { return m_last; }
   CGmConfidenceMlApi *MlApi(void) { return GetPointer(m_ml); }
   CGmConfidenceEventEngine *Events(void) { return GetPointer(m_events); }
   SGmConfidenceMlFeatures MlFeatures(void) const { return m_ml.ExportFeatures(m_last); }

   bool Analyze(void)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_CONF_THROTTLE_MS && m_last.valid)
         return true;
      m_last_ms = now;

      SGmConfidenceAnalysisResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
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
            m_logger.Warning("Confidence analysis aborted | no symbol", "AIConf");
         return false;
        }

      SGmTrendAnalysisResult trend;
      SGmVolatilityAnalysisResult vol;
      SGmNewsAnalysisResult news;
      trend.Reset();
      vol.Reset();
      news.Reset();
      if(m_trend != NULL && m_trend.IsReady())
         trend = m_trend.Last();
      if(m_vol != NULL && m_vol.IsReady())
         vol = m_vol.Last();
      if(m_news != NULL && m_news.IsReady())
         news = m_news.Last();

      // H4 cycle detection — Gold Mind regenerates 3 buy / 3 sell levels each H4
      const datetime h4 = iTime(r.symbol, PERIOD_H4, 0);
      r.h4_bar_time = h4;
      r.new_h4_cycle = (h4 > 0 && h4 != m_h4_bar);
      if(r.new_h4_cycle)
         m_h4_bar = h4;

      m_quality.Analyze(r.symbol, trend, vol, news, r);
      m_scoring.Score(r.symbol, trend, vol, news, m_db.AverageConfidence(), r);
      m_env.Classify(r);
      m_reco.Recommend(r);

      // Confidence trend vs previous
      if(m_last.valid)
        {
         if(r.overall_confidence >= m_last.overall_confidence + 3.0)
            r.confidence_trend = GM_CONF_TREND_UP;
         else if(r.overall_confidence <= m_last.overall_confidence - 3.0)
            r.confidence_trend = GM_CONF_TREND_DOWN;
         else
            r.confidence_trend = GM_CONF_TREND_FLAT;
        }

      r.valid = true;

      m_events.Evaluate(r);
      m_db.Record(r);

      m_prev = m_last;
      m_last = r;

      if(m_logger != NULL)
        {
         m_logger.Info(StringFormat("Confidence Calculated | %.0f", r.overall_confidence), "AIConf");
         m_logger.Info(StringFormat("Quality Score Updated | TQ=%.0f MQ=%.0f",
                                    r.trade_quality, r.market_quality), "AIConf");
         m_logger.Info("Environment Classified | " + GmConfEnvName(r.environment), "AIConf");
         m_logger.Info("Recommendation Generated | " + GmConfRecoName(r.recommendation), "AIConf");
         m_logger.Info("Dashboard Updated | Confidence widgets", "AIConf");
         m_logger.Debug(StringFormat("Performance | conf cycle | ready=%.0f | risk=%.0f",
                                     r.execution_readiness, r.risk_environment),
                        "AIConf");
        }
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = "CONF READY";
      s.ai_engine = "GoldMind Confidence AI";
      s.current_mode = "CONFIDENCE_ADVISOR";
      s.confidence_pct = m_last.overall_confidence;
      s.confidence_status = m_last.session_rating;
      if(m_last.atr14 > 0.0)
         s.atr14 = m_last.atr14;

      // Widget packing (Sprint 6 Decision Center)
      s.w_trend_detector = StringFormat("%.0f%%", m_last.overall_confidence);
      s.future_ai_score = StringFormat("%.0f", m_last.trade_quality);
      s.w_recovery_ai = StringFormat("%.0f", m_last.market_quality);
      s.prediction_status = GmConfEnvName(m_last.environment);
      s.learning_status = GmConfRecoName(m_last.recommendation);
      s.w_volatility_scanner = StringFormat("%.0f", m_last.trend_score);
      s.w_market_analyzer = StringFormat("%.0f", m_last.volatility_score);
      s.w_news_analyzer = StringFormat("%.0f", m_last.news_risk);
      s.decision_status = StringFormat("%.0f", m_last.execution_readiness);
      s.w_trade_confidence = StringFormat("%.0f%%", m_last.overall_confidence);
      s.ai_version = GmConfTrendName(m_last.confidence_trend);
     }
  };

#endif // GM_CAI_CONFIDENCE_ENGINE_MQH
//+------------------------------------------------------------------+
