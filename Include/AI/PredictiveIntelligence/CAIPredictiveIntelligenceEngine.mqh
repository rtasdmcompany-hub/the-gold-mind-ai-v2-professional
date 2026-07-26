//+------------------------------------------------------------------+
//|                        CAIPredictiveIntelligenceEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 5 Sprint 7 — Predictive Intelligence Facade           |
//+------------------------------------------------------------------+
#ifndef GM_CAI_PREDICTIVE_INTELLIGENCE_ENGINE_MQH
#define GM_CAI_PREDICTIVE_INTELLIGENCE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "PredictiveIntelligenceConstants.mqh"
#include "SGmPredictiveIntelligenceResult.mqh"
#include "CAIPredictiveIntelligence.mqh"
#include "CMarketScenarioSimulator.mqh"
#include "CProbabilityEngine.mqh"
#include "CMarketPathAnalyzer.mqh"
#include "CHistoricalSimulationEngine.mqh"
#include "CFuturePredictiveIntelligenceInterfaces.mqh"
#include "CPredictiveIntelligenceDatabase.mqh"
#include "CPredictiveIntelligenceScheduler.mqh"
#include "../Trend/CAITrendEngine.mqh"
#include "../Volatility/CAIVolatilityEngine.mqh"
#include "../OrderFlow/CAIOrderFlowIntelligenceEngine.mqh"
#include "../NewsIntelligence/CAINewsIntelligenceEngine.mqh"
#include "../MarketIntelligence/CAIMarketIntelligenceEngine.mqh"
#include "../MultiTimeframe/CAIMultiTimeframeEngine.mqh"
#include "../RecoveryIntelligence/CAIRecoveryIntelligenceEngine.mqh"
#include "../Forecasting/CAIForecastingEngine.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../SGmAISnapshot.mqh"

