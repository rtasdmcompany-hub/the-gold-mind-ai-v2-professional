//+------------------------------------------------------------------+
//|                                          CAIDashboardEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     Phase 2 Sprint 6 — AI Dashboard Foundation (READ-ONLY)      |
//+------------------------------------------------------------------+
#ifndef GM_CAI_DASHBOARD_ENGINE_MQH
#define GM_CAI_DASHBOARD_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CAIBase.mqh"
#include "CAIEventEngine.mqh"
#include "CAIDatabase.mqh"
#include "CAIApi.mqh"
#include "CAIDecisionCenter.mqh"
#include "CAIDataProvider.mqh"
#include "Market/Module.MarketAnalysis.mqh"
#include "Trend/Module.TrendAI.mqh"
#include "Volatility/Module.VolatilityAI.mqh"
#include "News/Module.NewsAI.mqh"
#include "Confidence/Module.ConfidenceAI.mqh"
#include "Learning/Module.LearningAI.mqh"
#include "Decision/Module.DecisionAI.mqh"
#include "AIValidation/Module.AIValidation.mqh"
#include "Assistant/Module.AssistantAI.mqh"
#include "Intelligence/Module.IntelligenceAI.mqh"
#include "Memory/Module.MemoryAI.mqh"
#include "Reporting/Module.ReportingAI.mqh"
#include "Conversation/Module.ConversationAI.mqh"
#include "Enterprise/Module.EnterpriseAI.mqh"
#include "RiskIntelligence/Module.RiskIntelligenceAI.mqh"
#include "Forecasting/Module.ForecastingAI.mqh"
#include "Orchestration/Module.OrchestrationAI.mqh"
#include "MasterControl/Module.MasterControlAI.mqh"
#include "MarketIntelligence/Module.MarketIntelligenceAI.mqh"
#include "OrderFlow/Module.OrderFlowAI.mqh"
#include "NewsIntelligence/Module.NewsIntelligenceAI.mqh"
#include "RecoveryIntelligence/Module.RecoveryIntelligenceAI.mqh"
#include "MultiTimeframe/Module.MultiTimeframeAI.mqh"
#include "PortfolioIntelligence/Module.PortfolioIntelligenceAI.mqh"
#include "PredictiveIntelligence/Module.PredictiveIntelligenceAI.mqh"
#include "ExecutionSupervisor/Module.ExecutionSupervisorAI.mqh"
#include "SelfLearning/Module.SelfLearningAI.mqh"
#include "../Core/CFileManager.mqh"
#include "../Phase2/CPhase2Bridge.mqh"
#include "../Analytics/CAnalyticsEngine.mqh"
#include "../Recovery/CRecoveryBase.mqh"

/// @file CAIDashboardEngine.mqh
/// @brief Independent AI Dashboard Engine — observation only.
/// @warning NEVER opens/closes/modifies trades, risk, or strategy.

