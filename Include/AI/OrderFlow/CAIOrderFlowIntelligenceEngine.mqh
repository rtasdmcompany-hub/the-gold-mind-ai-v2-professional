//+------------------------------------------------------------------+
//|                         CAIOrderFlowIntelligenceEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 5 Sprint 2 — Order Flow Intelligence Facade           |
//+------------------------------------------------------------------+
#ifndef GM_CAI_ORDER_FLOW_INTELLIGENCE_ENGINE_MQH
#define GM_CAI_ORDER_FLOW_INTELLIGENCE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "OrderFlowAIConstants.mqh"
#include "SGmOrderFlowResult.mqh"
#include "CGlobalSessionAnalyzer.mqh"
#include "CAIOrderFlowIntelligence.mqh"
#include "CMarketEnergyEngine.mqh"
#include "CSessionPersonalityEngine.mqh"
#include "CAIMarketTemperatureEngine.mqh"
#include "CFutureOrderFlowInterfaces.mqh"
#include "COrderFlowDatabase.mqh"
#include "COrderFlowScheduler.mqh"
#include "../Trend/CAITrendEngine.mqh"
#include "../Volatility/CAIVolatilityEngine.mqh"
#include "../News/CAINewsEngine.mqh"
#include "../Assistant/CAISupervisorEngine.mqh"
#include "../MarketIntelligence/CAIMarketIntelligenceEngine.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../SGmAISnapshot.mqh"