class CGmAIPredictiveIntelligenceEngine
  {
private:
   CGmLogger             *m_logger;
   CGmPhase2Bridge       *m_bridge;
   CGmAITrendEngine      *m_trend;
   CGmAIVolatilityEngine *m_vol;
   CGmAIOrderFlowIntelligenceEngine *m_orderflow;
   CGmAINewsIntelligenceEngine *m_newsintel;
   CGmAIMarketIntelligenceEngine *m_mktintel;
   CGmAIMultiTimeframeEngine *m_mtfintel;
   CGmAIRecoveryIntelligenceEngine *m_recintel;
   CGmAIForecastingEngine *m_forecast;

   CGmAIPredictiveIntelligence           m_core;
   CGmMarketScenarioSimulatorPred        m_scenarios;
   CGmProbabilityEnginePred              m_probability;
   CGmMarketPathAnalyzer                 m_path;
   CGmHistoricalSimulationEngine         m_historical;
   CGmFuturePredictiveIntelligenceLayer  m_future;
   CGmPredictiveIntelligenceDatabase     m_db;
   CGmPredictiveIntelligenceScheduler    m_sched;

   SGmPredictiveIntelligenceResult m_last;
   long                            m_magic;
   bool                            m_ready;

   string BuildSummary(const SGmPredictiveIntelligenceResult &r) const
     {
      return StringFormat("%s | Bull=%.0f Bear=%.0f Conf=%.0f Rel=%.0f | %s",
                          GmPredScenarioName(r.dominant_scenario),
                          r.bullish_probability, r.bearish_probability,
                          r.prediction_confidence, r.forecast_reliability,
                          GM_PRED_ADVISORY);
     }

public:
                     CGmAIPredictiveIntelligenceEngine(void)
                       : m_logger(NULL), m_bridge(NULL), m_trend(NULL), m_vol(NULL),
                         m_orderflow(NULL), m_newsintel(NULL), m_mktintel(NULL),
                         m_mtfintel(NULL), m_recintel(NULL), m_forecast(NULL),
                         m_magic(0), m_ready(false)
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
         m_logger.Success("Predictive Intelligence Started | " + GM_PRED_VERSION +
                          " | " + GM_PRED_ANALYSIS_ONLY, "AIPRED");
         m_logger.Info("POLICY | " + GM_PRED_ADVISORY, "AIPRED");
         m_logger.Info("CONTEXT | " + GM_PRED_CONTEXT, "AIPRED");
         m_logger.Info(m_future.Banner(), "AIPRED");
        }
      return true;
     }

   void BindSources(CGmAITrendEngine *trend,
                    CGmAIVolatilityEngine *vol,
                    CGmAIOrderFlowIntelligenceEngine *orderflow,
                    CGmAINewsIntelligenceEngine *newsintel,
                    CGmAIMarketIntelligenceEngine *mktintel,
                    CGmAIMultiTimeframeEngine *mtfintel,
                    CGmAIRecoveryIntelligenceEngine *recintel,
                    CGmAIForecastingEngine *forecast)
     {
      m_trend = trend;
      m_vol = vol;
      m_orderflow = orderflow;
      m_newsintel = newsintel;
      m_mktintel = mktintel;
      m_mtfintel = mtfintel;
      m_recintel = recintel;
      m_forecast = forecast;
      if(m_logger != NULL)
         m_logger.Info("Predictive sources bound | Trend+Vol+OF+News+MI+MTF+Rec+Forecast", "AIPRED");
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmPredictiveIntelligenceResult Last(void) const { return m_last; }
   CGmFuturePredictiveIntelligenceLayer *FutureLayer(void) { return GetPointer(m_future); }

   bool Analyze(void)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      m_sched.Signal();
      if(!m_sched.ShouldRun(now, GM_PRED_THROTTLE_MS))
        {
         if(m_last.valid && m_sched.CacheValid(now))
           {
            m_last.from_cache = true;
            m_last.status = GM_PRED_STATUS_CACHED;
            return true;
           }
         return m_last.valid;
        }

      m_sched.Begin(now);

      SGmPredictiveIntelligenceResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.status = GM_PRED_STATUS_RUNNING;
      r.may_execute = false;
      r.may_modify_risk = false;
      r.advisory_status = GM_PRED_ADVISORY;

      if(m_bridge != NULL)
        {
         r.symbol = m_bridge.Symbol();
         r.session_id = m_bridge.SessionId();
        }
      if(StringLen(r.symbol) == 0)
        {
         r.status = GM_PRED_STATUS_ERROR;
         m_sched.Complete(now);
         return false;
        }

      SGmTrendAnalysisResult trend;
      SGmVolatilityAnalysisResult vol;
      SGmOrderFlowResult of;
      SGmNewsIntelligenceResult ni;
      SGmMarketIntelligenceResult mi;
      SGmMultiTimeframeResult mtf;
      SGmRecoveryIntelligenceResult ri;
      SGmForecastResult fcst;
      trend.Reset(); vol.Reset(); of.Reset(); ni.Reset();
      mi.Reset(); mtf.Reset(); ri.Reset(); fcst.Reset();

      if(m_trend != NULL && m_trend.IsReady()) trend = m_trend.Last();
      if(m_vol != NULL && m_vol.IsReady()) vol = m_vol.Last();
      if(m_orderflow != NULL && m_orderflow.IsReady()) of = m_orderflow.Last();
      if(m_newsintel != NULL && m_newsintel.IsReady()) ni = m_newsintel.Last();
      if(m_mktintel != NULL && m_mktintel.IsReady()) mi = m_mktintel.Last();
      if(m_mtfintel != NULL && m_mtfintel.IsReady()) mtf = m_mtfintel.Last();
      if(m_recintel != NULL && m_recintel.IsReady()) ri = m_recintel.Last();
      if(m_forecast != NULL && m_forecast.IsReady()) fcst = m_forecast.Last();

      m_core.Analyze(trend, vol, of, ni, mi, mtf, fcst, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Prediction Generated | Conf=%.0f Rel=%.0f",
                                    r.prediction_confidence, r.forecast_reliability), "AIPRED");

      m_scenarios.Analyze(trend, vol, ni, ri, mi, r);
      if(m_logger != NULL)
         m_logger.Info("Scenario Simulated | " + GmPredScenarioName(r.dominant_scenario), "AIPRED");

      m_probability.Analyze(trend, vol, of, ri, fcst, r, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Probability Updated | Overall=%.0f Bull=%.0f Bear=%.0f",
                                    r.overall_probability_score,
                                    r.bullish_probability, r.bearish_probability), "AIPRED");

      m_path.Analyze(trend, vol, of, ri, r, r);
      m_historical.Analyze(mtf, ri, fcst, ni, r, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Historical Comparison Completed | Match=%.0f",
                                    r.historical_match), "AIPRED");

      r.ai_prediction_summary = BuildSummary(r);
      r.center_status = "PREDICTIVE INTEL READY";
      r.status = GM_PRED_STATUS_READY;
      r.insight = StringFormat("%s | %s Conf=%.0f Overall=%.0f Match=%.0f | %s",
                               r.center_status,
                               GmPredScenarioName(r.dominant_scenario),
                               r.prediction_confidence,
                               r.overall_probability_score,
                               r.historical_match,
                               GM_PRED_ADVISORY);
      r.valid = true;

      m_db.Record(r);
      m_last = r;
      m_sched.Complete(GetTickCount());

      if(m_logger != NULL)
         m_logger.Info("Dashboard Updated | Predictive pending=" +
                       IntegerToString(m_sched.Pending()), "AIPRED");
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = m_last.center_status;
      s.ai_engine = "GoldMind AI Predictive Intelligence";
      s.current_mode = "AI_PREDICTIVE_INTEL";
      s.confidence_pct = m_last.prediction_confidence;
      s.confidence_status = StringFormat("%.0f", m_last.prediction_confidence);

      // Phase 5 Sprint 7 widgets (last-wins)
      s.w_trend_detector = StringFormat("%.0f", m_last.prediction_confidence);   // Prediction Confidence
      s.future_ai_score = StringFormat("%.0f%% %s",
                                       m_last.scenario_probability,
                                       GmPredScenarioName(m_last.dominant_scenario)); // Scenario Probability
      s.w_recovery_ai = StringFormat("%.0f", m_last.bullish_probability);        // Bullish Probability
      s.prediction_status = StringFormat("%.0f", m_last.bearish_probability);    // Bearish Probability
      s.learning_status = StringFormat("%.0f", m_last.historical_match);         // Historical Match
      s.w_volatility_scanner = StringFormat("%.0f", m_last.forecast_reliability); // Forecast Reliability
      s.w_market_analyzer = GmPredScenarioName(m_last.dominant_scenario);        // Market Scenario
      s.w_news_analyzer = StringFormat("%.0f", m_last.overall_probability_score); // Probability Index
      s.w_trade_confidence = StringFormat("Rec=%.0f", m_last.recovery_probability); // Recovery Prob
      s.ai_version = m_last.ai_prediction_summary;                               // AI Prediction Summary
      s.decision_status = GM_PRED_ADVISORY;
     }
  };

#endif // GM_CAI_PREDICTIVE_INTELLIGENCE_ENGINE_MQH
//+------------------------------------------------------------------+
