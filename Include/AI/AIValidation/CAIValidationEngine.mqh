//+------------------------------------------------------------------+
//|                                      CAIValidationEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     Phase 3 Sprint 9 — AI Validation / Backtest / Certification |
//|     ANALYSIS ONLY — NEVER modifies strategy / risk / orders     |
//+------------------------------------------------------------------+
#ifndef GM_CAI_VALIDATION_ENGINE_MQH
#define GM_CAI_VALIDATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "AIValidationConstants.mqh"
#include "SGmAIValidationResult.mqh"
#include "CBacktestIntelligenceEngine.mqh"
#include "CForwardTestEngine.mqh"
#include "CModelCertificationEngine.mqh"
#include "CModelDriftDetector.mqh"
#include "CAiValidationReportEngine.mqh"
#include "CAiValidationEventEngine.mqh"
#include "CAiValidationHistoryDatabase.mqh"
#include "../Trend/CAITrendEngine.mqh"
#include "../Volatility/CAIVolatilityEngine.mqh"
#include "../News/CAINewsEngine.mqh"
#include "../Confidence/CAIConfidenceEngine.mqh"
#include "../Learning/CAILearningEngine.mqh"
#include "../Decision/CAIDecisionSupportEngine.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../SGmAISnapshot.mqh"

/// @file CAIValidationEngine.mqh
/// @brief Measures AI analytical quality — NEVER execution / strategy authority.

