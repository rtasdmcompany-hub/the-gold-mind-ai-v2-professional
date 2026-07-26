//+------------------------------------------------------------------+
//|                    CEnterpriseConfigurationCenterEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 7 Sprint 6 — Config / Profiles / Strategy Templates   |
//|     CONFIGURATION ONLY — NEVER interferes with live trading     |
//+------------------------------------------------------------------+
#ifndef GM_CENTERPRISE_CONFIGURATION_CENTER_ENGINE_MQH
#define GM_CENTERPRISE_CONFIGURATION_CENTER_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ConfigurationCenterConstants.mqh"
#include "SGmConfigurationCenterResult.mqh"
#include "CEccConfigurationEngine.mqh"
#include "CEccProfileManager.mqh"
#include "CEccStrategyTemplateManager.mqh"
#include "CEccWorkspaceManager.mqh"
#include "CEccImportExportEngine.mqh"
#include "CEccSecurityLayer.mqh"
#include "CEccTaskQueue.mqh"
#include "CEccConfigurationDatabase.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"
#include "../AI/SGmAISnapshot.mqh"

class CGmEnterpriseConfigurationCenterEngine
  {
private:
   CGmLogger                     *m_logger;
   CGmEccConfigurationEngine      m_config;
   CGmEccProfileManager           m_profiles;
   CGmEccStrategyTemplateManager  m_templates;
   CGmEccWorkspaceManager         m_workspace;
   CGmEccImportExportEngine       m_io;
   CGmEccSecurityLayer            m_security;
   CGmEccTaskQueue                m_queue;
   CGmEccConfigurationDatabase    m_db;
   SGmConfigurationCenterResult   m_last;
   int                            m_active_gm_trades;
   ulong                          m_last_ms;
   bool                           m_ready;
   bool                           m_exported;
   bool                           m_bootstrapped;

public:
                     CGmEnterpriseConfigurationCenterEngine(void)
                       : m_logger(NULL), m_active_gm_trades(0),
                         m_last_ms(0), m_ready(false), m_exported(false), m_bootstrapped(false)
     {
      m_last.Reset();
     }

   bool Init(CGmLogger *logger,
             CGmFileManager *files,
             const long magic,
             const string symbol)
     {
      m_logger = logger;
      m_db.Init(logger, files, magic, symbol);
      m_config.Init(logger);
      m_profiles.Init(logger);
      m_templates.Init(logger);
      m_workspace.Init(logger);
      m_security.Init(logger);
      m_queue.Reset();
      m_io.Init(logger, files, m_db.Prefix());
      m_last.Reset();
      m_ready = true;
      m_exported = false;
      m_bootstrapped = false;
      if(m_logger != NULL)
        {
         m_logger.Success("Configuration Center Started | " + GM_ECC_VERSION, "ECC");
         m_logger.Info("POLICY | " + GM_ECC_POLICY, "ECC");
         m_logger.Info("SAFE | " + GM_ECC_SAFE, "ECC");
        }
      return true;
     }

   void SetActiveGmTrades(const int n)
     {
      m_active_gm_trades = (n < 0 ? 0 : n);
      m_templates.SetActiveGmTrades(m_active_gm_trades);
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmConfigurationCenterResult Last(void) const { return m_last; }
   bool MayInterruptTrading(void) const { return false; }
   bool MayModifyLiveParams(void) const { return false; }

   bool Process(const bool force = false)
     {
      if(!m_ready)
         return false;

      m_templates.SetActiveGmTrades(m_active_gm_trades);

      const ulong now = GetTickCount();
      if(!force && m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_ECC_THROTTLE_MS)
         return true;
      m_last_ms = now;

      if(!force && m_queue.PreferCache((ulong)GM_ECC_THROTTLE_MS) && m_last.valid)
        {
         m_last.queue_status = GM_ECC_Q_CACHED;
         m_last.active_gm_trades = m_active_gm_trades;
         m_last.template_locked = (m_active_gm_trades > 0);
         m_last.may_apply_template = (m_active_gm_trades <= 0);
         return true;
        }

      m_queue.MarkRunning();

      if(!m_bootstrapped)
        {
         m_profiles.BackupProfile();
         m_workspace.BackupWorkspace();
         m_io.MarkImportVerified();
         m_bootstrapped = true;
         if(m_logger != NULL)
            m_logger.Success("Profile Created | Bootstrap Production profile catalog", "ECC");
        }

      SGmConfigurationCenterResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();

      m_profiles.ApplyToResult(r);
      m_templates.ApplyToResult(r);
      m_workspace.ApplyToResult(r);
      m_config.Build(r);
      m_io.ApplyToResult(r);
      m_security.VerifyIntegrity(r);
      m_security.ApplyToResult(r);

      r.may_execute = false;
      r.may_modify_risk = false;
      r.may_interrupt_trading = false;
      r.may_modify_live_params = false;
      r.center_status = "CONFIGURATION CENTER — NO TRADING AUTHORITY";
      r.insight = StringFormat(
         "Health=%.0f | Profile=%s v%d | Template=%s v%d | Locked=%s | GMTrades=%d",
         r.configuration_health, r.profile_name, r.profile_version,
         r.template_name, r.template_version,
         r.template_locked ? "YES" : "NO", r.active_gm_trades);
      r.valid = true;

      if(!m_exported || force)
        {
         m_io.ExportAll(r);
         m_io.ApplyToResult(r);
         m_exported = true;
         m_queue.MarkExported();
        }
      else
         m_queue.MarkCached();

      r.queue_status = m_queue.Status();
      m_last = r;
      m_db.Persist(r);
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = "Configuration Center";
      s.ai_engine = "GoldMind Enterprise Configuration & Profiles";
      s.current_mode = "ECC_CONFIG_ONLY";
      s.confidence_pct = m_last.configuration_health;
      s.confidence_status = m_last.template_locked ? "TEMPLATE LOCKED" : "TEMPLATE READY";

      s.w_trend_detector = m_last.profile_name;                               // Current Profile
      s.future_ai_score = m_last.template_name;                               // Current Template
      s.w_recovery_ai = m_last.workspace_status;                              // Workspace Status
      s.prediction_status = StringFormat("%.0f", m_last.configuration_health); // Config Health
      s.learning_status = (m_last.last_backup == "" ? "None" : m_last.last_backup); // Last Backup
      s.w_volatility_scanner = m_last.import_status;                          // Import Status
      s.w_market_analyzer = m_last.export_status;                             // Export Status
      s.w_news_analyzer = StringFormat("v%d", m_last.profile_version);        // Profile Version
      s.w_trade_confidence = StringFormat("Tmpl v%d | %s",
                                          m_last.template_version,
                                          m_last.template_locked ? "LOCKED" : "OPEN");
      s.ai_version = StringFormat("Health=%.0f | %s",
                                  m_last.configuration_health,
                                  m_last.template_locked ? "LOCKED" : "READY");
      s.decision_status = "CONFIGURATION ONLY — CORE EXECUTION AUTHORITY";
      s.valid = true;
     }
  };

#endif // GM_CENTERPRISE_CONFIGURATION_CENTER_ENGINE_MQH
//+------------------------------------------------------------------+
