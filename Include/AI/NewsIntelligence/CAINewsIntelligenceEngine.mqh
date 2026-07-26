//+------------------------------------------------------------------+
//|                            CAINewsIntelligenceEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 5 Sprint 3 — News Intelligence Facade                 |
//+------------------------------------------------------------------+
#ifndef GM_CAI_NEWS_INTELLIGENCE_ENGINE_MQH
#define GM_CAI_NEWS_INTELLIGENCE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "NewsIntelligenceConstants.mqh"
#include "SGmNewsIntelligenceResult.mqh"
#include "CAINewsIntelligenceCore.mqh"
#include "CNewsImpactAnalyzer.mqh"
#include "CAIGoldNewsEngine.mqh"
#include "CHistoricalNewsAnalyzer.mqh"
#include "CVolatilityForecastEngine.mqh"
#include "CFutureNewsIntelligenceInterfaces.mqh"
#include "CNewsIntelligenceDatabase.mqh"
#include "CNewsIntelligenceScheduler.mqh"
#include "../News/CAINewsEngine.mqh"
#include "../Trend/CAITrendEngine.mqh"
#include "../Volatility/CAIVolatilityEngine.mqh"
#include "../OrderFlow/CAIOrderFlowIntelligenceEngine.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../SGmAISnapshot.mqh"

