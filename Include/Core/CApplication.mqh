//+------------------------------------------------------------------+
//|                                               CApplication.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CAPPLICATION_MQH
#define GM_CAPPLICATION_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "Version.mqh"
#include "Defines.mqh"
#include "EnumsCore.mqh"
#include "TradingRules.mqh"
#include "CErrorManager.mqh"
#include "CTimeManager.mqh"
#include "CSessionManager.mqh"
#include "CFileManager.mqh"
#include "../Logging/CLogger.mqh"
#include "../Configuration/CConfiguration.mqh"
#include "../Trading/CTradeOwnership.mqh"
#include "../Trading/CTradeIdManager.mqh"
#include "../Trading/CTradeRegistry.mqh"
#include "../Trading/CStrategyEngineBase.mqh"
#include "../Trading/CTradeManager.mqh"
#include "../Trading/CPendingOrderEngine.mqh"
#include "../Lifecycle/CLevelManager.mqh"
#include "../Lifecycle/CLevelManagerImpl.mqh"
#include "../Trading/CCycleEngine.mqh"
#include "../Calculation/CLevelEngine.mqh"
#include "../Risk/CRiskEngine.mqh"
#include "../Protection/CCapitalProtectionEngine.mqh"
#include "../Session/CH4SessionEngine.mqh"
#include "../Validation/CValidationEngine.mqh"
#include "../Production/CProductionHardening.mqh"
#include "../Phase2/CPhase2Bridge.mqh"
#include "../Phase2/CPhase1ClosureEngine.mqh"
#include "../Phase2/Module.Phase2Closure.mqh"
#include "../Phase3/Module.Phase3Closure.mqh"
#include "../Phase5/Module.Phase5Closure.mqh"
#include "../Phase6/Module.Phase6Closure.mqh"
#include "../Core/ArchitectureFreeze.mqh"
#include "../Dashboard/CDashboardEngine.mqh"
#include "../Recovery/CRecoveryBase.mqh"
#include "../AI/CAIDashboardEngine.mqh"
#include "../AI/Core/Module.AICore.mqh"
#include "../Analytics/CAnalyticsEngine.mqh"
#include "../Journal/CJournalEngine.mqh"
#include "../Reports/CReportingEngine.mqh"
#include "../MultiInstance/CMultiInstanceEngine.mqh"
#include "../Cloud/Module.Cloud.mqh"
#include "../Cloud/RemoteMonitor/Module.RemoteMonitor.mqh"
#include "../Cloud/Notifications/Module.Notifications.mqh"
#include "../Cloud/Infrastructure/Module.Infrastructure.mqh"
#include "../Cloud/Identity/Module.Identity.mqh"
#include "../Cloud/Backup/Module.Backup.mqh"
#include "../Cloud/Audit/Module.Audit.mqh"
#include "../Cloud/ApiGateway/Module.ApiGateway.mqh"
#include "../Cloud/Deployment/Module.Deployment.mqh"
#include "../TradeJournal/Module.TradeJournal.mqh"
#include "../StrategyLab/Module.StrategyLab.mqh"
#include "../OptimizationLab/Module.OptimizationLab.mqh"
#include "../PortfolioAnalytics/Module.PortfolioAnalytics.mqh"
#include "../ReportingCenter/Module.ReportingCenter.mqh"
#include "../ConfigurationCenter/Module.ConfigurationCenter.mqh"
#include "../AIDecisionCenter/Module.AIDecisionCenter.mqh"
#include "../MultiAccountCenter/Module.MultiAccountCenter.mqh"
#include "../CommandCenter/Module.CommandCenter.mqh"
#include "../Phase7/Module.Phase7Closure.mqh"

/// @file CApplication.mqh
/// @brief Root orchestrator — Phase 7 Sprint 10 Ecosystem Certification & Closure.

