//+------------------------------------------------------------------+
//|                                              CAICoreEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     Phase 3 Sprint 1 — Independent AI Intelligence Layer        |
//+------------------------------------------------------------------+
#ifndef GM_CAI_CORE_ENGINE_MQH
#define GM_CAI_CORE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "Phase3AIConstants.mqh"
#include "SGmAICoreSettings.mqh"
#include "CAISecurityGuard.mqh"
#include "CAIStateManager.mqh"
#include "CAIContextManager.mqh"
#include "CAIMemoryManager.mqh"
#include "CAIDecisionQueue.mqh"
#include "CAIEventDispatcher.mqh"
#include "CAIDataBus.mqh"
#include "CAICoreDatabase.mqh"
#include "CAICorePerfMonitor.mqh"
#include "CAICoreApi.mqh"
#include "CAIController.mqh"
#include "CAIManager.mqh"
#include "../Market/Module.MarketAnalysis.mqh"
#include "../Trend/Module.TrendAI.mqh"
#include "../Volatility/Module.VolatilityAI.mqh"
#include "../News/Module.NewsAI.mqh"
#include "../Confidence/Module.ConfidenceAI.mqh"
#include "../Learning/Module.LearningAI.mqh"
#include "../Decision/Module.DecisionAI.mqh"
#include "../AIValidation/Module.AIValidation.mqh"
#include "../Assistant/Module.AssistantAI.mqh"
#include "../Intelligence/Module.IntelligenceAI.mqh"
#include "../Memory/Module.MemoryAI.mqh"
#include "../Reporting/Module.ReportingAI.mqh"
#include "../Conversation/Module.ConversationAI.mqh"
#include "../Enterprise/Module.EnterpriseAI.mqh"
#include "../RiskIntelligence/Module.RiskIntelligenceAI.mqh"
#include "../Forecasting/Module.ForecastingAI.mqh"
#include "../Orchestration/Module.OrchestrationAI.mqh"
#include "../MasterControl/Module.MasterControlAI.mqh"
#include "../MarketIntelligence/Module.MarketIntelligenceAI.mqh"
#include "../OrderFlow/Module.OrderFlowAI.mqh"
#include "../NewsIntelligence/Module.NewsIntelligenceAI.mqh"
#include "../RecoveryIntelligence/Module.RecoveryIntelligenceAI.mqh"
#include "../MultiTimeframe/Module.MultiTimeframeAI.mqh"
#include "../PortfolioIntelligence/Module.PortfolioIntelligenceAI.mqh"
#include "../PredictiveIntelligence/Module.PredictiveIntelligenceAI.mqh"
#include "../ExecutionSupervisor/Module.ExecutionSupervisorAI.mqh"
#include "../SelfLearning/Module.SelfLearningAI.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Analytics/CAnalyticsEngine.mqh"
#include "../../Recovery/CRecoveryBase.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

/// @file CAICoreEngine.mqh
/// @brief Root AI Core Engine — independent, ANALYSIS ONLY, no Core/Dash mutation.