class CGmAINewsIntelligenceEngine
  {
private:
   CGmLogger             *m_logger;
   CGmPhase2Bridge       *m_bridge;
   CGmAINewsEngine       *m_news;
   CGmAITrendEngine      *m_trend;
   CGmAIVolatilityEngine *m_vol;
   CGmAIOrderFlowIntelligenceEngine *m_orderflow;

   CGmAINewsIntelligenceCore       m_core;
   CGmNewsImpactAnalyzer           m_impact;
   CGmAIGoldNewsEngine             m_gold;
   CGmHistoricalNewsAnalyzer       m_historical;
   CGmVolatilityForecastEngineNI   m_forecast;
   CGmFutureNewsIntelligenceLayer  m_future;
   CGmNewsIntelligenceDatabase     m_db;
   CGmNewsIntelligenceScheduler    m_sched;

   SGmNewsIntelligenceResult m_last;
   long                      m_magic;
   bool                      m_ready;

   string BuildRecommendation(const SGmNewsIntelligenceResult &r) const
     {
      string rec = "Observe H4 Gold Mind levels; news is an opportunity zone — do not skip.";
      if(r.impact_class == GM_NI_IMPACT_EXTREME)
         rec = "Extreme impact window: expect ATR/spread expansion; Gold Mind remains active — advisory monitoring only.";
      else if(r.impact_class == GM_NI_IMPACT_HIGH)
         rec = "High-impact event: elevated volatility expected; treat as opportunity zone, never disable trading.";
      else if(r.impact_class == GM_NI_IMPACT_MEDIUM)
         rec = "Medium impact: moderate expansion likely; continue standard Gold Mind observation.";
      else if(r.impact_class == GM_NI_IMPACT_LOW)
         rec = "Low impact: limited expansion; baseline environment.";
      else
         rec = "No scheduled priority event: baseline Gold Mind environment.";
      return rec + " | " + GM_NI_ADVISORY;
     }

public:
                     CGmAINewsIntelligenceEngine(void)
                       : m_logger(NULL), m_bridge(NULL), m_news(NULL), m_trend(NULL),
                         m_vol(NULL), m_orderflow(NULL), m_magic(0), m_ready(false)
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
      m_last.Reset();
      m_ready = true;
      if(m_logger != NULL)
        {
         m_logger.Success("News Intelligence Started | " + GM_NI_VERSION +
                          " | " + GM_NI_ANALYSIS_ONLY, "AINI");
         m_logger.Info("POLICY | " + GM_NI_ADVISORY, "AINI");
         m_logger.Info("POLICY | " + GM_NI_OPPORTUNITY, "AINI");
         m_logger.Info(m_future.Banner(), "AINI");
        }
      return true;
     }

   void BindSources(CGmAINewsEngine *news,
                    CGmAITrendEngine *trend,
                    CGmAIVolatilityEngine *vol,
                    CGmAIOrderFlowIntelligenceEngine *orderflow)
     {
      m_news = news;
      m_trend = trend;
      m_vol = vol;
      m_orderflow = orderflow;
      if(m_logger != NULL)
         m_logger.Info("News Intelligence sources bound | News+Trend+Vol+OrderFlow", "AINI");
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmNewsIntelligenceResult Last(void) const { return m_last; }
   CGmFutureNewsIntelligenceLayer *FutureLayer(void) { return GetPointer(m_future); }

   bool Analyze(void)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      m_sched.Signal();
      if(!m_sched.ShouldRun(now, GM_NI_THROTTLE_MS))
        {
         if(m_last.valid && m_sched.CacheValid(now))
           {
            m_last.from_cache = true;
            m_last.status = GM_NI_STATUS_CACHED;
            return true;
           }
         return m_last.valid;
        }

      m_sched.Begin(now);

      SGmNewsIntelligenceResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.status = GM_NI_STATUS_RUNNING;
      r.may_disable_trading = false;
      r.may_skip_trades = false;
      r.advisory_status = GM_NI_ADVISORY;

      if(m_bridge != NULL)
        {
         r.symbol = m_bridge.Symbol();
         r.session_id = m_bridge.SessionId();
        }
      if(StringLen(r.symbol) == 0)
        {
         r.status = GM_NI_STATUS_ERROR;
         m_sched.Complete(now);
         return false;
        }

      SGmNewsAnalysisResult news;
      SGmTrendAnalysisResult trend;
      SGmVolatilityAnalysisResult vol;
      SGmOrderFlowResult of;
      news.Reset(); trend.Reset(); vol.Reset(); of.Reset();
      if(m_news != NULL && m_news.IsReady()) news = m_news.Last();
      if(m_trend != NULL && m_trend.IsReady()) trend = m_trend.Last();
      if(m_vol != NULL && m_vol.IsReady()) vol = m_vol.Last();
      if(m_orderflow != NULL && m_orderflow.IsReady()) of = m_orderflow.Last();

      m_core.Analyze(news, r);
      if(m_logger != NULL)
        {
         m_logger.Info("News Updated | " + r.upcoming_news, "AINI");
         m_logger.Info("Economic Event Loaded | " + GmNiEventClassName(r.event_class), "AINI");
        }

      m_impact.Analyze(news, vol, r, r);
      m_gold.Analyze(news, trend, vol, of, r, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Gold Sentiment Updated | %.0f %s",
                                    r.gold_sentiment_score, GmNiGoldBiasName(r.gold_bias)), "AINI");

      m_historical.Analyze(news, vol, r, r);
      m_forecast.Analyze(vol, trend, of, r, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Forecast Generated | ATR=%.0f Conf=%.0f",
                                    r.atr_forecast, r.forecast_confidence), "AINI");

      r.ai_news_recommendation = BuildRecommendation(r);
      r.center_status = "NEWS INTEL READY";
      r.status = GM_NI_STATUS_READY;
      r.insight = StringFormat("%s | %s Impact=%.0f Gold=%.0f ATRF=%.0f Conf=%.0f | %s",
                               r.center_status, r.upcoming_news,
                               r.news_impact_score, r.gold_sentiment_score,
                               r.atr_forecast, r.forecast_confidence,
                               GM_NI_ADVISORY);
      r.valid = true;

      m_db.Record(r);
      m_last = r;
      m_sched.Complete(GetTickCount());

      if(m_logger != NULL)
         m_logger.Info("Dashboard Refreshed | News Intelligence pending=" +
                       IntegerToString(m_sched.Pending()), "AINI");
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = m_last.center_status;
      s.ai_engine = "GoldMind AI News Intelligence";
      s.current_mode = "AI_NEWS_INTEL";
      s.confidence_pct = GmNiClamp(0.4 * m_last.forecast_confidence +
                                   0.3 * m_last.news_confidence +
                                   0.3 * m_last.news_impact_score);
      s.confidence_status = StringFormat("%.0f", m_last.forecast_confidence);

      // Phase 5 Sprint 3 widgets (last-wins)
      s.w_trend_detector = m_last.upcoming_news;                                 // Upcoming News
      s.future_ai_score = m_last.countdown_text;                                 // Countdown To Event
      s.w_recovery_ai = StringFormat("%.0f | %s", m_last.news_impact_score,
                                     GmNiImpactName(m_last.impact_class));       // News Impact Score
      s.prediction_status = StringFormat("%.0f | %s", m_last.gold_sentiment_score,
                                         GmNiGoldBiasName(m_last.gold_bias));    // Gold Sentiment
      s.learning_status = StringFormat("%.0f", m_last.expected_volatility);      // Expected Volatility
      s.w_volatility_scanner = StringFormat("%.0f", m_last.atr_forecast);        // ATR Forecast
      s.w_market_analyzer = StringFormat("%.0f%%", m_last.historical_similarity); // Historical News Similarity
      s.w_news_analyzer = StringFormat("Exp=%.0f", m_last.expansion_forecast);   // Expected Expansion
      s.w_trade_confidence = StringFormat("Liq=%.0f", m_last.liquidity_forecast); // Expected Liquidity
      s.ai_version = m_last.calendar_summary;                                    // Economic Calendar Summary
      // recommendation shown via decision_status; mode/confidence/gate via 11-13
      s.decision_status = m_last.ai_news_recommendation;
     }
  };

#endif // GM_CAI_NEWS_INTELLIGENCE_ENGINE_MQH
//+------------------------------------------------------------------+