class CGmApplication
  {
private:
   ENUM_GM_APP_STATE           m_state;
   CGmConfiguration            m_config;
   CGmLogger                   m_logger;
   CGmErrorManager             m_errors;
   CGmTimeManager              m_time;
   CGmSessionManager           m_session;
   CGmFileManager              m_files;
   CGmTradeOwnership           m_ownership;
   CGmTradeIdManager           m_trade_ids;
   CGmTradeRegistry            m_registry;
   CGmStrategyEngineBase       m_strategy_engine;
   CGmRiskEngine               m_risk_engine;
   CGmCapitalProtectionEngine  m_protection;
   CGmH4SessionEngine          m_h4_session;
   CGmValidationEngine         m_validation;
   CGmProductionHardening      m_production;
   CGmPhase2Bridge             m_phase2;
   CGmPhase1ClosureEngine      m_phase1_closure;
   CGmPhase2ClosureEngine      m_phase2_closure;
   CGmPhase3ClosureEngine      m_phase3_closure;
   CGmPhase5ClosureEngine      m_phase5_closure;
   CGmPhase6ClosureEngine      m_phase6_closure;
   CGmPhase7ClosureEngine      m_phase7_closure;
   CGmDashboardEngine          m_dashboard;
   CGmLevelManager             m_level_manager;
   CGmTradeManager             m_trade_manager;
   CGmLevelEngine              m_level_engine;
   CGmPendingOrderEngine       m_pending_engine;
   CGmCycleEngine              m_cycle_engine;
   CGmRecoveryBase             m_recovery_engine;
   CGmAIDashboardEngine        m_ai_engine;
   CGmAICoreEngine             m_ai_core;
   CGmAnalyticsEngine          m_analytics_engine;
   CGmJournalEngine            m_journal_engine;
   CGmReportingEngine          m_reporting_engine;
   CGmMultiInstanceEngine      m_multi_instance;
   CGmEnterpriseCloudEngine    m_cloud;
   CGmEnterpriseRemoteMonitorEngine m_remote;
   CGmEnterpriseNotificationEngine  m_notify_center;
   CGmEnterpriseInfrastructureEngine m_infra;
   CGmEnterpriseIdentityEngine       m_identity;
   CGmEnterpriseBackupEngine         m_backup;
   CGmEnterpriseAuditEngine          m_audit;
   CGmEnterpriseApiGatewayEngine     m_api;
   CGmEnterpriseDeploymentEngine     m_deploy;
   CGmEnterpriseTradeJournalEngine   m_etj;
   CGmEnterpriseStrategyLabEngine    m_slab;
   CGmEnterpriseOptimizationLabEngine m_optlab;
   CGmEnterprisePortfolioAnalyticsEngine m_epa;
   CGmEnterpriseReportingCenterEngine    m_erc;
   CGmEnterpriseConfigurationCenterEngine m_ecc;
   CGmEnterpriseAIDecisionCenterEngine    m_adc;
   CGmEnterpriseMultiAccountCenterEngine  m_mac;
   CGmEnterpriseCommandCenterEngine       m_eoc;
   bool                        m_timer_active;
   ulong                       m_tick_count;
   ulong                       m_timer_count;

   void PublishCloudDashboard(void)
     {
      if(!m_cloud.IsReady())
         return;
      SGmAISnapshot snap = m_ai_engine.Snapshot();
      m_cloud.ApplyToAISnapshot(snap);
      m_ai_engine.PushSnapshot(snap);
     }

   void PublishRemoteDashboard(void)
     {
      if(!m_remote.IsReady())
         return;
      SGmAISnapshot snap = m_ai_engine.Snapshot();
      m_remote.ApplyToAISnapshot(snap);
      m_ai_engine.PushSnapshot(snap);
     }

   void PublishNotifyDashboard(void)
     {
      if(!m_notify_center.IsReady())
         return;
      SGmAISnapshot snap = m_ai_engine.Snapshot();
      m_notify_center.ApplyToAISnapshot(snap);
      m_ai_engine.PushSnapshot(snap);
     }

   void PublishInfraDashboard(void)
     {
      if(!m_infra.IsReady())
         return;
      SGmAISnapshot snap = m_ai_engine.Snapshot();
      m_infra.ApplyToAISnapshot(snap);
      m_ai_engine.PushSnapshot(snap);
     }

   void PublishIdentityDashboard(void)
     {
      if(!m_identity.IsReady())
         return;
      SGmAISnapshot snap = m_ai_engine.Snapshot();
      m_identity.ApplyToAISnapshot(snap);
      m_ai_engine.PushSnapshot(snap);
     }

   void PublishBackupDashboard(void)
     {
      if(!m_backup.IsReady())
         return;
      SGmAISnapshot snap = m_ai_engine.Snapshot();
      m_backup.ApplyToAISnapshot(snap);
      m_ai_engine.PushSnapshot(snap);
     }

   void PublishAuditDashboard(void)
     {
      if(!m_audit.IsReady())
         return;
      SGmAISnapshot snap = m_ai_engine.Snapshot();
      m_audit.ApplyToAISnapshot(snap);
      m_ai_engine.PushSnapshot(snap);
     }

   void PublishApiDashboard(void)
     {
      if(!m_api.IsReady())
         return;
      SGmAISnapshot snap = m_ai_engine.Snapshot();
      m_api.ApplyToAISnapshot(snap);
      m_ai_engine.PushSnapshot(snap);
     }

   void PublishDeployDashboard(void)
     {
      if(!m_deploy.IsReady())
         return;
      SGmAISnapshot snap = m_ai_engine.Snapshot();
      m_deploy.ApplyToAISnapshot(snap);
      m_ai_engine.PushSnapshot(snap);
     }

   void PublishJournalDashboard(void)
     {
      if(!m_etj.IsReady())
         return;
      SGmAISnapshot snap = m_ai_engine.Snapshot();
      m_etj.ApplyToAISnapshot(snap);
      m_ai_engine.PushSnapshot(snap);
     }

   void PublishStrategyLabDashboard(void)
     {
      if(!m_slab.IsReady())
         return;
      SGmAISnapshot snap = m_ai_engine.Snapshot();
      m_slab.ApplyToAISnapshot(snap);
      m_ai_engine.PushSnapshot(snap);
     }

   void PublishOptimizationLabDashboard(void)
     {
      if(!m_optlab.IsReady())
         return;
      SGmAISnapshot snap = m_ai_engine.Snapshot();
      m_optlab.ApplyToAISnapshot(snap);
      m_ai_engine.PushSnapshot(snap);
     }

   void PublishPortfolioDashboard(void)
     {
      if(!m_epa.IsReady())
         return;
      SGmAISnapshot snap = m_ai_engine.Snapshot();
      m_epa.ApplyToAISnapshot(snap);
      m_ai_engine.PushSnapshot(snap);
     }

   void PublishReportingDashboard(void)
     {
      if(!m_erc.IsReady())
         return;
      SGmAISnapshot snap = m_ai_engine.Snapshot();
      m_erc.ApplyToAISnapshot(snap);
      m_ai_engine.PushSnapshot(snap);
     }

   void PublishConfigurationDashboard(void)
     {
      if(!m_ecc.IsReady())
         return;
      SGmAISnapshot snap = m_ai_engine.Snapshot();
      m_ecc.ApplyToAISnapshot(snap);
      m_ai_engine.PushSnapshot(snap);
     }

   void PublishAIDecisionDashboard(void)
     {
      if(!m_adc.IsReady())
         return;
      SGmAISnapshot snap = m_ai_engine.Snapshot();
      m_adc.ApplyToAISnapshot(snap);
      m_ai_engine.PushSnapshot(snap);
     }

   void PublishMultiAccountDashboard(void)
     {
      if(!m_mac.IsReady())
         return;
      SGmAISnapshot snap = m_ai_engine.Snapshot();
      m_mac.ApplyToAISnapshot(snap);
      m_ai_engine.PushSnapshot(snap);
     }

   void PublishCommandCenterDashboard(void)
     {
      if(!m_eoc.IsReady())
         return;
      SGmAISnapshot snap = m_ai_engine.Snapshot();
      m_eoc.ApplyToAISnapshot(snap);
      m_ai_engine.PushSnapshot(snap);
     }

   // Observe-only count of Gold Mind managed positions (never modifies trades)
   int CountActiveGmPositions(void) const
     {
      return m_ownership.CountOwnPositions();
     }

   void SetState(const ENUM_GM_APP_STATE state, const string reason = "")
     {
      m_state = state;
      if(m_logger.IsInitialized())
        {
         string msg = StringFormat("App state -> %s", EnumToString(state));
         if(StringLen(reason) > 0)
            msg = msg + " | " + reason;
         m_logger.Info(msg, "Application");
        }
     }

   void LogProprietaryRules(void)
     {
      m_logger.Info(GmOwnershipBanner(), "Ownership");
      m_logger.Info(GmArchitectureFreezeBanner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase2FreezeBanner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase3FreezeBanner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase4Sprint10Banner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase4CompleteBanner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase5Sprint1Banner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase5Sprint10Banner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase5CompleteBanner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase6Sprint1Banner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase6Sprint2Banner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase6Sprint3Banner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase6Sprint4Banner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase6Sprint5Banner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase6Sprint6Banner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase6Sprint7Banner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase6Sprint8Banner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase6Sprint9Banner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase6Sprint10Banner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase6CompleteBanner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase7Sprint1Banner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase7Sprint2Banner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase7Sprint3Banner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase7Sprint4Banner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase7Sprint5Banner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase7Sprint6Banner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase7Sprint7Banner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase7Sprint8Banner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase7Sprint9Banner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase7Sprint10Banner(), "ArchitectureFreeze");
      m_logger.Info(GmPhase7CompleteBanner(), "ArchitectureFreeze");
      m_logger.Info("Phase 7 Sprint 10: Trading Ecosystem Certification & Closure",
                    "Phase7Closure");
     }

public:
                     CGmApplication(void)
                       : m_state(GM_APP_STATE_UNINITIALIZED),
                         m_timer_active(false),
                         m_tick_count(0),
                         m_timer_count(0)
     {
     }

                    ~CGmApplication(void)
     {
      if(m_state != GM_APP_STATE_UNINITIALIZED && m_state != GM_APP_STATE_SHUTTING_DOWN)
         Deinit(REASON_CLOSE);
     }

   int Init(const string symbol,
            const ENUM_TIMEFRAMES timeframe,
            const long magic_number,
            const ENUM_GM_LOG_LEVEL log_level,
            const bool log_to_file,
            const bool enable_timer,
            const int timer_interval_ms,
            const SGmProtectionSettings &protection,
            const SGmSessionLogSettings &session_logs,
            const SGmValidationSettings &validation,
            const SGmProductionSettings &production,
            const SGmDashboardSettings &dashboard,
            const SGmAICoreSettings &ai_core)
     {
      const ulong t0 = GetMicrosecondCount();
      SetState(GM_APP_STATE_INITIALIZING, "Phase3 Sprint10 Closure");

      if(!m_config.Init(symbol, timeframe, magic_number, log_level, log_to_file,
                        enable_timer, timer_interval_ms, protection, session_logs,
                        validation, production, dashboard, ai_core))
        {
         SetState(GM_APP_STATE_ERROR, "config");
         return INIT_FAILED;
        }

      if(!m_logger.Init(GM_PRODUCT_SHORT,
                        m_config.LogLevel(),
                        m_config.LogDestination(),
                        m_config.LogToFile()))
        {
         SetState(GM_APP_STATE_ERROR, "logger");
         return INIT_FAILED;
        }

      m_logger.Info("========== EA START (Phase 3 / Sprint 10 Closure & Certification) ==========", "Application");
      LogProprietaryRules();

      if(!m_errors.Init(GetPointer(m_logger)) ||
         !m_time.Init(GetPointer(m_logger), m_config.Symbol(), m_config.StrategyTimeframe()) ||
         !m_session.Init(GetPointer(m_logger), GetPointer(m_time)) ||
         !m_files.Init(GetPointer(m_logger), GetPointer(m_errors), true) ||
         !m_ownership.Init(GetPointer(m_logger), m_config.MagicNumber(), m_config.Symbol()) ||
         !m_trade_ids.Init(GetPointer(m_logger), GetPointer(m_ownership),
                           m_config.MagicNumber(), m_config.Symbol()) ||
         !m_registry.Init(GetPointer(m_logger), GetPointer(m_files),
                          m_config.MagicNumber(), m_config.Symbol()))
        {
         SetState(GM_APP_STATE_ERROR, "core");
         return INIT_FAILED;
        }

      if(!m_risk_engine.InitFull(GetPointer(m_logger), m_config.Symbol(),
                                 m_config.MaxSpreadPoints()))
        {
         SetState(GM_APP_STATE_ERROR, "risk");
         return INIT_FAILED;
        }

      if(!m_protection.Init(GetPointer(m_logger),
                            GetPointer(m_files),
                            GetPointer(m_risk_engine),
                            GetPointer(m_ownership),
                            GetPointer(m_registry),
                            m_config.Symbol(),
                            m_config.MagicNumber(),
                            m_config.ProtectionSettings()))
        {
         SetState(GM_APP_STATE_ERROR, "protection");
         return INIT_FAILED;
        }

      if(!m_level_manager.Init(GetPointer(m_logger), GetPointer(m_files),
                               m_config.Symbol(), m_config.MagicNumber()))
        {
         SetState(GM_APP_STATE_ERROR, "level_manager");
         return INIT_FAILED;
        }

      if(!m_h4_session.Init(GetPointer(m_logger),
                            GetPointer(m_files),
                            GetPointer(m_level_manager),
                            GetPointer(m_ownership),
                            GetPointer(m_registry),
                            m_config.Symbol(),
                            m_config.MagicNumber(),
                            m_config.SessionLogSettings()))
        {
         SetState(GM_APP_STATE_ERROR, "h4_session");
         return INIT_FAILED;
        }

      if(!m_trade_manager.InitFull(GetPointer(m_logger),
                                   GetPointer(m_errors),
                                   GetPointer(m_ownership),
                                   GetPointer(m_trade_ids),
                                   GetPointer(m_registry),
                                   GetPointer(m_risk_engine),
                                   GetPointer(m_level_manager),
                                   m_config.Symbol(),
                                   m_config.MagicNumber()))
        {
         SetState(GM_APP_STATE_ERROR, "trade_manager");
         return INIT_FAILED;
        }
      m_trade_manager.SetH4Session(GetPointer(m_h4_session));

      m_strategy_engine.Init(GetPointer(m_logger));
      m_level_engine.Init(GetPointer(m_logger));
      m_level_engine.SetSymbol(m_config.Symbol());
      m_recovery_engine.Init(GetPointer(m_logger), GetPointer(m_ownership));
      // AI Dashboard InitFull after Phase2 + Analytics (Sprint 6)
      // Analytics full-init after Phase2 bridge (below)

      if(!m_pending_engine.Init(GetPointer(m_logger),
                                GetPointer(m_errors),
                                GetPointer(m_ownership),
                                GetPointer(m_trade_ids),
                                GetPointer(m_risk_engine),
                                GetPointer(m_trade_manager),
                                GetPointer(m_level_manager),
                                m_config.Symbol(),
                                m_config.MagicNumber()))
        {
         SetState(GM_APP_STATE_ERROR, "pending");
         return INIT_FAILED;
        }

      m_pending_engine.SetProtection(GetPointer(m_protection));
      m_pending_engine.SetExecutionControl(m_h4_session.ExecControl());
      m_level_manager.BindPendingEngine(GetPointer(m_pending_engine));

      if(!m_cycle_engine.Init(GetPointer(m_logger),
                              GetPointer(m_level_engine),
                              GetPointer(m_pending_engine),
                              GetPointer(m_ownership),
                              GetPointer(m_level_manager),
                              m_config.Symbol(),
                              m_config.MagicNumber()))
        {
         SetState(GM_APP_STATE_ERROR, "cycle");
         return INIT_FAILED;
        }

      m_cycle_engine.SetSessionEngine(GetPointer(m_h4_session));

      if(!m_production.Init(GetPointer(m_logger),
                            GetPointer(m_files),
                            m_h4_session.ExecControl(),
                            GetPointer(m_registry),
                            GetPointer(m_ownership),
                            GetPointer(m_h4_session),
                            m_config.Symbol(),
                            m_config.MagicNumber(),
                            m_config.ProductionSettings()))
        {
         SetState(GM_APP_STATE_ERROR, "production");
         return INIT_FAILED;
        }
      m_pending_engine.SetProduction(GetPointer(m_production));

      if(!m_validation.Init(GetPointer(m_logger),
                            GetPointer(m_files),
                            GetPointer(m_level_engine),
                            GetPointer(m_ownership),
                            GetPointer(m_trade_ids),
                            GetPointer(m_registry),
                            GetPointer(m_level_manager),
                            GetPointer(m_protection),
                            GetPointer(m_h4_session),
                            m_config.Symbol(),
                            m_config.MagicNumber(),
                            m_config.ValidationSettings()))
        {
         SetState(GM_APP_STATE_ERROR, "validation");
         return INIT_FAILED;
        }

      m_recovery_engine.RecoverState();
      m_trade_manager.ProtectUncoveredPositions();
      m_trade_manager.RecoverTradeManagement();
      m_protection.Recover();
      m_logger.Info(m_config.Summary(), "Configuration");

      if(!m_cycle_engine.RunStartup())
        {
         m_errors.Error("Application", "Startup cycle failed");
         SetState(GM_APP_STATE_ERROR, "startup_cycle");
         return INIT_FAILED;
        }

      m_trade_manager.ProtectUncoveredPositions();
      m_protection.Process(GM_APP_STATE_READY);
      m_h4_session.Process();
      m_production.Process();

      if(m_config.RunValidationOnStartup())
         m_validation.RunFullSuite();

      m_phase2.Init(GetPointer(m_logger),
                    GetPointer(m_ownership),
                    GetPointer(m_registry),
                    GetPointer(m_level_manager),
                    GetPointer(m_h4_session),
                    GetPointer(m_protection),
                    GetPointer(m_level_engine),
                    m_config.Symbol(),
                    m_config.MagicNumber());

      m_analytics_engine.InitFull(GetPointer(m_logger),
                                  GetPointer(m_phase2),
                                  GetPointer(m_recovery_engine));

      m_journal_engine.Init(GetPointer(m_logger),
                            GetPointer(m_files),
                            GetPointer(m_level_manager),
                            GetPointer(m_h4_session),
                            GetPointer(m_analytics_engine),
                            m_config.MagicNumber(),
                            m_config.Symbol());

      m_reporting_engine.Init(GetPointer(m_logger),
                              GetPointer(m_journal_engine),
                              GetPointer(m_analytics_engine));

      m_ai_engine.InitFull(GetPointer(m_logger),
                           GetPointer(m_files),
                           GetPointer(m_phase2),
                           GetPointer(m_analytics_engine),
                           GetPointer(m_recovery_engine),
                           m_config.MagicNumber(),
                           m_config.Symbol());

      m_multi_instance.Init(GetPointer(m_logger),
                            GetPointer(m_files),
                            GetPointer(m_phase2),
                            GetPointer(m_analytics_engine),
                            GetPointer(m_recovery_engine),
                            m_config.Symbol(),
                            m_config.StrategyTimeframe(),
                            m_config.MagicNumber());

      m_phase1_closure.Init(GetPointer(m_logger),
                            GetPointer(m_files),
                            GetPointer(m_validation),
                            GetPointer(m_production),
                            GetPointer(m_phase2),
                            m_config.Symbol(),
                            m_config.MagicNumber());
      m_phase1_closure.RunClosure();

      m_dashboard.Init(GetPointer(m_logger),
                       GetPointer(m_phase2),
                       GetPointer(m_recovery_engine),
                       m_config.DashboardSettings(),
                       GetPointer(m_analytics_engine),
                       GetPointer(m_journal_engine),
                       GetPointer(m_ai_engine),
                       GetPointer(m_multi_instance),
                       GetPointer(m_files),
                       m_config.MagicNumber());
      m_multi_instance.SetDashboardOk(m_config.EnableDashboard());

      m_phase2_closure.Init(GetPointer(m_logger),
                            GetPointer(m_files),
                            GetPointer(m_phase2),
                            GetPointer(m_dashboard),
                            GetPointer(m_analytics_engine),
                            GetPointer(m_journal_engine),
                            GetPointer(m_reporting_engine),
                            GetPointer(m_ai_engine),
                            GetPointer(m_multi_instance),
                            m_config.DashboardSettings(),
                            m_config.Symbol(),
                            m_config.MagicNumber());
      m_phase2_closure.RunClosure();

      m_ai_core.Init(GetPointer(m_logger),
                     GetPointer(m_files),
                     GetPointer(m_phase2),
                     GetPointer(m_analytics_engine),
                     GetPointer(m_recovery_engine),
                     m_config.AICoreSettings(),
                     m_config.MagicNumber(),
                     m_config.Symbol());
      m_ai_engine.BindMarketAnalyzer(m_ai_core.MarketAnalyzer());
      m_ai_engine.BindTrendEngine(m_ai_core.TrendEngine());
      m_ai_engine.BindVolatilityEngine(m_ai_core.VolatilityEngine());
      m_ai_engine.BindNewsEngine(m_ai_core.NewsEngine());
      m_ai_engine.BindConfidenceEngine(m_ai_core.ConfidenceEngine());
      m_ai_engine.BindLearningEngine(m_ai_core.LearningEngine());
      m_ai_engine.BindDecisionSupportEngine(m_ai_core.DecisionSupportEngine());
      m_ai_engine.BindAIValidationEngine(m_ai_core.AIValidationEngine());
      m_ai_engine.BindSupervisorEngine(m_ai_core.SupervisorEngine());
      m_ai_engine.BindDecisionIntelligenceEngine(m_ai_core.DecisionIntelligenceEngine());
      m_ai_engine.BindLearningMemoryEngine(m_ai_core.LearningMemoryEngine());
      m_ai_engine.BindEnterpriseReportingEngine(m_ai_core.EnterpriseReportingEngine());
      m_ai_engine.BindConversationalAssistantEngine(m_ai_core.ConversationalAssistantEngine());
      m_ai_engine.BindEnterpriseMonitoringEngine(m_ai_core.EnterpriseMonitoringEngine());
      m_ai_engine.BindRiskIntelligenceEngine(m_ai_core.RiskIntelligenceEngine());
      m_ai_engine.BindForecastingEngine(m_ai_core.ForecastingEngine());
      m_ai_engine.BindOrchestrationEngine(m_ai_core.OrchestrationEngine());
      m_ai_engine.BindMasterControlEngine(m_ai_core.MasterControlEngine());
      m_ai_engine.BindMarketIntelligenceEngine(m_ai_core.MarketIntelligenceEngine());
      m_ai_engine.BindOrderFlowIntelligenceEngine(m_ai_core.OrderFlowIntelligenceEngine());
      m_ai_engine.BindNewsIntelligenceEngine(m_ai_core.NewsIntelligenceEngine());
      m_ai_engine.BindRecoveryIntelligenceEngine(m_ai_core.RecoveryIntelligenceEngine());
      m_ai_engine.BindMultiTimeframeEngine(m_ai_core.MultiTimeframeEngine());
      m_ai_engine.BindPortfolioIntelligenceEngine(m_ai_core.PortfolioIntelligenceEngine());
      m_ai_engine.BindPredictiveIntelligenceEngine(m_ai_core.PredictiveIntelligenceEngine());
      m_ai_engine.BindExecutionSupervisorEngine(m_ai_core.ExecutionSupervisorEngine());
      m_ai_engine.BindSelfLearningPlatformEngine(m_ai_core.SelfLearningPlatformEngine());
      if(m_ai_core.EnterpriseMonitoringEngine() != NULL)
         m_ai_core.EnterpriseMonitoringEngine().BindMultiInstance(GetPointer(m_multi_instance));

      m_phase3_closure.Init(GetPointer(m_logger),
                            GetPointer(m_files),
                            GetPointer(m_ai_core),
                            GetPointer(m_ai_engine),
                            m_config.Symbol(),
                            m_config.MagicNumber());
      m_phase3_closure.RunClosure();

      m_phase5_closure.Init(GetPointer(m_logger),
                            GetPointer(m_files),
                            GetPointer(m_ai_core),
                            GetPointer(m_ai_engine),
                            m_config.Symbol(),
                            m_config.MagicNumber());
      m_phase5_closure.RunClosure();
      {
         SGmAISnapshot cert = m_ai_engine.Snapshot();
         m_phase5_closure.ApplyToAISnapshot(cert);
         m_ai_engine.PushSnapshot(cert);
      }

      // Phase 6 — Cloud layer (independent; never gates trading)
      m_cloud.Init(GetPointer(m_logger),
                   GetPointer(m_files),
                   m_config.MagicNumber(),
                   m_config.Symbol());
      PublishCloudDashboard();

      m_remote.Init(GetPointer(m_logger),
                    GetPointer(m_files),
                    m_config.MagicNumber(),
                    m_config.Symbol());
      m_remote.BindCloud(GetPointer(m_cloud));
      m_remote.SetObservedFlags(true,
                                true,
                                m_ai_core.IsReady(),
                                m_ai_engine.IsReady());
      m_remote.Process(true);
      PublishRemoteDashboard();

      m_notify_center.Init(GetPointer(m_logger),
                           GetPointer(m_files),
                           m_config.MagicNumber(),
                           m_config.Symbol());
      m_notify_center.BindCloud(GetPointer(m_cloud));
      m_notify_center.BindRemote(GetPointer(m_remote));
      m_notify_center.Process(true);
      PublishNotifyDashboard();

      m_infra.Init(GetPointer(m_logger),
                   GetPointer(m_files),
                   m_config.MagicNumber(),
                   m_config.Symbol());
      m_infra.BindCloud(GetPointer(m_cloud));
      m_infra.BindRemote(GetPointer(m_remote));
      m_infra.BindNotify(GetPointer(m_notify_center));
      m_infra.Process(true);
      PublishInfraDashboard();

      m_identity.Init(GetPointer(m_logger),
                      GetPointer(m_files),
                      m_config.MagicNumber(),
                      m_config.Symbol());
      m_identity.BindCloud(GetPointer(m_cloud));
      m_identity.Process(true);
      PublishIdentityDashboard();

      m_backup.Init(GetPointer(m_logger),
                    GetPointer(m_files),
                    m_config.MagicNumber(),
                    m_config.Symbol());
      m_backup.BindCloud(GetPointer(m_cloud));
      m_backup.BindRemote(GetPointer(m_remote));
      m_backup.BindNotify(GetPointer(m_notify_center));
      m_backup.BindIdentity(GetPointer(m_identity));
      m_backup.Process(true);
      PublishBackupDashboard();

      m_audit.Init(GetPointer(m_logger),
                   GetPointer(m_files),
                   m_config.MagicNumber(),
                   m_config.Symbol());
      m_audit.BindCloud(GetPointer(m_cloud));
      m_audit.BindRemote(GetPointer(m_remote));
      m_audit.BindNotify(GetPointer(m_notify_center));
      m_audit.BindIdentity(GetPointer(m_identity));
      m_audit.BindBackup(GetPointer(m_backup));
      m_audit.SetObservedFlags(m_ai_core.IsReady(), m_ai_engine.IsReady());
      m_audit.Process(true);
      PublishAuditDashboard();

      m_api.Init(GetPointer(m_logger),
                 GetPointer(m_files),
                 m_config.MagicNumber(),
                 m_config.Symbol());
      m_api.BindCloud(GetPointer(m_cloud));
      m_api.BindRemote(GetPointer(m_remote));
      m_api.BindNotify(GetPointer(m_notify_center));
      m_api.BindIdentity(GetPointer(m_identity));
      m_api.BindBackup(GetPointer(m_backup));
      m_api.BindAudit(GetPointer(m_audit));
      m_api.Process(true);
      PublishApiDashboard();

      m_deploy.Init(GetPointer(m_logger),
                    GetPointer(m_files),
                    m_config.MagicNumber(),
                    m_config.Symbol());
      m_deploy.BindCloud(GetPointer(m_cloud));
      m_deploy.BindRemote(GetPointer(m_remote));
      m_deploy.BindIdentity(GetPointer(m_identity));
      m_deploy.BindBackup(GetPointer(m_backup));
      m_deploy.BindAudit(GetPointer(m_audit));
      m_deploy.BindApi(GetPointer(m_api));
      m_deploy.SetActiveGmTrades(CountActiveGmPositions());
      m_deploy.Process(true);
      PublishDeployDashboard();

      m_phase6_closure.Init(GetPointer(m_logger),
                            GetPointer(m_files),
                            GetPointer(m_cloud),
                            GetPointer(m_remote),
                            GetPointer(m_notify_center),
                            GetPointer(m_infra),
                            GetPointer(m_identity),
                            GetPointer(m_backup),
                            GetPointer(m_audit),
                            GetPointer(m_api),
                            GetPointer(m_deploy),
                            m_config.Symbol(),
                            m_config.MagicNumber());
      m_phase6_closure.RunClosure();
      {
         SGmAISnapshot cert6 = m_ai_engine.Snapshot();
         m_phase6_closure.ApplyToAISnapshot(cert6);
         m_ai_engine.PushSnapshot(cert6);
      }

      m_etj.Init(GetPointer(m_logger),
                 GetPointer(m_files),
                 m_config.MagicNumber(),
                 m_config.Symbol());
      m_etj.Process(true);
      PublishJournalDashboard();

      m_slab.Init(GetPointer(m_logger),
                  GetPointer(m_files),
                  m_config.MagicNumber(),
                  m_config.Symbol());
      m_slab.SetActiveGmTrades(CountActiveGmPositions());
      m_slab.Process(true);
      PublishStrategyLabDashboard();

      m_optlab.Init(GetPointer(m_logger),
                    GetPointer(m_files),
                    m_config.MagicNumber(),
                    m_config.Symbol());
      m_optlab.BindStrategyLab(GetPointer(m_slab));
      m_optlab.SetActiveGmTrades(CountActiveGmPositions());
      m_optlab.Process(true);
      PublishOptimizationLabDashboard();

      m_epa.Init(GetPointer(m_logger),
                 GetPointer(m_files),
                 m_config.MagicNumber(),
                 m_config.Symbol());
      m_epa.Process(true);
      PublishPortfolioDashboard();

      m_erc.Init(GetPointer(m_logger),
                 GetPointer(m_files),
                 m_config.MagicNumber(),
                 m_config.Symbol());
      m_erc.BindPortfolio(GetPointer(m_epa));
      m_erc.BindTradeJournal(GetPointer(m_etj));
      m_erc.Process(true);
      PublishReportingDashboard();

      m_ecc.Init(GetPointer(m_logger),
                 GetPointer(m_files),
                 m_config.MagicNumber(),
                 m_config.Symbol());
      m_ecc.SetActiveGmTrades(CountActiveGmPositions());
      m_ecc.Process(true);
      PublishConfigurationDashboard();

      m_adc.Init(GetPointer(m_logger),
                 GetPointer(m_files),
                 m_config.MagicNumber(),
                 m_config.Symbol());
      m_adc.BindPortfolio(GetPointer(m_epa));
      m_adc.BindTradeJournal(GetPointer(m_etj));
      m_adc.Process(true);
      PublishAIDecisionDashboard();

      m_mac.Init(GetPointer(m_logger),
                 GetPointer(m_files),
                 m_config.MagicNumber(),
                 m_config.Symbol());
      m_mac.BindPortfolio(GetPointer(m_epa));
      m_mac.BindTradeJournal(GetPointer(m_etj));
      m_mac.BindIdentity(GetPointer(m_identity));
      m_mac.Process(true);
      PublishMultiAccountDashboard();

      m_eoc.Init(GetPointer(m_logger),
                 GetPointer(m_files),
                 m_config.MagicNumber(),
                 m_config.Symbol());
      m_eoc.BindPortfolio(GetPointer(m_epa));
      m_eoc.BindMultiAccount(GetPointer(m_mac));
      m_eoc.BindAIDecision(GetPointer(m_adc));
      m_eoc.BindIdentity(GetPointer(m_identity));
      m_eoc.BindInfrastructure(GetPointer(m_infra));
      m_eoc.BindApi(GetPointer(m_api));
      m_eoc.BindBackup(GetPointer(m_backup));
      m_eoc.BindNotify(GetPointer(m_notify_center));
      m_eoc.BindCloud(GetPointer(m_cloud));
      m_eoc.SetLiveOps(CountActiveGmPositions(),
                      m_ownership.CountOwnPendingOrders(),
                      true,
                      m_ai_core.IsEnabled());
      m_eoc.Process(true);
      PublishCommandCenterDashboard();

      m_phase7_closure.Init(GetPointer(m_logger),
                            GetPointer(m_files),
                            GetPointer(m_etj),
                            GetPointer(m_slab),
                            GetPointer(m_optlab),
                            GetPointer(m_epa),
                            GetPointer(m_erc),
                            GetPointer(m_ecc),
                            GetPointer(m_adc),
                            GetPointer(m_mac),
                            GetPointer(m_eoc),
                            m_config.Symbol(),
                            m_config.MagicNumber());
      m_phase7_closure.RunClosure();
      {
         SGmAISnapshot cert7 = m_ai_engine.Snapshot();
         m_phase7_closure.ApplyToAISnapshot(cert7);
         m_ai_engine.PushSnapshot(cert7);
      }

      m_production.WriteRcReport(m_validation.HasRun()
                                 ? StringFormat("ValidationDecision=%s Score=%.1f | Phase1=%s | Phase2=%s | Phase3=%s | Phase5=%s | Phase6=%s | Phase7=%s | Cloud=%s | RM=%.0f | ENC=%d | EIF=%.0f | ELM=%.0f | BDR=%.0f | EAC=%.0f | EAP=%.0f | EDP=%.0f | ETJ=%d | ESL=%.0f | EOL=%.0f | EPA=%.0f | ERC=%.0f | ECC=%.0f | ADC=%.0f | MAC=%.0f | EOC=%.0f | AI=%s | P5=%.1f | P6=%.1f | P7=%.1f",
                                                m_validation.Final().decision,
                                                m_validation.Final().overall_score,
                                                m_phase1_closure.Passed() ? "PASS" : "FAIL",
                                                m_phase2_closure.Passed() ? "PASS" : "FAIL",
                                                m_phase3_closure.Passed() ? "PASS" : "FAIL",
                                                m_phase5_closure.Passed() ? "PASS" : "FAIL",
                                                m_phase6_closure.Passed() ? "PASS" : "FAIL",
                                                m_phase7_closure.Passed() ? "PASS" : "FAIL",
                                                m_cloud.IsReady() ? GmCloudStatusName(m_cloud.Last().cloud_status) : "OFF",
                                                m_remote.IsReady() ? m_remote.Last().overall_health_score : 0.0,
                                                m_notify_center.IsReady() ? m_notify_center.Last().unread_count : 0,
                                                m_infra.IsReady() ? m_infra.Last().enterprise_score : 0.0,
                                                m_identity.IsReady() ? m_identity.Last().license_health : 0.0,
                                                m_backup.IsReady() ? m_backup.Last().business_continuity : 0.0,
                                                m_audit.IsReady() ? m_audit.Last().trust_score : 0.0,
                                                m_api.IsReady() ? m_api.Last().api_health : 0.0,
                                                m_deploy.IsReady() ? m_deploy.Last().production_health : 0.0,
                                                m_etj.IsReady() ? m_etj.Last().trades_total : 0,
                                                m_slab.IsReady() ? m_slab.Last().institutional_score : 0.0,
                                                m_optlab.IsReady() ? m_optlab.Last().institutional_score : 0.0,
                                                m_epa.IsReady() ? m_epa.Last().portfolio_health : 0.0,
                                                m_erc.IsReady() ? m_erc.Last().report_quality : 0.0,
                                                m_ecc.IsReady() ? m_ecc.Last().configuration_health : 0.0,
                                                m_adc.IsReady() ? m_adc.Last().decision_confidence : 0.0,
                                                m_mac.IsReady() ? m_mac.Last().enterprise_health : 0.0,
                                                m_eoc.IsReady() ? m_eoc.Last().enterprise_health : 0.0,
                                                m_ai_core.IsEnabled() ? m_ai_core.StateName() : "OFF",
                                                m_phase5_closure.Report().overall_score,
                                                m_phase6_closure.Report().overall_score,
                                                m_phase7_closure.Report().overall_score)
                                 : StringFormat("Validation=skipped | Phase1=%s | Phase2=%s | Phase3=%s | Phase5=%s | Phase6=%s | Phase7=%s | Cloud=%s | RM=%.0f | ENC=%d | EIF=%.0f | ELM=%.0f | BDR=%.0f | EAC=%.0f | EAP=%.0f | EDP=%.0f | ETJ=%d | ESL=%.0f | EOL=%.0f | EPA=%.0f | ERC=%.0f | ECC=%.0f | ADC=%.0f | MAC=%.0f | EOC=%.0f | P5=%.1f | P6=%.1f | P7=%.1f",
                                                m_phase1_closure.Passed() ? "PASS" : "FAIL",
                                                m_phase2_closure.Passed() ? "PASS" : "FAIL",
                                                m_phase3_closure.Passed() ? "PASS" : "FAIL",
                                                m_phase5_closure.Passed() ? "PASS" : "FAIL",
                                                m_phase6_closure.Passed() ? "PASS" : "FAIL",
                                                m_phase7_closure.Passed() ? "PASS" : "FAIL",
                                                m_cloud.IsReady() ? GmCloudStatusName(m_cloud.Last().cloud_status) : "OFF",
                                                m_remote.IsReady() ? m_remote.Last().overall_health_score : 0.0,
                                                m_notify_center.IsReady() ? m_notify_center.Last().unread_count : 0,
                                                m_infra.IsReady() ? m_infra.Last().enterprise_score : 0.0,
                                                m_identity.IsReady() ? m_identity.Last().license_health : 0.0,
                                                m_backup.IsReady() ? m_backup.Last().business_continuity : 0.0,
                                                m_audit.IsReady() ? m_audit.Last().trust_score : 0.0,
                                                m_api.IsReady() ? m_api.Last().api_health : 0.0,
                                                m_deploy.IsReady() ? m_deploy.Last().production_health : 0.0,
                                                m_etj.IsReady() ? m_etj.Last().trades_total : 0,
                                                m_slab.IsReady() ? m_slab.Last().institutional_score : 0.0,
                                                m_optlab.IsReady() ? m_optlab.Last().institutional_score : 0.0,
                                                m_epa.IsReady() ? m_epa.Last().portfolio_health : 0.0,
                                                m_erc.IsReady() ? m_erc.Last().report_quality : 0.0,
                                                m_ecc.IsReady() ? m_ecc.Last().configuration_health : 0.0,
                                                m_adc.IsReady() ? m_adc.Last().decision_confidence : 0.0,
                                                m_mac.IsReady() ? m_mac.Last().enterprise_health : 0.0,
                                                m_eoc.IsReady() ? m_eoc.Last().enterprise_health : 0.0,
                                                m_phase5_closure.Report().overall_score,
                                                m_phase6_closure.Report().overall_score,
                                                m_phase7_closure.Report().overall_score));

      if(m_config.EnableTimer() && EventSetMillisecondTimer(m_config.TimerIntervalMs()))
        {
         m_timer_active = true;
         m_logger.Info(StringFormat("Timer started (%d ms)", m_config.TimerIntervalMs()),
                       "Application");
        }

      m_logger.Success(StringFormat("Application initialized | Phase7 Sprint10 Ecosystem Certification | %I64u us",
                                    GetMicrosecondCount() - t0),
                       "Application");
      SetState(GM_APP_STATE_READY, "init complete");
      SetState(GM_APP_STATE_RUNNING, "enter run loop");
      return INIT_SUCCEEDED;
     }

   void Deinit(const int reason)
     {
      SetState(GM_APP_STATE_SHUTTING_DOWN, StringFormat("reason=%d", reason));
      if(m_timer_active)
        {
         EventKillTimer();
         m_timer_active = false;
        }

      m_production.Shutdown();
      m_eoc.Shutdown();
      m_mac.Shutdown();
      m_adc.Shutdown();
      m_ecc.Shutdown();
      m_erc.Shutdown();
      m_epa.Shutdown();
      m_optlab.Shutdown();
      m_slab.Shutdown();
      m_etj.Shutdown();
      m_deploy.Shutdown();
      m_api.Shutdown();
      m_audit.Shutdown();
      m_backup.Shutdown();
      m_identity.Shutdown();
      m_infra.Shutdown();
      m_notify_center.Shutdown();
      m_cloud.Shutdown();
      m_remote.Shutdown();
      m_dashboard.Shutdown();
      m_ai_core.Shutdown();
      m_multi_instance.Shutdown();
      m_reporting_engine.Shutdown();
      m_journal_engine.Shutdown();
      m_h4_session.Shutdown();
      m_protection.Shutdown();
      m_level_manager.Shutdown();
      m_registry.Shutdown();
      m_trade_ids.Shutdown();
      m_risk_engine.Shutdown();
      m_analytics_engine.Shutdown();
      m_ai_engine.Shutdown();
      m_recovery_engine.Shutdown();
      m_level_engine.Shutdown();
      m_trade_manager.Shutdown();
      m_strategy_engine.Shutdown();

      if(m_logger.IsInitialized())
        {
         m_logger.Success("Application shutdown complete", "Application");
         m_logger.Shutdown();
        }
      m_state = GM_APP_STATE_UNINITIALIZED;
     }

   void OnTick(void)
     {
      if(m_state != GM_APP_STATE_RUNNING)
         return;
      m_tick_count++;
      m_session.Refresh();
      m_production.Process();
      m_protection.Process(m_state);
      m_h4_session.Process();
      m_trade_manager.Process();
      m_journal_engine.Process();
      m_reporting_engine.Process();
      m_ai_engine.Process();
      m_ai_core.Process();
      m_multi_instance.Process();

      if(m_time.IsNewBar())
        {
         m_logger.Info("New H4 bar — cycle rollover + level reset", "Application");
         if(!m_cycle_engine.OnNewH4Closed())
            m_errors.Error("Application", "H4 rollover failed");
         m_trade_manager.SetH4CycleId(m_cycle_engine.ActiveH4Bar());
         m_dashboard.OnNewH4();
        }
      m_dashboard.Process();
     }

   void OnTimer(void)
     {
      if(m_state != GM_APP_STATE_RUNNING)
         return;
      m_timer_count++;
      m_session.Refresh();
      m_production.Process();
      m_protection.Process(m_state);
      m_h4_session.Process();
      m_registry.Flush();
      m_trade_manager.ProtectUncoveredPositions();
      m_journal_engine.Process();
      m_reporting_engine.Process();
      m_ai_engine.Process();
      m_ai_core.Process();
      m_multi_instance.Process();
      m_dashboard.Process();
      // Cloud = background only (never on critical tick path)
      if(m_cloud.IsReady())
        {
         m_cloud.Process(false);
        }
      if(m_remote.IsReady())
        {
         m_remote.SetObservedFlags(true,
                                   true,
                                   m_ai_core.IsReady(),
                                   m_ai_engine.IsReady());
         m_remote.Process(false);
        }
      if(m_notify_center.IsReady())
        {
         m_notify_center.Process(false);
        }
      if(m_infra.IsReady())
        {
         m_infra.Process(false);
        }
      if(m_identity.IsReady())
        {
         m_identity.Process(false);
        }
      if(m_backup.IsReady())
        {
         m_backup.Process(false);
        }
      if(m_audit.IsReady())
        {
         m_audit.SetObservedFlags(m_ai_core.IsReady(), m_ai_engine.IsReady());
         m_audit.Process(false);
        }
      if(m_api.IsReady())
        {
         m_api.Process(false);
        }
      if(m_deploy.IsReady())
        {
         m_deploy.SetActiveGmTrades(CountActiveGmPositions());
         m_deploy.Process(false);
        }
      if(m_etj.IsReady())
        {
         m_etj.Process(false);
        }
      if(m_slab.IsReady())
        {
         m_slab.SetActiveGmTrades(CountActiveGmPositions());
         m_slab.Process(false);
        }
      if(m_optlab.IsReady())
        {
         m_optlab.SetActiveGmTrades(CountActiveGmPositions());
         m_optlab.Process(false);
        }
      if(m_epa.IsReady())
        {
         m_epa.Process(false);
        }
      if(m_erc.IsReady())
        {
         m_erc.Process(false);
        }
      if(m_ecc.IsReady())
        {
         m_ecc.SetActiveGmTrades(CountActiveGmPositions());
         m_ecc.Process(false);
        }
      if(m_adc.IsReady())
        {
         m_adc.Process(false);
        }
      if(m_mac.IsReady())
        {
         m_mac.Process(false);
        }
      if(m_eoc.IsReady())
        {
         m_eoc.SetLiveOps(CountActiveGmPositions(),
                          m_ownership.CountOwnPendingOrders(),
                          true,
                          m_ai_core.IsEnabled());
         m_eoc.Process(false);
         PublishCommandCenterDashboard();
        }
      else if(m_mac.IsReady())
         PublishMultiAccountDashboard();
      else if(m_adc.IsReady())
         PublishAIDecisionDashboard();
      else if(m_ecc.IsReady())
         PublishConfigurationDashboard();
      else if(m_erc.IsReady())
         PublishReportingDashboard();
      else if(m_epa.IsReady())
         PublishPortfolioDashboard();
      else if(m_optlab.IsReady())
         PublishOptimizationLabDashboard();
      else if(m_slab.IsReady())
         PublishStrategyLabDashboard();
      else if(m_etj.IsReady())
         PublishJournalDashboard();
      else if(m_deploy.IsReady())
         PublishDeployDashboard();
      else if(m_api.IsReady())
         PublishApiDashboard();
      else if(m_audit.IsReady())
         PublishAuditDashboard();
      else if(m_backup.IsReady())
         PublishBackupDashboard();
      else if(m_identity.IsReady())
         PublishIdentityDashboard();
      else if(m_infra.IsReady())
         PublishInfraDashboard();
      else if(m_notify_center.IsReady())
         PublishNotifyDashboard();
      else if(m_remote.IsReady())
         PublishRemoteDashboard();
      else if(m_cloud.IsReady())
         PublishCloudDashboard();
     }

   void OnTrade(void) {}

   void OnTradeTransaction(const MqlTradeTransaction &trans,
                           const MqlTradeRequest &request,
                           const MqlTradeResult &result)
     {
      if(m_state != GM_APP_STATE_RUNNING)
         return;
      m_trade_manager.OnTradeTransaction(trans, request, result);
      m_dashboard.OnTradeTransaction(trans);
     }

   void OnChartEvent(const int id,
                     const long &lparam,
                     const double &dparam,
                     const string &sparam)
     {
      if(m_state != GM_APP_STATE_RUNNING)
         return;
      m_dashboard.OnChartEvent(id, lparam, dparam, sparam);
     }

   ENUM_GM_APP_STATE State(void) const { return m_state; }
  };

#endif // GM_CAPPLICATION_MQH
//+------------------------------------------------------------------+
