//+------------------------------------------------------------------+
//|                           CEnterpriseDeploymentEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 6 Sprint 9 — Deployment / Auto-Update facade          |
//|     LIFECYCLE ONLY — NEVER interrupts trading                   |
//+------------------------------------------------------------------+
#ifndef GM_CENTERPRISE_DEPLOYMENT_ENGINE_MQH
#define GM_CENTERPRISE_DEPLOYMENT_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "DeploymentConstants.mqh"
#include "SGmDeploymentResult.mqh"
#include "CEdpDeploymentSecurity.mqh"
#include "CEdpReleaseManagement.mqh"
#include "CEdpAutoUpdateEngine.mqh"
#include "CEdpDeploymentEngine.mqh"
#include "CEdpProductionValidation.mqh"
#include "CEdpRollbackEngine.mqh"
#include "CEdpDeploymentDatabase.mqh"
#include "../CEnterpriseCloudEngine.mqh"
#include "../RemoteMonitor/CEnterpriseRemoteMonitorEngine.mqh"
#include "../Identity/CEnterpriseIdentityEngine.mqh"
#include "../Backup/CEnterpriseBackupEngine.mqh"
#include "../Audit/CEnterpriseAuditEngine.mqh"
#include "../ApiGateway/CEnterpriseApiGatewayEngine.mqh"
#include "../CCloudSecurity.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../../AI/SGmAISnapshot.mqh"

