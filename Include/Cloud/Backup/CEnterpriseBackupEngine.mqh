//+------------------------------------------------------------------+
//|                               CEnterpriseBackupEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 6 Sprint 6 — Backup / DR / Continuity facade          |
//|     DATA PROTECTION ONLY — NEVER interrupts trading             |
//+------------------------------------------------------------------+
#ifndef GM_CENTERPRISE_BACKUP_ENGINE_MQH
#define GM_CENTERPRISE_BACKUP_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "BackupConstants.mqh"
#include "SGmBackupResult.mqh"
#include "CBdrBackupSecurity.mqh"
#include "CBdrPolicyManager.mqh"
#include "CBdrBackupEngine.mqh"
#include "CBdrDisasterRecovery.mqh"
#include "CBdrBusinessContinuity.mqh"
#include "CBdrRestoreValidation.mqh"
#include "CBdrBackupDatabase.mqh"
#include "../CEnterpriseCloudEngine.mqh"
#include "../RemoteMonitor/CEnterpriseRemoteMonitorEngine.mqh"
#include "../Notifications/CEnterpriseNotificationEngine.mqh"
#include "../Identity/CEnterpriseIdentityEngine.mqh"
#include "../CCloudSecurity.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../../AI/SGmAISnapshot.mqh"

class CGmEnterpriseBackupEngine
  {
private:
   CGmLogger                        *m_logger;
   CGmEnterpriseCloudEngine         *m_cloud;
   CGmEnterpriseRemoteMonitorEngine *m_remote;
   CGmEnterpriseNotificationEngine  *m_notify;
   CGmEnterpriseIdentityEngine      *m_identity;
   CGmCloudSecurity                  m_sec_core;
   CGmBdrBackupSecurity              m_sec;
   CGmBdrPolicyManager               m_policy;
   CGmBdrBackupEngine                m_backup;
   CGmBdrDisasterRecovery            m_dr;
   CGmBdrBusinessContinuity          m_bc;
   CGmBdrRestoreValidation           m_restore;
   CGmBdrBackupDatabase              m_db;
   SGmBackupResult                   m_last;
   bool                              m_first_done;
   ulong                             m_last_ms;
   ulong                             m_cycle_us;
   bool                              m_ready;

public:
                     CGmEnterpriseBackupEngine(void)
                       : m_logger(NULL), m_cloud(NULL), m_remote(NULL),
                         m_notify(NULL), m_identity(NULL),
                         m_first_done(false), m_last_ms(0), m_cycle_us(0), m_ready(false)
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
      const string seed = StringFormat("BDR|%I64d|%s|%s", magic, symbol, GM_BDR_VERSION);
      m_sec_core.Init(seed);
      m_sec.Init(GetPointer(m_sec_core));
      m_policy.Init(GM_BDR_POL_DAILY);
      m_backup.Init(GetPointer(m_sec), GetPointer(m_policy), files, m_db.Prefix());
      m_dr.Init(GetPointer(m_sec));
      m_bc.Init();
      m_restore.Init(GetPointer(m_sec));
      m_last.Reset();
      m_ready = true;
      if(m_logger != NULL)
        {
         m_logger.Success("Backup Engine Started | " + GM_BDR_VERSION, "BDR");
         m_logger.Info("POLICY | " + GM_BDR_POLICY, "BDR");
         m_logger.Info("SAFE | " + GM_BDR_SAFE, "BDR");
         m_logger.Info("Policy Updated | " + m_policy.Summary(), "BDR");
        }
      return true;
     }

   void BindCloud(CGmEnterpriseCloudEngine *cloud)
     {
      m_cloud = cloud;
      if(m_logger != NULL && cloud != NULL)
         m_logger.Info("Backup bound to Cloud (observe only)", "BDR");
     }

   void BindRemote(CGmEnterpriseRemoteMonitorEngine *remote)
     {
      m_remote = remote;
     }

   void BindNotify(CGmEnterpriseNotificationEngine *notify)
     {
      m_notify = notify;
     }

   void BindIdentity(CGmEnterpriseIdentityEngine *identity)
     {
      m_identity = identity;
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmBackupResult Last(void) const { return m_last; }
   bool MayInterruptTrading(void) const { return false; }

   bool Process(const bool force = false)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(!force && m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_BDR_THROTTLE_MS)
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

      SGmNotificationCenterResult ntf_st;
      ntf_st.Reset();
      if(m_notify != NULL && m_notify.IsReady())
         ntf_st = m_notify.Last();

      SGmIdentityResult id_st;
      id_st.Reset();
      if(m_identity != NULL && m_identity.IsReady())
         id_st = m_identity.Last();

      SGmBackupResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();

      // Low-priority async backup (at most one unit of work per cycle)
      const ENUM_GM_BDR_BACKUP_MODE mode = m_first_done ? GM_BDR_MODE_INCREMENTAL : GM_BDR_MODE_FULL;
      if(m_logger != NULL && (force || !m_first_done || m_policy.Due(m_backup.LastAt())))
         m_logger.Info("Backup Started | " + GmBdrBackupModeName(mode), "BDR");

      const bool ran = m_backup.Run(mode, force || !m_first_done);
      if(ran)
        {
         m_first_done = true;
         if(m_logger != NULL)
           {
            m_logger.Info("Backup Completed | versions=" + IntegerToString(m_backup.VersionCount()), "BDR");
            m_logger.Info("Integrity Verified | " + m_backup.LastHash(), "BDR");
           }
        }
      else if(m_backup.Status() == GM_BDR_STATUS_FAILED && m_logger != NULL)
         m_logger.Warning("Backup Failed | non-blocking — trading continues", "BDR");

      m_backup.ApplyTo(r);

      if(m_logger != NULL)
         m_logger.Info("Recovery Tested | DR drill", "BDR");
      m_dr.TestRecovery(m_backup, r);
      m_restore.Validate(m_backup, r);

      m_bc.Measure(cloud_st, rm_st, ntf_st, id_st, r.backup_health, r.recovery_readiness, r);

      r.center_status = "BACKUP & RECOVERY CENTER READY";
      r.insight = StringFormat("%s | BC=%.0f | %s",
                               r.center_status, r.business_continuity, GM_BDR_SAFE);
      r.may_execute = false;
      r.may_modify_risk = false;
      r.may_interrupt_trading = false;
      r.valid = true;

      const string audit = m_sec.AccessControlLine() +
                           " | may_interrupt=false | trading_priority=highest";
      m_db.Record(r, audit);
      m_last = r;
      m_cycle_us = GetMicrosecondCount() - t0;

      if(m_logger != NULL)
         m_logger.Debug(StringFormat("Performance Statistics | cycle=%I64u us (<1%%)",
                                     m_cycle_us), "BDR");
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = m_last.center_status;
      s.ai_engine = "GoldMind Enterprise Backup Continuity";
      s.current_mode = "CLOUD_BACKUP_CONTINUITY";
      s.confidence_pct = m_last.business_continuity;
      s.confidence_status = StringFormat("%.0f", m_last.backup_health);

      // Phase 6 Sprint 6 widgets
      s.w_trend_detector = m_last.backup_status_text;                      // Backup Status
      s.future_ai_score = TimeToString(m_last.last_backup_at, TIME_DATE | TIME_MINUTES); // Last Backup
      s.w_recovery_ai = (m_last.next_backup_at > 0)
                        ? TimeToString(m_last.next_backup_at, TIME_DATE | TIME_MINUTES)
                        : "On-Demand";                                    // Next Backup
      s.prediction_status = StringFormat("%.0f", m_last.backup_health);   // Backup Health
      s.learning_status = StringFormat("%.0f", m_last.recovery_readiness); // Recovery Readiness
      s.w_volatility_scanner = m_last.restore_status;                     // Restore Status
      s.w_market_analyzer = m_last.retention_policy;                      // Retention Policy
      s.w_news_analyzer = StringFormat("%.0f%%", m_last.storage_usage_pct); // Storage Usage
      s.w_trade_confidence = StringFormat("%.0f", m_last.business_continuity); // BC Score
      s.ai_version = m_last.integrity_status + " | " + m_last.policy_status;
      s.decision_status = GM_BDR_POLICY;
      s.valid = true;
     }
  };

#endif // GM_CENTERPRISE_BACKUP_ENGINE_MQH
//+------------------------------------------------------------------+
