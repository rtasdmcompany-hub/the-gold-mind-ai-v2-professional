//+------------------------------------------------------------------+
//|                                    CAIForecastingEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 4 Sprint 8 — Forecasting Facade                       |
//+------------------------------------------------------------------+
#ifndef GM_CAI_FORECASTING_ENGINE_MQH
#define GM_CAI_FORECASTING_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ForecastingAIConstants.mqh"
#include "SGmForecastResult.mqh"
#include "CAIMarketForecastEngine.mqh"
#include "CScenarioSimulationEngine.mqh"
#include "CProbabilityIntelligenceEngine.mqh"
#include "CMarketTransitionDetector.mqh"
#include "CAIForecastAccuracyTracker.mqh"
#include "CScenarioExplanationEngine.mqh"
#include "CForecastDatabase.mqh"
#include "CForecastScheduler.mqh"
#include "../Trend/CAITrendEngine.mqh"
#include "../Volatility/CAIVolatilityEngine.mqh"
#include "../Intelligence/CAIDecisionIntelligenceEngine.mqh"
#include "../Assistant/CAISupervisorEngine.mqh"
#include "../RiskIntelligence/CAIRiskIntelligenceEngine.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../SGmAISnapshot.mqh"

class CGmAIForecastingEngine
  {
private:
   CGmLogger             *m_logger;
   CGmPhase2Bridge       *m_bridge;
   CGmAITrendEngine      *m_trend;
   CGmAIVolatilityEngine *m_vol;
   CGmAIDecisionIntelligenceEngine *m_intel;
   CGmAISupervisorEngine *m_supervisor;
   CGmAIRiskIntelligenceEngine *m_riskintel;

   CGmAIMarketForecastEngine         m_market_fcst;
   CGmScenarioSimulationEngine       m_scenarios;
   CGmProbabilityIntelligenceEngine  m_probs;
   CGmMarketTransitionDetector       m_transition;
   CGmAIForecastAccuracyTracker      m_accuracy;
   CGmScenarioExplanationEngine      m_explain;
   CGmForecastDatabase               m_db;
   CGmForecastScheduler              m_sched;

   ENUM_GM_FCST_REGIME   m_prev_regime;
   SGmForecastResult     m_last;
   long                  m_magic;
   int                   m_seq;
   bool                  m_ready;

public:
                     CGmAIForecastingEngine(void)
                       : m_logger(NULL), m_bridge(NULL), m_trend(NULL), m_vol(NULL),
                         m_intel(NULL), m_supervisor(NULL), m_riskintel(NULL),
                         m_prev_regime(GM_FCST_REGIME_UNKNOWN), m_magic(0), m_seq(0),
                         m_ready(false)
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
      m_seq = 0;
      m_prev_regime = GM_FCST_REGIME_UNKNOWN;
      m_accuracy.Reset();
      m_db.Init(logger, files, magic, symbol);
      m_sched.Reset();
      m_last.Reset();
      m_ready = true;
      if(m_logger != NULL)
        {
         m_logger.Success("AI Forecast Engine Started | " + GM_FCST_VERSION +
                          " | " + GM_FCST_ANALYSIS_ONLY, "AIFcst");
         m_logger.Info("POLICY | " + GM_FCST_ADVISORY, "AIFcst");
        }
      return true;
     }

   void BindSources(CGmAITrendEngine *trend,
                    CGmAIVolatilityEngine *vol,
                    CGmAIDecisionIntelligenceEngine *intel,
                    CGmAISupervisorEngine *supervisor,
                    CGmAIRiskIntelligenceEngine *riskintel = NULL)
     {
      m_trend = trend;
      m_vol = vol;
      m_intel = intel;
      m_supervisor = supervisor;
      m_riskintel = riskintel;
      if(m_logger != NULL)
         m_logger.Info("Forecast sources bound | Trend+Vol+Intel+Supervisor+Risk",
                       "AIFcst");
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmForecastResult Last(void) const { return m_last; }

   bool Analyze(void)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      m_sched.Signal();
      if(!m_sched.ShouldRun(now, GM_FCST_THROTTLE_MS))
        {
         if(m_last.valid && m_sched.CacheValid(now))
           {
            m_last.from_cache = true;
            m_last.status = GM_FCST_STATUS_CACHED;
            return true;
           }
         return m_last.valid;
        }

      m_sched.Begin(now);

      SGmForecastResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.status = GM_FCST_STATUS_RUNNING;
      r.may_execute = false;
      r.may_modify_strategy = false;
      r.advisory_status = GM_FCST_ADVISORY;
      m_seq++;
      r.forecast_id = StringFormat("FCST-%I64d-%d", m_magic, m_seq);

      if(m_bridge != NULL)
        {
         r.symbol = m_bridge.Symbol();
         r.session_id = m_bridge.SessionId();
        }
      if(StringLen(r.symbol) == 0)
        {
         r.status = GM_FCST_STATUS_ERROR;
         m_sched.Complete(now);
         return false;
        }

      SGmTrendAnalysisResult trend;
      SGmVolatilityAnalysisResult vol;
      SGmIntelligenceResult intel;
      SGmAssistantResult sup;
      SGmRiskIntelligenceResult risk;
      trend.Reset(); vol.Reset(); intel.Reset(); sup.Reset(); risk.Reset();
      if(m_trend != NULL && m_trend.IsReady()) trend = m_trend.Last();
      if(m_vol != NULL && m_vol.IsReady()) vol = m_vol.Last();
      if(m_intel != NULL && m_intel.IsReady()) intel = m_intel.Last();
      if(m_supervisor != NULL && m_supervisor.IsReady()) sup = m_supervisor.Last();
      if(m_riskintel != NULL && m_riskintel.IsReady()) risk = m_riskintel.Last();

      m_market_fcst.Analyze(trend, vol, intel, r);
      if(m_logger != NULL)
         m_logger.Info("Market Forecast Generated | " + GmFcstOutlookName(r.outlook), "AIFcst");

      m_scenarios.Analyze(trend, vol, sup, r, r);
      if(m_logger != NULL)
         m_logger.Info("Scenario Simulation Completed | " +
                       GmFcstScenarioName(r.dominant_scenario), "AIFcst");

      m_probs.Analyze(vol, sup, risk, r, r);
      if(m_logger != NULL)
         m_logger.Info("Probability Matrix Updated", "AIFcst");

      m_transition.Analyze(trend, vol, sup, m_prev_regime, r);
      if(r.transition_detected && m_logger != NULL)
         m_logger.Info("Market Transition Detected | " +
                       GmFcstRegimeName(r.regime_from) + " → " +
                       GmFcstRegimeName(r.regime_to), "AIFcst");
      m_prev_regime = r.regime_to;

      m_accuracy.Analyze(trend, r, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Forecast Accuracy Updated | %.0f%% (%+.0f)",
                                    r.accuracy_score, r.accuracy_improvement), "AIFcst");

      m_explain.Analyze(trend, vol, intel, r);

      r.center_status = "FORECAST CENTER READY";
      r.status = GM_FCST_STATUS_READY;
      r.insight = StringFormat("%s | Outlook=%s Trend=%.0f%% Dom=%s Acc=%.0f%% | %s",
                               r.center_status,
                               GmFcstOutlookName(r.outlook),
                               r.trend_probability,
                               GmFcstScenarioName(r.dominant_scenario),
                               r.accuracy_score,
                               GM_FCST_ANALYSIS_ONLY);
      r.valid = true;

      m_db.Record(r);
      m_last = r;
      m_sched.Complete(GetTickCount());

      if(m_logger != NULL)
         m_logger.Info("Dashboard Forecast Updated | pending=" +
                       IntegerToString(m_sched.Pending()), "AIFcst");
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = m_last.center_status;
      s.ai_engine = "GoldMind AI Forecast Center";
      s.current_mode = "AI_FORECAST";
      s.confidence_pct = m_last.forecast_confidence;
      s.confidence_status = StringFormat("%.0f", m_last.forecast_confidence);

      // AI Forecast Center widgets (last-wins)
      s.w_trend_detector = StringFormat("%s | Trend=%.0f%% | Vol=%s",
                                        GmFcstOutlookName(m_last.outlook),
                                        m_last.trend_probability,
                                        m_last.volatility_expectation);      // Current Market Forecast
      s.future_ai_score = m_last.scenario_probability_map;               // Scenario Probability Map
      s.w_recovery_ai = StringFormat("%.0f%%", m_last.trend_probability); // Trend Probability
      s.prediction_status = StringFormat("%s | VolP=%.0f%%",
                                         m_last.volatility_expectation,
                                         m_last.prob_volatility);        // Volatility Forecast
      s.learning_status = (m_last.transition_detected
                           ? StringFormat("%s→%s (%.0f%%)",
                                          GmFcstRegimeName(m_last.regime_from),
                                          GmFcstRegimeName(m_last.regime_to),
                                          m_last.transition_confidence)
                           : StringFormat("Stable | %s",
                                          GmFcstRegimeName(m_last.regime_to))); // Transition
      s.w_volatility_scanner = StringFormat("%.0f%% (%+.0f)",
                                            m_last.accuracy_score,
                                            m_last.accuracy_improvement); // Forecast Accuracy
      s.w_market_analyzer = m_last.historical_match;                     // Historical Scenario Match
      s.w_news_analyzer = m_last.ai_explanation;                         // AI Outlook Explanation
      s.w_trade_confidence = m_last.technical_summary;
      s.ai_version = GmFcstScenarioName(m_last.dominant_scenario);
      s.decision_status = GM_FCST_ADVISORY;
     }
  };

#endif // GM_CAI_FORECASTING_ENGINE_MQH
//+------------------------------------------------------------------+