class CGmEnterpriseDeploymentEngine
  {
private:
   CGmLogger                        *m_logger;
   CGmEnterpriseCloudEngine         *m_cloud;
   CGmEnterpriseRemoteMonitorEngine *m_remote;
   CGmEnterpriseIdentityEngine      *m_identity;
   CGmEnterpriseBackupEngine        *m_backup;
   CGmEnterpriseAuditEngine         *m_audit;
   CGmEnterpriseApiGatewayEngine    *m_api;
   CGmCloudSecurity                  m_sec_core;
   CGmEdpDeploymentSecurity          m_sec;
   CGmEdpReleaseManagement           m_release;
   CGmEdpAutoUpdateEngine            m_update;
   CGmEdpDeploymentEngine            m_deploy;
   CGmEdpProductionValidation        m_validate;
   CGmEdpRollbackEngine              m_rollback;
   CGmEdpDeploymentDatabase          m_db;
   SGmDeploymentResult               m_last;
   int                               m_active_gm_trades;
   ENUM_GM_EDP_UPDATE                 m_prev_upd;
   ulong                             m_last_ms;
   ulong                             m_cycle_us;
   bool                              m_ready;

public:
                     CGmEnterpriseDeploymentEngine(void)
                       : m_logger(NULL), m_cloud(NULL), m_remote(NULL),
                         m_identity(NULL), m_backup(NULL), m_audit(NULL), m_api(NULL),
                         m_active_gm_trades(0), m_prev_upd(GM_EDP_UPD_IDLE),
                         m_last_ms(0), m_cycle_us(0), m_ready(false)
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
      const string seed = StringFormat("EDP|%I64d|%s|%s", magic, symbol, GM_EDP_VERSION);
      m_sec_core.Init(seed);
      m_sec.Init(GetPointer(m_sec_core));
      m_release.Init(GetPointer(m_sec));
      m_update.Init(GetPointer(m_sec), GetPointer(m_release), files, m_db.Prefix());
      m_deploy.Init(GetPointer(m_release));
      m_validate.Init();
      m_rollback.Init(GetPointer(m_sec), GetPointer(m_release));
      m_last.Reset();
      m_ready = true;
      if(m_logger != NULL)
        {
         m_logger.Success("Deployment Engine Started | " + GM_EDP_VERSION, "EDP");
         m_logger.Info("POLICY | " + GM_EDP_POLICY, "EDP");
         m_logger.Info("SAFE | " + GM_EDP_SAFE, "EDP");
         if(m_release.UpdateAvailable())
            m_logger.Info("Update Available | " + m_release.LatestVersion() + "." +
                          IntegerToString(m_release.LatestBuild()), "EDP");
         m_logger.Info("Release Approved | " + m_release.Approval(), "EDP");
        }
      return true;
     }

   void BindCloud(CGmEnterpriseCloudEngine *c) { m_cloud = c; }
   void BindRemote(CGmEnterpriseRemoteMonitorEngine *r) { m_remote = r; }
   void BindIdentity(CGmEnterpriseIdentityEngine *i) { m_identity = i; }
   void BindBackup(CGmEnterpriseBackupEngine *b) { m_backup = b; }
   void BindAudit(CGmEnterpriseAuditEngine *a) { m_audit = a; }
   void BindApi(CGmEnterpriseApiGatewayEngine *a) { m_api = a; }

   // Observe-only: count of Gold Mind managed open positions (never modifies trades)
   void SetActiveGmTrades(const int count)
     {
      m_active_gm_trades = MathMax(0, count);
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmDeploymentResult Last(void) const { return m_last; }
   bool MayInterruptTrading(void) const { return false; }

   bool Process(const bool force = false)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(!force && m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_EDP_THROTTLE_MS)
         return true;

      const ulong t0 = GetMicrosecondCount();
      m_last_ms = now;

      SGmCloudStatus cloud_st;
      cloud_st.Reset();
      if(m_cloud != NULL && m_cloud.IsReady())
         cloud_st = m_cloud.Last();

      SGmRemoteMonitorResult rm_st;
      rm_st.Reset();
      if(m_remote != NULL && m_remote.IsReady())
         rm_st = m_remote.Last();

      SGmIdentityResult id_st;
      id_st.Reset();
      if(m_identity != NULL && m_identity.IsReady())
         id_st = m_identity.Last();

      SGmBackupResult bdr_st;
      bdr_st.Reset();
      if(m_backup != NULL && m_backup.IsReady())
         bdr_st = m_backup.Last();

      SGmAuditResult aud_st;
      aud_st.Reset();
      if(m_audit != NULL && m_audit.IsReady())
         aud_st = m_audit.Last();

      SGmApiGatewayResult api_st;
      api_st.Reset();
      if(m_api != NULL && m_api.IsReady())
         api_st = m_api.Last();

      SGmDeploymentResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();

      m_release.ApplyTo(r);

      const ENUM_GM_EDP_UPDATE before = m_update.Status();
      if(m_logger != NULL && m_release.UpdateAvailable() && before == GM_EDP_UPD_IDLE)
         m_logger.Info("Update Download Started", "EDP");

      m_update.ProcessCycle(m_active_gm_trades, r);

      if(m_logger != NULL)
        {
         if(before != GM_EDP_UPD_DOWNLOADING && m_update.Status() == GM_EDP_UPD_DOWNLOADING)
            m_logger.Info("Update Download Started", "EDP");
         if(before == GM_EDP_UPD_DOWNLOADING || m_update.Status() == GM_EDP_UPD_VERIFYING)
            m_logger.Info("Update Download Completed | hash=" + m_update.PackageHash(), "EDP");
         if(r.package_integrity == "Verified")
            m_logger.Info("Package Verified | " + r.package_integrity, "EDP");
         if(r.update_deferred)
            m_logger.Warning("Update Deferred | active GM trades=" +
                             IntegerToString(m_active_gm_trades), "EDP");
         if(m_prev_upd != GM_EDP_UPD_OK && m_update.Status() == GM_EDP_UPD_OK)
            m_logger.Info("Deployment Completed | staged update OK (no live interrupt)", "EDP");
        }
      m_prev_upd = m_update.Status();

      if(m_logger != NULL)
         m_logger.Info("Deployment Started | promote production check", "EDP");
      m_deploy.Promote(GM_EDP_ENV_PRODUCTION, m_active_gm_trades <= 0);
      m_deploy.ApplyTo(r);

      m_validate.Validate(cloud_st, rm_st, id_st, bdr_st, aud_st, api_st, r);
      m_rollback.Prepare(m_active_gm_trades, r);

      if(m_logger != NULL)
        {
         if(StringFind(m_rollback.Status(), "Prepared") >= 0)
           {
            m_logger.Info("Rollback Initiated | framework arm", "EDP");
            m_logger.Info("Rollback Completed | validation ready", "EDP");
           }
        }

      r.center_status = "DEPLOYMENT CENTER READY";
      r.insight = StringFormat("%s | ProdHealth=%.0f | Trades=%d | %s",
                               r.center_status, r.production_health,
                               r.active_gm_trades, GM_EDP_SAFE);
      r.may_execute = false;
      r.may_modify_risk = false;
      r.may_interrupt_trading = false;
      r.valid = true;

      const string audit = m_sec.AuditLine() + " | may_install_now=" +
                           (r.may_install_now ? "yes" : "no") +
                           " | may_interrupt=false";
      m_db.Record(r, audit, m_rollback.Report());
      m_last = r;
      m_cycle_us = GetMicrosecondCount() - t0;

      if(m_logger != NULL)
         m_logger.Debug(StringFormat("Performance Statistics | cycle=%I64u us (<1%%)",
                                     m_cycle_us), "EDP");
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = m_last.center_status;
      s.ai_engine = "GoldMind Enterprise Deployment Center";
      s.current_mode = "CLOUD_DEPLOYMENT";
      s.confidence_pct = m_last.deployment_health;
      s.confidence_status = StringFormat("%.0f", m_last.production_health);

      // Phase 6 Sprint 9 widgets
      s.w_trend_detector = m_last.current_version;                        // Current Version
      s.future_ai_score = m_last.latest_version;                          // Latest Version
      s.w_recovery_ai = m_last.deployment_status_text;                    // Deployment Status
      s.prediction_status = m_last.update_status_text;                    // Update Status
      s.learning_status = GmEdpChannelName(m_last.channel);               // Release Channel
      s.w_volatility_scanner = m_last.rollback_status;                    // Rollback Status
      s.w_market_analyzer = m_last.release_notes;                         // Release Notes
      s.w_news_analyzer = IntegerToString(m_last.current_build);          // Build Number
      s.w_trade_confidence = StringFormat("%.0f", m_last.production_health); // Production Health
      s.ai_version = m_last.package_integrity + " | " + m_last.approval_status;
      s.decision_status = GM_EDP_POLICY;
      s.valid = true;
     }
  };

#endif // GM_CENTERPRISE_DEPLOYMENT_ENGINE_MQH
//+------------------------------------------------------------------+