class CGmAIOrderFlowIntelligenceEngine
  {
private:
   CGmLogger             *m_logger;
   CGmPhase2Bridge       *m_bridge;
   CGmAITrendEngine      *m_trend;
   CGmAIVolatilityEngine *m_vol;
   CGmAINewsEngine       *m_news;
   CGmAISupervisorEngine *m_supervisor;
   CGmAIMarketIntelligenceEngine *m_mktintel;

   CGmGlobalSessionAnalyzer        m_session;
   CGmAIOrderFlowIntelligence      m_orderflow;
   CGmMarketEnergyEngineOF         m_energy;
   CGmSessionPersonalityEngine     m_personality;
   CGmAIMarketTemperatureEngine    m_temperature;
   CGmFutureOrderFlowLayer         m_future;
   CGmOrderFlowDatabase            m_db;
   CGmOrderFlowScheduler           m_sched;

   SGmOrderFlowResult m_last;
   long               m_magic;
   bool               m_ready;

public:
                     CGmAIOrderFlowIntelligenceEngine(void)
                       : m_logger(NULL), m_bridge(NULL), m_trend(NULL), m_vol(NULL),
                         m_news(NULL), m_supervisor(NULL), m_mktintel(NULL),
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
         m_logger.Success("Order Flow Intelligence Started | " + GM_OF_VERSION +
                          " | " + GM_OF_ANALYSIS_ONLY, "AIOF");
         m_logger.Info("POLICY | " + GM_OF_ADVISORY, "AIOF");
         m_logger.Info(m_future.Banner(), "AIOF");
        }
      return true;
     }

   void BindSources(CGmAITrendEngine *trend,
                    CGmAIVolatilityEngine *vol,
                    CGmAINewsEngine *news,
                    CGmAISupervisorEngine *supervisor,
                    CGmAIMarketIntelligenceEngine *mktintel)
     {
      m_trend = trend;
      m_vol = vol;
      m_news = news;
      m_supervisor = supervisor;
      m_mktintel = mktintel;
      if(m_logger != NULL)
         m_logger.Info("Order Flow sources bound | Trend+Vol+News+Supervisor+MarketIntel", "AIOF");
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmOrderFlowResult Last(void) const { return m_last; }
   CGmFutureOrderFlowLayer *FutureLayer(void) { return GetPointer(m_future); }

   bool Analyze(void)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      m_sched.Signal();
      if(!m_sched.ShouldRun(now, GM_OF_THROTTLE_MS))
        {
         if(m_last.valid && m_sched.CacheValid(now))
           {
            m_last.from_cache = true;
            m_last.status = GM_OF_STATUS_CACHED;
            return true;
           }
         return m_last.valid;
        }

      m_sched.Begin(now);

      SGmOrderFlowResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.status = GM_OF_STATUS_RUNNING;
      r.may_execute = false;
      r.may_modify_risk = false;
      r.advisory_status = GM_OF_ADVISORY;

      if(m_bridge != NULL)
        {
         r.symbol = m_bridge.Symbol();
         r.session_id = m_bridge.SessionId();
        }
      if(StringLen(r.symbol) == 0)
        {
         r.status = GM_OF_STATUS_ERROR;
         m_sched.Complete(now);
         return false;
        }

      SGmTrendAnalysisResult trend;
      SGmVolatilityAnalysisResult vol;
      SGmNewsAnalysisResult news;
      SGmAssistantResult sup;
      SGmMarketIntelligenceResult mi;
      trend.Reset(); vol.Reset(); news.Reset(); sup.Reset(); mi.Reset();
      if(m_trend != NULL && m_trend.IsReady()) trend = m_trend.Last();
      if(m_vol != NULL && m_vol.IsReady()) vol = m_vol.Last();
      if(m_news != NULL && m_news.IsReady()) news = m_news.Last();
      if(m_supervisor != NULL && m_supervisor.IsReady()) sup = m_supervisor.Last();
      if(m_mktintel != NULL && m_mktintel.IsReady()) mi = m_mktintel.Last();

      m_session.Analyze(vol, trend, mi, r);
      if(m_logger != NULL)
         m_logger.Info("Session Detected | " + GmOfSessionName(r.active_session), "AIOF");

      m_orderflow.Analyze(trend, vol, mi, r, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Order Flow Updated | Score=%.0f", r.order_flow_score), "AIOF");

      m_energy.Analyze(trend, vol, mi, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Energy Calculated | Score=%.0f Dir=%s",
                                    r.energy_score, r.energy_direction), "AIOF");

      m_personality.Analyze(r, news, sup, mi, r);
      m_temperature.Analyze(r, r);
      if(m_logger != NULL)
         m_logger.Info("Temperature Updated | " + GmOfTempName(r.market_temperature), "AIOF");

      r.center_status = "ORDER FLOW READY";
      r.status = GM_OF_STATUS_READY;
      r.insight = StringFormat("%s | Sess=%s OF=%.0f Energy=%.0f Temp=%s Hist=%.0f | %s",
                               r.center_status,
                               GmOfSessionName(r.active_session),
                               r.order_flow_score, r.energy_score,
                               GmOfTempName(r.market_temperature),
                               r.historical_session_success,
                               GM_OF_ANALYSIS_ONLY);
      r.valid = true;

      m_db.Record(r);
      m_last = r;
      m_sched.Complete(GetTickCount());

      if(m_logger != NULL)
         m_logger.Info("Dashboard Refreshed | Order Flow pending=" +
                       IntegerToString(m_sched.Pending()), "AIOF");
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = m_last.center_status;
      s.ai_engine = "GoldMind AI Order Flow Intelligence";
      s.current_mode = "AI_ORDER_FLOW";
      s.confidence_pct = GmOfClamp(0.4 * m_last.order_flow_score + 0.3 * m_last.energy_score +
                                   0.3 * m_last.session_strength);
      s.confidence_status = StringFormat("%.0f", s.confidence_pct);

      // Phase 5 Sprint 2 widgets (last-wins)
      s.w_trend_detector = GmOfSessionName(m_last.active_session);               // Current Trading Session
      s.future_ai_score = StringFormat("%.0f", m_last.session_strength);         // Session Strength
      s.w_recovery_ai = StringFormat("%.0f | %s", m_last.energy_score,
                                     m_last.energy_direction);                   // Market Energy
      s.prediction_status = StringFormat("%.0f", m_last.buying_energy);          // Buying Pressure
      s.learning_status = StringFormat("%.0f", m_last.selling_energy);           // Selling Pressure
      s.w_volatility_scanner = StringFormat("%.0f/100", m_last.order_flow_score); // Order Flow Score
      s.w_market_analyzer = StringFormat("%.0f", m_last.institutional_activity_index); // Inst Activity
      s.w_news_analyzer = StringFormat("%s (%.0f)",
                                       GmOfTempName(m_last.market_temperature),
                                       m_last.temperature_index);                // Market Temperature
      s.w_trade_confidence = StringFormat("%s | Str=%.0f Vol=%.0f",
                                          GmOfPersonalityName(m_last.session_personality),
                                          m_last.session_strength,
                                          m_last.session_volatility);            // Session Statistics
      s.ai_version = StringFormat("%.0f%%", m_last.historical_session_success);  // Historical Session Success
      s.decision_status = GM_OF_ADVISORY;
     }
  };

#endif // GM_CAI_ORDER_FLOW_INTELLIGENCE_ENGINE_MQH
//+------------------------------------------------------------------+