class CGmAICoreEngine
  {
private:
   CGmLogger              *m_logger;
   SGmAICoreSettings       m_settings;
   CGmAISecurityGuard      m_security;
   CGmAIStateManager       m_state;
   CGmAIContextManager     m_context;
   CGmAIMemoryManager      m_memory;
   CGmAIDecisionQueue      m_queue;
   CGmAIEventDispatcher    m_events;
   CGmAIDataBus            m_bus;
   CGmAICoreDatabase       m_db;
   CGmAICorePerfMonitor    m_perf;
   CGmAICoreApi            m_api;
   CGmAIController         m_ctrl;
   CGmAIManager            m_manager;
   CGmAIMarketAnalyzer     m_market;
   CGmAITrendEngine        m_trend;
   CGmAIVolatilityEngine   m_vol;
   CGmAINewsEngine         m_news;
   CGmAIConfidenceEngine   m_conf;
   CGmAILearningEngine     m_learn;
   CGmAIDecisionSupportEngine m_decision;
   CGmAIValidationEngine   m_aival;
   CGmAISupervisorEngine   m_assist;
   CGmAIDecisionIntelligenceEngine m_intel;
   CGmAILearningMemoryEngine m_memlearn;
   CGmAIEnterpriseReportingEngine m_aireport;
   CGmAIConversationalAssistantEngine m_aichat;
   CGmAIEnterpriseMonitoringEngine m_entmon;
   CGmAIRiskIntelligenceEngine m_riskintel;
   CGmAIForecastingEngine m_forecast;
   CGmAIOrchestrationEngine m_orch;
   CGmAIMasterControlEngine m_master;
   CGmAIMarketIntelligenceEngine m_mktintel;
   CGmAIOrderFlowIntelligenceEngine m_orderflow;
   CGmAINewsIntelligenceEngine m_newsintel;
   CGmAIRecoveryIntelligenceEngine m_recintel;
   CGmAIMultiTimeframeEngine m_mtfintel;
   CGmAIPortfolioIntelligenceEngine m_portintel;
   CGmAIPredictiveIntelligenceEngine m_predintel;
   CGmAIExecutionSupervisorEngine m_execsup;
   CGmAISelfLearningPlatformEngine m_selflearn;
   ulong                   m_last_process_ms;
   bool                    m_ready;

public:
                     CGmAICoreEngine(void)
                       : m_logger(NULL), m_last_process_ms(0), m_ready(false)
     {
      m_settings.Defaults();
     }

                    ~CGmAICoreEngine(void)
     {
      Shutdown();
     }

   bool Init(CGmLogger *logger,
             CGmFileManager *files,
             CGmPhase2Bridge *bridge,
             CGmAnalyticsEngine *analytics,
             CGmRecoveryBase *recovery,
             const SGmAICoreSettings &settings,
             const long magic,
             const string symbol)
     {
      m_logger = logger;
      m_settings = settings;
      m_settings.Clamp();

      if(m_logger != NULL)
         m_logger.Info("AI Started | " + GM_AI_CORE_LABEL + " | " + GM_AI_CORE_VERSION,
                       "AICore");

      m_security.Init(logger);
      m_state.Init(logger);
      m_events.Init(logger);
      m_memory.Init();
      m_queue.Init();
      m_perf.Init(logger);
      m_api.Init(logger);
      m_context.Init(logger, m_settings);
      m_db.Init(logger, files, magic, symbol);
      m_bus.Init(logger, bridge, analytics, recovery, m_settings);
      m_ctrl.Init(logger, GetPointer(m_state), GetPointer(m_security),
                  GetPointer(m_events), m_settings);
      m_manager.Init(logger, GetPointer(m_bus), GetPointer(m_context),
                     GetPointer(m_memory), GetPointer(m_queue), GetPointer(m_db),
                     GetPointer(m_state), GetPointer(m_events),
                     GetPointer(m_ctrl), GetPointer(m_api));
      m_market.Init(logger, files, bridge, magic, symbol);
      m_trend.Init(logger, files, bridge, magic, symbol);
      m_vol.Init(logger, files, bridge, magic, symbol);
      m_news.Init(logger, files, bridge, magic, symbol);
      m_conf.Init(logger, files, bridge, magic, symbol);
      m_conf.BindSources(GetPointer(m_trend), GetPointer(m_vol), GetPointer(m_news));
      m_learn.Init(logger, files, bridge, magic, symbol);
      m_learn.BindSources(GetPointer(m_trend), GetPointer(m_vol), GetPointer(m_news),
                          GetPointer(m_conf), analytics);
      m_decision.Init(logger, files, bridge, magic, symbol);
      m_decision.BindSources(GetPointer(m_trend), GetPointer(m_vol), GetPointer(m_news),
                             GetPointer(m_conf), GetPointer(m_learn));
      m_aival.Init(logger, files, bridge, magic, symbol);
      m_aival.BindSources(GetPointer(m_trend), GetPointer(m_vol), GetPointer(m_news),
                          GetPointer(m_conf), GetPointer(m_learn), GetPointer(m_decision));
      m_assist.Init(logger, files, bridge, analytics, recovery, magic, symbol);
      m_assist.BindSources(GetPointer(m_trend), GetPointer(m_vol), GetPointer(m_news),
                           GetPointer(m_conf), GetPointer(m_learn), GetPointer(m_aival));
      m_intel.Init(logger, files, bridge, analytics, magic, symbol);
      m_intel.BindSources(GetPointer(m_trend), GetPointer(m_vol), GetPointer(m_news),
                          GetPointer(m_conf), GetPointer(m_learn), GetPointer(m_assist));
      m_memlearn.Init(logger, files, bridge, analytics, magic, symbol);
      m_memlearn.BindSources(GetPointer(m_trend), GetPointer(m_vol), GetPointer(m_news),
                             GetPointer(m_learn), GetPointer(m_assist), GetPointer(m_intel));
      m_aireport.Init(logger, files, bridge, analytics, magic, symbol);
      m_aireport.BindSources(GetPointer(m_learn), GetPointer(m_assist),
                             GetPointer(m_intel), GetPointer(m_memlearn));
      m_aichat.Init(logger, files, bridge, magic, symbol);
      m_aichat.BindSources(GetPointer(m_vol), GetPointer(m_assist),
                           GetPointer(m_intel), GetPointer(m_memlearn),
                           GetPointer(m_aireport));
      m_entmon.Init(logger, files, bridge, magic, symbol);
      m_entmon.BindSources(GetPointer(m_assist), GetPointer(m_intel),
                           GetPointer(m_memlearn), GetPointer(m_aireport),
                           GetPointer(m_aichat), NULL);
      m_entmon.SetCoreOk(true);
      m_riskintel.Init(logger, files, bridge, analytics, magic, symbol);
      m_riskintel.BindSources(GetPointer(m_assist), GetPointer(m_intel),
                              GetPointer(m_entmon));
      m_forecast.Init(logger, files, bridge, magic, symbol);
      m_forecast.BindSources(GetPointer(m_trend), GetPointer(m_vol),
                             GetPointer(m_intel), GetPointer(m_assist),
                             GetPointer(m_riskintel));
      m_orch.Init(logger, files, bridge, magic, symbol);
      m_orch.BindSources(GetPointer(m_intel), GetPointer(m_riskintel),
                         GetPointer(m_forecast), GetPointer(m_memlearn),
                         GetPointer(m_assist), GetPointer(m_aireport),
                         GetPointer(m_vol));
      m_master.Init(logger, files, bridge, magic, symbol);
      m_master.BindSources(GetPointer(m_assist), GetPointer(m_intel),
                           GetPointer(m_memlearn), GetPointer(m_aireport),
                           GetPointer(m_riskintel), GetPointer(m_forecast),
                           GetPointer(m_aichat), GetPointer(m_entmon),
                           GetPointer(m_orch));
      m_mktintel.Init(logger, files, bridge, magic, symbol);
      m_mktintel.BindSources(GetPointer(m_trend), GetPointer(m_vol),
                             GetPointer(m_news), GetPointer(m_assist));
      m_orderflow.Init(logger, files, bridge, magic, symbol);
      m_orderflow.BindSources(GetPointer(m_trend), GetPointer(m_vol),
                              GetPointer(m_news), GetPointer(m_assist),
                              GetPointer(m_mktintel));
      m_newsintel.Init(logger, files, bridge, magic, symbol);
      m_newsintel.BindSources(GetPointer(m_news), GetPointer(m_trend),
                              GetPointer(m_vol), GetPointer(m_orderflow));
      m_recintel.Init(logger, files, bridge, analytics, recovery, magic, symbol);
      m_recintel.BindSources(GetPointer(m_assist), GetPointer(m_trend),
                             GetPointer(m_vol), GetPointer(m_newsintel));
      m_mtfintel.Init(logger, files, bridge, magic, symbol);
      m_mtfintel.BindSources(GetPointer(m_trend), GetPointer(m_vol),
                             GetPointer(m_orderflow), GetPointer(m_newsintel),
                             GetPointer(m_recintel), GetPointer(m_mktintel));
      m_portintel.Init(logger, files, bridge, analytics, magic, symbol);
      m_portintel.BindSources(GetPointer(m_assist), GetPointer(m_trend),
                              GetPointer(m_orderflow), GetPointer(m_recintel),
                              GetPointer(m_riskintel), GetPointer(m_entmon));
      m_predintel.Init(logger, files, bridge, magic, symbol);
      m_predintel.BindSources(GetPointer(m_trend), GetPointer(m_vol),
                              GetPointer(m_orderflow), GetPointer(m_newsintel),
                              GetPointer(m_mktintel), GetPointer(m_mtfintel),
                              GetPointer(m_recintel), GetPointer(m_forecast));
      m_execsup.Init(logger, files, bridge, analytics, magic, symbol);
      m_execsup.BindSources(GetPointer(m_assist), GetPointer(m_trend),
                            GetPointer(m_vol), GetPointer(m_orderflow),
                            GetPointer(m_newsintel), GetPointer(m_recintel));
      m_selflearn.Init(logger, files, bridge, analytics, magic, symbol);
      m_selflearn.BindSources(GetPointer(m_learn), GetPointer(m_memlearn),
                              GetPointer(m_assist), GetPointer(m_orderflow),
                              GetPointer(m_newsintel), GetPointer(m_recintel),
                              GetPointer(m_predintel), GetPointer(m_execsup),
                              GetPointer(m_aival));

      m_ready = true;
      m_events.Dispatch("AI Initialized", GmAICoreModeName(m_settings.mode));

      if(!m_settings.enable_ai)
        {
         m_ctrl.Disable();
         if(m_logger != NULL)
            m_logger.Info("AI Core disabled by configuration", "AICore");
         return true;
        }

      m_state.SetState(GM_AI_CORE_STATE_MONITORING);
      if(m_logger != NULL)
         m_logger.Success(StringFormat("AI Initialized | mode=%s | ANALYSIS ONLY | security=ON",
                                       GmAICoreModeName(m_settings.mode)),
                          "AICore");
      return true;
     }

   void Shutdown(void)
     {
      if(!m_ready)
         return;
      m_events.Dispatch("AI Stopped", "");
      m_selflearn.Shutdown();
      m_execsup.Shutdown();
      m_predintel.Shutdown();
      m_portintel.Shutdown();
      m_mtfintel.Shutdown();
      m_recintel.Shutdown();
      m_newsintel.Shutdown();
      m_orderflow.Shutdown();
      m_mktintel.Shutdown();
      m_master.Shutdown();
      m_orch.Shutdown();
      m_forecast.Shutdown();
      m_riskintel.Shutdown();
      m_entmon.Shutdown();
      m_aichat.Shutdown();
      m_aireport.Shutdown();
      m_memlearn.Shutdown();
      m_intel.Shutdown();
      m_assist.Shutdown();
      m_aival.Shutdown();
      m_decision.Shutdown();
      m_learn.Shutdown();
      m_conf.Shutdown();
      m_news.Shutdown();
      m_vol.Shutdown();
      m_trend.Shutdown();
      m_market.Shutdown();
      m_db.Shutdown();
      m_state.SetState(GM_AI_CORE_STATE_DISABLED);
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   bool IsEnabled(void) const { return m_settings.enable_ai && m_ready; }
   ENUM_GM_AI_CORE_STATE State(void) const { return m_state.State(); }
   string StateName(void) const { return m_state.StateName(); }
   double Confidence(void) const
     {
      if(m_selflearn.IsReady() && m_selflearn.Last().valid)
         return GmSlClamp(0.4 * m_selflearn.Last().learning_confidence +
                          0.3 * m_selflearn.Last().knowledge_index +
                          0.3 * m_selflearn.Last().knowledge_reliability);
      if(m_execsup.IsReady() && m_execsup.Last().valid)
         return GmEsClamp(0.4 * m_execsup.Last().execution_health_score +
                          0.3 * m_execsup.Last().trade_quality_score +
                          0.3 * m_execsup.Last().decision_stability_score);
      if(m_predintel.IsReady() && m_predintel.Last().valid)
         return GmPredClamp(0.4 * m_predintel.Last().prediction_confidence +
                            0.3 * m_predintel.Last().forecast_reliability +
                            0.3 * m_predintel.Last().overall_probability_score);
      if(m_portintel.IsReady() && m_portintel.Last().valid)
         return GmPiClamp(0.4 * m_portintel.Last().portfolio_intelligence_score +
                          0.3 * m_portintel.Last().capital_efficiency_score +
                          0.3 * m_portintel.Last().portfolio_stability_score);
      if(m_mtfintel.IsReady() && m_mtfintel.Last().valid)
         return GmMtfClamp(0.4 * m_mtfintel.Last().confluence_score +
                           0.3 * m_mtfintel.Last().synchronization_score +
                           0.3 * m_mtfintel.Last().execution_context_score);
      if(m_recintel.IsReady() && m_recintel.Last().valid)
         return GmRiClamp(0.4 * m_recintel.Last().recovery_intelligence_score +
                          0.3 * m_recintel.Last().recovery_confidence +
                          0.3 * m_recintel.Last().loss_control_score);
      if(m_newsintel.IsReady() && m_newsintel.Last().valid)
         return GmNiClamp(0.4 * m_newsintel.Last().forecast_confidence +
                          0.3 * m_newsintel.Last().news_confidence +
                          0.3 * m_newsintel.Last().news_impact_score);
      if(m_orderflow.IsReady() && m_orderflow.Last().valid)
         return GmOfClamp(0.4 * m_orderflow.Last().order_flow_score +
                          0.3 * m_orderflow.Last().energy_score +
                          0.3 * m_orderflow.Last().session_strength);
      if(m_mktintel.IsReady() && m_mktintel.Last().valid)
         return GmMiClamp(0.4 * m_mktintel.Last().momentum_index +
                          0.3 * m_mktintel.Last().liquidity_score +
                          0.3 * m_mktintel.Last().structure_quality);
      if(m_master.IsReady() && m_master.Last().valid)
         return m_master.Last().ai_health_score;
      if(m_orch.IsReady() && m_orch.Last().valid)
         return m_orch.Last().intelligence_score;
      if(m_forecast.IsReady() && m_forecast.Last().valid)
         return m_forecast.Last().forecast_confidence;
      if(m_riskintel.IsReady() && m_riskintel.Last().valid)
         return m_riskintel.Last().confidence;
      if(m_entmon.IsReady() && m_entmon.Last().valid)
         return m_entmon.Last().fleet_health_score;
      if(m_aichat.IsReady() && m_aichat.Last().valid &&
         m_aichat.Last().security_status == GM_CHAT_SEC_ALLOW &&
         m_aireport.IsReady() && m_aireport.Last().valid)
         return m_aireport.Last().exec_confidence;
      if(m_aireport.IsReady() && m_aireport.Last().valid)
         return m_aireport.Last().exec_confidence;
      if(m_memlearn.IsReady() && m_memlearn.Last().valid)
         return m_memlearn.Last().calibrated_confidence;
      if(m_intel.IsReady() && m_intel.Last().valid)
         return m_intel.Last().ai_confidence;
      if(m_assist.IsReady() && m_assist.Last().valid)
         return m_assist.Last().overall_health_score;
      if(m_aival.IsReady() && m_aival.Last().valid)
         return m_aival.Last().certification_score;
      if(m_decision.IsReady() && m_decision.Last().valid)
         return m_decision.Last().overall_confidence;
      if(m_learn.IsReady() && m_learn.Last().valid)
         return m_learn.Last().confidence;
      if(m_conf.IsReady() && m_conf.Last().valid)
         return m_conf.Last().overall_confidence;
      if(m_news.IsReady() && m_news.Last().valid)
         return m_news.Last().confidence;
      if(m_vol.IsReady() && m_vol.Last().valid)
         return m_vol.Last().confidence;
      if(m_trend.IsReady() && m_trend.Last().valid)
         return m_trend.Last().confidence;
      return m_market.IsReady() && m_market.Last().valid
             ? m_market.Last().confidence
             : m_context.Confidence();
     }
   string LastInsight(void) const
     {
      if(m_selflearn.IsReady() && m_selflearn.Last().valid)
         return m_selflearn.Last().insight;
      if(m_execsup.IsReady() && m_execsup.Last().valid)
         return m_execsup.Last().insight;
      if(m_predintel.IsReady() && m_predintel.Last().valid)
         return m_predintel.Last().insight;
      if(m_portintel.IsReady() && m_portintel.Last().valid)
         return m_portintel.Last().insight;
      if(m_mtfintel.IsReady() && m_mtfintel.Last().valid)
         return m_mtfintel.Last().insight;
      if(m_recintel.IsReady() && m_recintel.Last().valid)
         return m_recintel.Last().insight;
      if(m_newsintel.IsReady() && m_newsintel.Last().valid)
         return m_newsintel.Last().insight;
      if(m_orderflow.IsReady() && m_orderflow.Last().valid)
         return m_orderflow.Last().insight;
      if(m_mktintel.IsReady() && m_mktintel.Last().valid)
         return m_mktintel.Last().insight;
      if(m_master.IsReady() && m_master.Last().valid)
         return m_master.Last().insight;
      if(m_orch.IsReady() && m_orch.Last().valid)
         return m_orch.Last().insight;
      if(m_forecast.IsReady() && m_forecast.Last().valid)
         return m_forecast.Last().insight;
      if(m_riskintel.IsReady() && m_riskintel.Last().valid)
         return m_riskintel.Last().insight;
      if(m_entmon.IsReady() && m_entmon.Last().valid)
         return m_entmon.Last().insight;
      if(m_aichat.IsReady() && m_aichat.Last().valid)
         return m_aichat.Last().insight;
      if(m_aireport.IsReady() && m_aireport.Last().valid)
         return m_aireport.Last().insight;
      if(m_memlearn.IsReady() && m_memlearn.Last().valid)
         return m_memlearn.Last().insight;
      if(m_intel.IsReady() && m_intel.Last().valid)
         return m_intel.Last().insight;
      if(m_assist.IsReady() && m_assist.Last().valid)
         return m_assist.Last().insight;
      if(m_aival.IsReady() && m_aival.Last().valid)
         return m_aival.Last().insight;
      if(m_decision.IsReady() && m_decision.Last().valid)
         return m_decision.Last().insight;
      if(m_learn.IsReady() && m_learn.Last().valid)
         return m_learn.Last().insight;
      if(m_conf.IsReady() && m_conf.Last().valid)
         return m_conf.Last().insight;
      if(m_news.IsReady() && m_news.Last().valid)
         return m_news.Last().insight;
      if(m_vol.IsReady() && m_vol.Last().valid)
         return m_vol.Last().insight;
      if(m_trend.IsReady() && m_trend.Last().valid)
         return m_trend.Last().insight;
      return m_market.IsReady() && m_market.Last().valid
             ? m_market.Last().insight
             : m_context.LastInsight();
     }
   SGmAICoreSettings Settings(void) const { return m_ctrl.Settings(); }
   CGmAISecurityGuard *Security(void) { return GetPointer(m_security); }
   CGmAIMarketAnalyzer *MarketAnalyzer(void) { return GetPointer(m_market); }
   CGmAITrendEngine *TrendEngine(void) { return GetPointer(m_trend); }
   CGmAIVolatilityEngine *VolatilityEngine(void) { return GetPointer(m_vol); }
   CGmAINewsEngine *NewsEngine(void) { return GetPointer(m_news); }
   CGmAIConfidenceEngine *ConfidenceEngine(void) { return GetPointer(m_conf); }
   CGmAILearningEngine *LearningEngine(void) { return GetPointer(m_learn); }
   CGmAIDecisionSupportEngine *DecisionSupportEngine(void) { return GetPointer(m_decision); }
   CGmAIValidationEngine *AIValidationEngine(void) { return GetPointer(m_aival); }
   CGmAISupervisorEngine *SupervisorEngine(void) { return GetPointer(m_assist); }
   CGmAIDecisionIntelligenceEngine *DecisionIntelligenceEngine(void) { return GetPointer(m_intel); }
   CGmAILearningMemoryEngine *LearningMemoryEngine(void) { return GetPointer(m_memlearn); }
   CGmAIEnterpriseReportingEngine *EnterpriseReportingEngine(void) { return GetPointer(m_aireport); }
   CGmAIConversationalAssistantEngine *ConversationalAssistantEngine(void) { return GetPointer(m_aichat); }
   CGmAIEnterpriseMonitoringEngine *EnterpriseMonitoringEngine(void) { return GetPointer(m_entmon); }
   CGmAIRiskIntelligenceEngine *RiskIntelligenceEngine(void) { return GetPointer(m_riskintel); }
   CGmAIForecastingEngine *ForecastingEngine(void) { return GetPointer(m_forecast); }
   CGmAIOrchestrationEngine *OrchestrationEngine(void) { return GetPointer(m_orch); }
   CGmAIMasterControlEngine *MasterControlEngine(void) { return GetPointer(m_master); }
   CGmAIMarketIntelligenceEngine *MarketIntelligenceEngine(void) { return GetPointer(m_mktintel); }
   CGmAIOrderFlowIntelligenceEngine *OrderFlowIntelligenceEngine(void) { return GetPointer(m_orderflow); }
   CGmAINewsIntelligenceEngine *NewsIntelligenceEngine(void) { return GetPointer(m_newsintel); }
   CGmAIRecoveryIntelligenceEngine *RecoveryIntelligenceEngine(void) { return GetPointer(m_recintel); }
   CGmAIMultiTimeframeEngine *MultiTimeframeEngine(void) { return GetPointer(m_mtfintel); }
   CGmAIPortfolioIntelligenceEngine *PortfolioIntelligenceEngine(void) { return GetPointer(m_portintel); }
   CGmAIPredictiveIntelligenceEngine *PredictiveIntelligenceEngine(void) { return GetPointer(m_predintel); }
   CGmAIExecutionSupervisorEngine *ExecutionSupervisorEngine(void) { return GetPointer(m_execsup); }
   CGmAISelfLearningPlatformEngine *SelfLearningPlatformEngine(void) { return GetPointer(m_selflearn); }

   void Process(void)
     {
      if(!m_ready || !m_settings.enable_ai)
         return;
      if(!m_ctrl.CanAnalyze())
         return;

      const ulong now = GetTickCount();
      if(m_last_process_ms != 0 &&
         (now - m_last_process_ms) < (ulong)m_settings.process_throttle_ms)
         return;
      m_last_process_ms = now;

      const ulong t0 = GetMicrosecondCount();
      m_manager.RunAnalysisCycle();
      m_market.Analyze();
      m_trend.Analyze();
      m_vol.Analyze();
      m_news.Analyze();
      m_conf.Analyze();
      m_learn.Analyze();
      m_decision.Analyze();
      m_aival.Analyze();
      m_assist.Analyze();
      m_intel.Analyze();
      m_memlearn.Analyze();
      m_aireport.Analyze();
      m_aichat.Analyze();
      m_entmon.Analyze();
      m_riskintel.Analyze();
      m_forecast.Analyze();
      m_orch.Analyze();
      m_master.Analyze();
      m_mktintel.Analyze();
      m_orderflow.Analyze();
      m_newsintel.Analyze();
      m_recintel.Analyze();
      m_mtfintel.Analyze();
      m_portintel.Analyze();
      m_predintel.Analyze();
      m_execsup.Analyze();
      m_selflearn.Analyze();
      m_perf.Record(GetMicrosecondCount() - t0);
     }

   bool PeekLatestDecision(SGmAIDecisionItem &out) const
     {
      return m_queue.PeekLatest(out);
     }
  };

#endif // GM_CAI_CORE_ENGINE_MQH
//+------------------------------------------------------------------+