class CGmAIDashboardEngine : public CGmAIBase
  {
private:
   CGmFileManager       *m_files;
   CGmPhase2Bridge      *m_bridge;
   CGmAnalyticsEngine   *m_analytics;
   CGmRecoveryBase      *m_recovery;

   CGmAIEventEngine      m_events;
   CGmAIDatabase         m_db;
   CGmAIApi              m_api;
   CGmAIDecisionCenter   m_decision;
   CGmAIDataProvider     m_data;
   CGmAIMarketAnalyzer  *m_market;
   CGmAITrendEngine     *m_trend;
   CGmAIVolatilityEngine *m_vol;
   CGmAINewsEngine      *m_news;
   CGmAIConfidenceEngine *m_conf;
   CGmAILearningEngine  *m_learn;
   CGmAIDecisionSupportEngine *m_dec_support;
   CGmAIValidationEngine *m_aival;
   CGmAISupervisorEngine *m_assist;
   CGmAIDecisionIntelligenceEngine *m_intel;
   CGmAILearningMemoryEngine *m_memlearn;
   CGmAIEnterpriseReportingEngine *m_aireport;
   CGmAIConversationalAssistantEngine *m_aichat;
   CGmAIEnterpriseMonitoringEngine *m_entmon;
   CGmAIRiskIntelligenceEngine *m_riskintel;
   CGmAIForecastingEngine *m_forecast;
   CGmAIOrchestrationEngine *m_orch;
   CGmAIMasterControlEngine *m_master;
   CGmAIMarketIntelligenceEngine *m_mktintel;
   CGmAIOrderFlowIntelligenceEngine *m_orderflow;
   CGmAINewsIntelligenceEngine *m_newsintel;
   CGmAIRecoveryIntelligenceEngine *m_recintel;
   CGmAIMultiTimeframeEngine *m_mtfintel;
   CGmAIPortfolioIntelligenceEngine *m_portintel;
   CGmAIPredictiveIntelligenceEngine *m_predintel;
   CGmAIExecutionSupervisorEngine *m_execsup;
   CGmAISelfLearningPlatformEngine *m_selflearn;

   SGmAISnapshot         m_snap;
   SGmAISnapshot         m_cert_overlay;
   bool                  m_have_cert;
   bool                  m_ready;
   bool                  m_widgets_loaded;

public:
                     CGmAIDashboardEngine(void)
                       : m_files(NULL), m_bridge(NULL), m_analytics(NULL),
                         m_recovery(NULL), m_market(NULL), m_trend(NULL),
                         m_vol(NULL), m_news(NULL), m_conf(NULL), m_learn(NULL),
                         m_dec_support(NULL), m_aival(NULL), m_assist(NULL), m_intel(NULL),
                         m_memlearn(NULL), m_aireport(NULL), m_aichat(NULL), m_entmon(NULL),
                         m_riskintel(NULL), m_forecast(NULL), m_orch(NULL), m_master(NULL),
                         m_mktintel(NULL), m_orderflow(NULL), m_newsintel(NULL),
                         m_recintel(NULL), m_mtfintel(NULL), m_portintel(NULL),
                         m_predintel(NULL), m_execsup(NULL), m_selflearn(NULL),
                         m_have_cert(false),
                         m_ready(false), m_widgets_loaded(false)
     {
      m_module_name = "AIDashboard";
      m_snap.Reset();
      m_cert_overlay.Reset();
     }

                    ~CGmAIDashboardEngine(void) { Shutdown(); }

   bool InitFull(CGmLogger *logger,
                 CGmFileManager *files,
                 CGmPhase2Bridge *bridge,
                 CGmAnalyticsEngine *analytics,
                 CGmRecoveryBase *recovery,
                 const long magic,
                 const string symbol)
     {
      m_logger = logger;
      m_files = files;
      m_bridge = bridge;
      m_analytics = analytics;
      m_recovery = recovery;

      m_events.Init(logger);
      m_db.Init(logger, files, magic, symbol);
      m_api.Init(logger);
      m_decision.Init(logger);
      m_data.Init(logger, bridge, analytics, recovery, GetPointer(m_decision));

      m_status = GM_MODULE_IDLE;
      m_ready = true;
      m_widgets_loaded = true;

      m_events.Raise(GM_AI_EVT_STARTED, "AIDashboard",
                     "AI Dashboard Started | foundation only", 0.0,
                     (bridge != NULL) ? bridge.SessionId() : 0);
      m_db.AddLog("AI Dashboard Started");
      m_db.AddLog("AI Widgets Loaded");
      m_db.AddLog("API Ready");
      m_db.AddLog("Database Ready");

      Collect(true);

      if(m_logger != NULL)
         m_logger.Success("AI Dashboard Started | Decision Center=" + GM_AI_NOT_INITIALIZED +
                          " | READ-ONLY",
                          m_module_name);
      return true;
     }

   virtual bool Init(CGmLogger *logger)
     {
      // Prefer InitFull from Application — keep base contract
      m_logger = logger;
      m_status = GM_MODULE_IDLE;
      if(m_logger != NULL)
         m_logger.Info("AI base Init — call InitFull for Sprint 6 foundation", m_module_name);
      return true;
     }

   virtual void Shutdown(void)
     {
      if(m_ready)
        {
         m_events.Raise(GM_AI_EVT_STOPPED, "AIDashboard", "AI Dashboard Stopped", 0.0, 0);
         m_db.AddLog("AI Dashboard Stopped");
         m_db.Shutdown();
        }
      m_decision.Shutdown();
      m_ready = false;
      m_status = GM_MODULE_DISABLED;
     }

   bool IsReady(void) const { return m_ready; }
   bool WidgetsLoaded(void) const { return m_widgets_loaded; }

   CGmAIEventEngine *Events(void) { return GetPointer(m_events); }
   CGmAIDatabase *Database(void) { return GetPointer(m_db); }
   CGmAIApi *Api(void) { return GetPointer(m_api); }
   CGmAIDecisionCenter *DecisionCenter(void) { return GetPointer(m_decision); }
   CGmAIDataProvider *DataProvider(void) { return GetPointer(m_data); }
   SGmAISnapshot Snapshot(void) const { return m_snap; }

   void BindMarketAnalyzer(CGmAIMarketAnalyzer *market)
     {
      m_market = market;
      if(m_logger != NULL && market != NULL)
         m_logger.Info("AI Dashboard bound to Market Analyzer", m_module_name);
     }

   void BindTrendEngine(CGmAITrendEngine *trend)
     {
      m_trend = trend;
      if(m_logger != NULL && trend != NULL)
         m_logger.Info("AI Dashboard bound to Trend Engine", m_module_name);
     }

   void BindVolatilityEngine(CGmAIVolatilityEngine *vol)
     {
      m_vol = vol;
      if(m_logger != NULL && vol != NULL)
         m_logger.Info("AI Dashboard bound to Volatility Engine", m_module_name);
     }

   void BindNewsEngine(CGmAINewsEngine *news)
     {
      m_news = news;
      if(m_logger != NULL && news != NULL)
         m_logger.Info("AI Dashboard bound to News Engine", m_module_name);
     }

   void BindConfidenceEngine(CGmAIConfidenceEngine *conf)
     {
      m_conf = conf;
      if(m_logger != NULL && conf != NULL)
         m_logger.Info("AI Dashboard bound to Confidence Engine", m_module_name);
     }

   void BindLearningEngine(CGmAILearningEngine *learn)
     {
      m_learn = learn;
      if(m_logger != NULL && learn != NULL)
         m_logger.Info("AI Dashboard bound to Learning Engine", m_module_name);
     }

   void BindDecisionSupportEngine(CGmAIDecisionSupportEngine *decision)
     {
      m_dec_support = decision;
      if(m_logger != NULL && decision != NULL)
         m_logger.Info("AI Dashboard bound to Decision Support Engine", m_module_name);
     }

   void BindAIValidationEngine(CGmAIValidationEngine *aival)
     {
      m_aival = aival;
      if(m_logger != NULL && aival != NULL)
         m_logger.Info("AI Dashboard bound to AI Validation Engine", m_module_name);
     }

   void BindSupervisorEngine(CGmAISupervisorEngine *assist)
     {
      m_assist = assist;
      if(m_logger != NULL && assist != NULL)
         m_logger.Info("AI Dashboard bound to AI Supervisor Engine", m_module_name);
     }

   void BindDecisionIntelligenceEngine(CGmAIDecisionIntelligenceEngine *intel)
     {
      m_intel = intel;
      if(m_logger != NULL && intel != NULL)
         m_logger.Info("AI Dashboard bound to Decision Intelligence Engine", m_module_name);
     }

   void BindLearningMemoryEngine(CGmAILearningMemoryEngine *mem)
     {
      m_memlearn = mem;
      if(m_logger != NULL && mem != NULL)
         m_logger.Info("AI Dashboard bound to Learning Memory Engine", m_module_name);
     }

   void BindEnterpriseReportingEngine(CGmAIEnterpriseReportingEngine *rpt)
     {
      m_aireport = rpt;
      if(m_logger != NULL && rpt != NULL)
         m_logger.Info("AI Dashboard bound to Enterprise Reporting Engine", m_module_name);
     }

   void BindConversationalAssistantEngine(CGmAIConversationalAssistantEngine *chat)
     {
      m_aichat = chat;
      if(m_logger != NULL && chat != NULL)
         m_logger.Info("AI Dashboard bound to Conversational Assistant Engine", m_module_name);
     }

   void BindEnterpriseMonitoringEngine(CGmAIEnterpriseMonitoringEngine *ent)
     {
      m_entmon = ent;
      if(m_logger != NULL && ent != NULL)
         m_logger.Info("AI Dashboard bound to Enterprise Monitoring Engine", m_module_name);
     }

   void BindRiskIntelligenceEngine(CGmAIRiskIntelligenceEngine *risk)
     {
      m_riskintel = risk;
      if(m_logger != NULL && risk != NULL)
         m_logger.Info("AI Dashboard bound to Risk Intelligence Engine", m_module_name);
     }

   void BindForecastingEngine(CGmAIForecastingEngine *fcst)
     {
      m_forecast = fcst;
      if(m_logger != NULL && fcst != NULL)
         m_logger.Info("AI Dashboard bound to Forecasting Engine", m_module_name);
     }

   void BindOrchestrationEngine(CGmAIOrchestrationEngine *orch)
     {
      m_orch = orch;
      if(m_logger != NULL && orch != NULL)
         m_logger.Info("AI Dashboard bound to Orchestration / Command Center", m_module_name);
     }

   void BindMasterControlEngine(CGmAIMasterControlEngine *master)
     {
      m_master = master;
      if(m_logger != NULL && master != NULL)
         m_logger.Info("AI Dashboard bound to Master Control Center", m_module_name);
     }

   void BindMarketIntelligenceEngine(CGmAIMarketIntelligenceEngine *mi)
     {
      m_mktintel = mi;
      if(m_logger != NULL && mi != NULL)
         m_logger.Info("AI Dashboard bound to Market Intelligence Engine", m_module_name);
     }

   void BindOrderFlowIntelligenceEngine(CGmAIOrderFlowIntelligenceEngine *of)
     {
      m_orderflow = of;
      if(m_logger != NULL && of != NULL)
         m_logger.Info("AI Dashboard bound to Order Flow Intelligence Engine", m_module_name);
     }

   void BindNewsIntelligenceEngine(CGmAINewsIntelligenceEngine *ni)
     {
      m_newsintel = ni;
      if(m_logger != NULL && ni != NULL)
         m_logger.Info("AI Dashboard bound to News Intelligence Engine", m_module_name);
     }

   void BindRecoveryIntelligenceEngine(CGmAIRecoveryIntelligenceEngine *ri)
     {
      m_recintel = ri;
      if(m_logger != NULL && ri != NULL)
         m_logger.Info("AI Dashboard bound to Recovery Intelligence Engine", m_module_name);
     }

   void BindMultiTimeframeEngine(CGmAIMultiTimeframeEngine *mtf)
     {
      m_mtfintel = mtf;
      if(m_logger != NULL && mtf != NULL)
         m_logger.Info("AI Dashboard bound to Multi-Timeframe Intelligence Engine", m_module_name);
     }

   void BindPortfolioIntelligenceEngine(CGmAIPortfolioIntelligenceEngine *pi)
     {
      m_portintel = pi;
      if(m_logger != NULL && pi != NULL)
         m_logger.Info("AI Dashboard bound to Portfolio Intelligence Engine", m_module_name);
     }

   void BindPredictiveIntelligenceEngine(CGmAIPredictiveIntelligenceEngine *pred)
     {
      m_predintel = pred;
      if(m_logger != NULL && pred != NULL)
         m_logger.Info("AI Dashboard bound to Predictive Intelligence Engine", m_module_name);
     }

   void BindExecutionSupervisorEngine(CGmAIExecutionSupervisorEngine *es)
     {
      m_execsup = es;
      if(m_logger != NULL && es != NULL)
         m_logger.Info("AI Dashboard bound to Execution Supervisor Engine", m_module_name);
     }

   void BindSelfLearningPlatformEngine(CGmAISelfLearningPlatformEngine *sl)
     {
      m_selflearn = sl;
      if(m_logger != NULL && sl != NULL)
         m_logger.Info("AI Dashboard bound to Self-Learning Platform Engine", m_module_name);
     }

   /// @brief Persist Phase 5 certification overlay (re-applied after each Collect).
   void PushSnapshot(const SGmAISnapshot &s)
     {
      m_snap = s;
      m_cert_overlay = s;
      m_have_cert = true;
     }

   bool Collect(const bool force)
     {
      if(!m_ready)
         return false;
      const datetime prev_stamp = m_snap.stamped_at;
      SGmAISnapshot s;
      if(!m_data.Collect(s, force))
         return false;
      if(m_market != NULL && m_market.IsReady())
        {
         m_market.Analyze();
         m_market.ApplyToAISnapshot(s);
        }
      if(m_trend != NULL && m_trend.IsReady())
        {
         m_trend.Analyze();
         m_trend.ApplyToAISnapshot(s);
        }
      if(m_vol != NULL && m_vol.IsReady())
        {
         m_vol.Analyze();
         m_vol.ApplyToAISnapshot(s);
        }
      if(m_news != NULL && m_news.IsReady())
        {
         m_news.Analyze();
         m_news.ApplyToAISnapshot(s);
        }
      if(m_conf != NULL && m_conf.IsReady())
        {
         m_conf.Analyze();
         m_conf.ApplyToAISnapshot(s);
        }
      if(m_learn != NULL && m_learn.IsReady())
        {
         m_learn.Analyze();
         m_learn.ApplyToAISnapshot(s);
        }
      if(m_dec_support != NULL && m_dec_support.IsReady())
        {
         m_dec_support.Analyze();
         m_dec_support.ApplyToAISnapshot(s);
        }
      if(m_aival != NULL && m_aival.IsReady())
        {
         m_aival.Analyze();
         m_aival.ApplyToAISnapshot(s);
        }
      if(m_assist != NULL && m_assist.IsReady())
        {
         m_assist.SetDashboardOk(true);
         m_assist.Analyze();
         m_assist.ApplyToAISnapshot(s);
        }
      if(m_intel != NULL && m_intel.IsReady())
        {
         m_intel.Analyze();
         m_intel.ApplyToAISnapshot(s);
        }
      if(m_memlearn != NULL && m_memlearn.IsReady())
        {
         m_memlearn.Analyze();
         m_memlearn.ApplyToAISnapshot(s);
        }
      if(m_aireport != NULL && m_aireport.IsReady())
        {
         m_aireport.Analyze();
         m_aireport.ApplyToAISnapshot(s);
        }
      if(m_aichat != NULL && m_aichat.IsReady())
        {
         m_aichat.Analyze();
         m_aichat.ApplyToAISnapshot(s);
        }
      if(m_entmon != NULL && m_entmon.IsReady())
        {
         m_entmon.SetDashboardOk(true);
         m_entmon.SetCoreOk(true);
         m_entmon.Analyze();
         m_entmon.ApplyToAISnapshot(s);
        }
      if(m_riskintel != NULL && m_riskintel.IsReady())
        {
         m_riskintel.Analyze();
         m_riskintel.ApplyToAISnapshot(s);
        }
      if(m_forecast != NULL && m_forecast.IsReady())
        {
         m_forecast.Analyze();
         m_forecast.ApplyToAISnapshot(s);
        }
      if(m_orch != NULL && m_orch.IsReady())
        {
         m_orch.Analyze();
         m_orch.ApplyToAISnapshot(s);
        }
      if(m_master != NULL && m_master.IsReady())
        {
         m_master.Analyze();
         m_master.ApplyToAISnapshot(s);
        }
      if(m_mktintel != NULL && m_mktintel.IsReady())
        {
         m_mktintel.Analyze();
         m_mktintel.ApplyToAISnapshot(s);
        }
      if(m_orderflow != NULL && m_orderflow.IsReady())
        {
         m_orderflow.Analyze();
         m_orderflow.ApplyToAISnapshot(s);
        }
      if(m_newsintel != NULL && m_newsintel.IsReady())
        {
         m_newsintel.Analyze();
         m_newsintel.ApplyToAISnapshot(s);
        }
      if(m_recintel != NULL && m_recintel.IsReady())
        {
         m_recintel.Analyze();
         m_recintel.ApplyToAISnapshot(s);
        }
      if(m_mtfintel != NULL && m_mtfintel.IsReady())
        {
         m_mtfintel.Analyze();
         m_mtfintel.ApplyToAISnapshot(s);
        }
      if(m_portintel != NULL && m_portintel.IsReady())
        {
         m_portintel.Analyze();
         m_portintel.ApplyToAISnapshot(s);
        }
      if(m_predintel != NULL && m_predintel.IsReady())
        {
         m_predintel.Analyze();
         m_predintel.ApplyToAISnapshot(s);
        }
      if(m_execsup != NULL && m_execsup.IsReady())
        {
         m_execsup.Analyze();
         m_execsup.ApplyToAISnapshot(s);
        }
      if(m_selflearn != NULL && m_selflearn.IsReady())
        {
         m_selflearn.Analyze();
         m_selflearn.ApplyToAISnapshot(s);
        }
      if(m_have_cert)
        {
         // Phase 5 Sprint 10 certification widgets (last-wins)
         s.ai_status = m_cert_overlay.ai_status;
         s.ai_engine = m_cert_overlay.ai_engine;
         s.current_mode = m_cert_overlay.current_mode;
         s.confidence_pct = m_cert_overlay.confidence_pct;
         s.confidence_status = m_cert_overlay.confidence_status;
         s.w_trend_detector = m_cert_overlay.w_trend_detector;
         s.future_ai_score = m_cert_overlay.future_ai_score;
         s.w_recovery_ai = m_cert_overlay.w_recovery_ai;
         s.prediction_status = m_cert_overlay.prediction_status;
         s.learning_status = m_cert_overlay.learning_status;
         s.w_volatility_scanner = m_cert_overlay.w_volatility_scanner;
         s.w_market_analyzer = m_cert_overlay.w_market_analyzer;
         s.w_news_analyzer = m_cert_overlay.w_news_analyzer;
         s.w_trade_confidence = m_cert_overlay.w_trade_confidence;
         s.ai_version = m_cert_overlay.ai_version;
         s.decision_status = m_cert_overlay.decision_status;
        }
      m_snap = s;
      m_db.RecordCollectUs(s.collect_us);
      if(force || s.stamped_at != prev_stamp)
        {
         m_events.Raise(GM_AI_EVT_DATA_UPDATED, "AIDataProvider",
                        StringFormat("collect=%I64u us", s.collect_us),
                        s.confidence_pct, s.h4_session_id);
        }
      if(m_logger != NULL && (force || s.stamped_at != prev_stamp))
         m_logger.Debug(StringFormat("Performance | AI collect=%I64u us | mem=%I64u",
                                     s.collect_us, s.memory_kb),
                        m_module_name);
      return true;
     }

   void Process(void)
     {
      Collect(false);
     }

   /// @brief Evaluate remains disabled — no AI trading decisions.
   virtual bool Evaluate(void)
     {
      string reason = "";
      m_decision.RequestDecision(reason);
      if(m_logger != NULL)
         m_logger.Debug(reason, m_module_name);
      return false;
     }
  };

#endif // GM_CAI_DASHBOARD_ENGINE_MQH
//+------------------------------------------------------------------+