class CGmAIValidationEngine
  {
private:
   CGmLogger                      *m_logger;
   CGmPhase2Bridge                *m_bridge;
   CGmAITrendEngine               *m_trend;
   CGmAIVolatilityEngine          *m_vol;
   CGmAINewsEngine                *m_news;
   CGmAIConfidenceEngine          *m_conf;
   CGmAILearningEngine            *m_learn;
   CGmAIDecisionSupportEngine     *m_decision;

   CGmBacktestIntelligenceEngine   m_backtest;
   CGmForwardTestEngine            m_forward;
   CGmModelCertificationEngine     m_cert;
   CGmModelDriftDetector           m_drift;
   CGmAiValidationReportEngine     m_reports;
   CGmAiValidationEventEngine      m_events;
   CGmAiValidationHistoryDatabase  m_db;

   SGmAIValidationResult           m_last;
   long                            m_magic;
   ulong                           m_last_ms;
   bool                            m_ready;

public:
                     CGmAIValidationEngine(void)
                       : m_logger(NULL), m_bridge(NULL),
                         m_trend(NULL), m_vol(NULL), m_news(NULL),
                         m_conf(NULL), m_learn(NULL), m_decision(NULL),
                         m_magic(0), m_last_ms(0), m_ready(false)
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
      m_db.Init(logger, files, magic, symbol);
      m_reports.Init(logger, files, magic, symbol);
      m_last.Reset();
      m_last_ms = 0;
      m_ready = true;
      if(m_logger != NULL)
        {
         m_logger.Success("AI Validation Engine ready | " + GM_AIVAL_ANALYSIS_ONLY +
                          " | " + GM_AIVAL_VERSION, "AIVal");
         m_logger.Info("POLICY | never modify/optimize strategy or risk automatically",
                       "AIVal");
        }
      return true;
     }

   void BindSources(CGmAITrendEngine *trend,
                    CGmAIVolatilityEngine *vol,
                    CGmAINewsEngine *news,
                    CGmAIConfidenceEngine *conf,
                    CGmAILearningEngine *learn,
                    CGmAIDecisionSupportEngine *decision)
     {
      m_trend = trend;
      m_vol = vol;
      m_news = news;
      m_conf = conf;
      m_learn = learn;
      m_decision = decision;
      if(m_logger != NULL)
         m_logger.Info("Validation sources bound | Trend+Vol+News+Conf+Learn+Decision",
                       "AIVal");
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmAIValidationResult Last(void) const { return m_last; }

   bool Analyze(void)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_AIVAL_THROTTLE_MS && m_last.valid)
         return true;
      m_last_ms = now;

      m_events.OnStarted();

      SGmAIValidationResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.status = GM_AIVAL_STATUS_RUNNING;
      r.may_modify_strategy = false;

      if(m_bridge != NULL)
        {
         r.symbol = m_bridge.Symbol();
         r.session_id = m_bridge.SessionId();
        }
      if(StringLen(r.symbol) == 0)
        {
         r.status = GM_AIVAL_STATUS_ERROR;
         if(m_logger != NULL)
            m_logger.Warning("Validation aborted | no symbol", "AIVal");
         return false;
        }

      SGmTrendAnalysisResult trend;
      SGmVolatilityAnalysisResult vol;
      SGmNewsAnalysisResult news;
      SGmConfidenceAnalysisResult conf;
      SGmLearningAnalysisResult learn;
      SGmDecisionSupportResult dec;
      trend.Reset(); vol.Reset(); news.Reset(); conf.Reset(); learn.Reset(); dec.Reset();
      if(m_trend != NULL && m_trend.IsReady()) trend = m_trend.Last();
      if(m_vol != NULL && m_vol.IsReady()) vol = m_vol.Last();
      if(m_news != NULL && m_news.IsReady()) news = m_news.Last();
      if(m_conf != NULL && m_conf.IsReady()) conf = m_conf.Last();
      if(m_learn != NULL && m_learn.IsReady()) learn = m_learn.Last();
      if(m_decision != NULL && m_decision.IsReady()) dec = m_decision.Last();

      m_backtest.Analyze(r.symbol, m_magic, r);
      m_events.OnBacktest();

      m_forward.Analyze(trend, vol, conf, dec, learn, r);
      m_events.OnForward();

      // Soft news accuracy from news engine confidence if available
      if(news.valid)
         r.news_accuracy = GmAiValClamp(news.confidence);

      m_cert.Certify(r);
      m_events.OnCert(r.certification_score);

      m_drift.Detect(r);
      if(r.drift_alert)
         m_events.OnDrift(r.drift_message);

      if(r.status != GM_AIVAL_STATUS_DRIFT)
         r.status = GM_AIVAL_STATUS_READY;

      m_reports.Generate(r);

      r.insight = StringFormat("%s | acc=%.0f cert=%.0f grade=%s | %s | %s",
                               GmAiValStatusName(r.status),
                               r.ai_accuracy,
                               r.certification_score,
                               GmAiValGradeName(r.reliability_grade),
                               r.drift_alert ? r.drift_message : "stable",
                               GM_AIVAL_ANALYSIS_ONLY);
      r.valid = true;

      m_db.Record(r);
      m_events.OnCompleted(r);
      m_last = r;

      if(m_logger != NULL)
        {
         m_logger.Info(StringFormat("Validation Completed | acc=%.0f cert=%.0f",
                                    r.ai_accuracy, r.certification_score), "AIVal");
         m_logger.Info("Dashboard Updated | Validation widgets", "AIVal");
         if(r.drift_alert)
            m_logger.Warning("Drift Detected | " + r.drift_message, "AIVal");
         m_logger.Debug(StringFormat("Performance | fwd=%.0f bkt=%.0f health=%.0f",
                                     r.forward_test_score, r.backtest_score, r.ai_health_score),
                        "AIVal");
        }
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = "VALID READY";
      s.ai_engine = "GoldMind AI Validation";
      s.current_mode = "AI_VALIDATION";
      s.confidence_pct = m_last.certification_score;
      s.confidence_status = StringFormat("%.0f%%", m_last.ai_accuracy);

      s.w_trend_detector = StringFormat("%.0f%%", m_last.ai_accuracy);
      s.future_ai_score = StringFormat("%.0f%%", m_last.prediction_accuracy);
      s.w_recovery_ai = StringFormat("%.0f%%", m_last.confidence_accuracy);
      s.prediction_status = StringFormat("%.0f%%", m_last.strategy_match_accuracy);
      s.learning_status = StringFormat("LIVE %.0f", m_last.forward_test_score);
      s.w_volatility_scanner = StringFormat("BKT %.0f", m_last.backtest_score);
      s.w_market_analyzer = StringFormat("%.0f", m_last.certification_score);
      s.w_news_analyzer = m_last.drift_alert ? GmAiValDriftName(m_last.drift_type) : "Stable";
      s.decision_status = StringFormat("%.0f", m_last.learning_stability);
      s.w_trade_confidence = StringFormat("%.0f", m_last.ai_health_score);
      s.ai_version = StringFormat("Grade %s", GmAiValGradeName(m_last.reliability_grade));
     }
  };

#endif // GM_CAI_VALIDATION_ENGINE_MQH
//+------------------------------------------------------------------+
