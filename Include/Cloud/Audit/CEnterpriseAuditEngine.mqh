//+------------------------------------------------------------------+
//|                                CEnterpriseAuditEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 6 Sprint 7 — Audit / Compliance / Forensic facade     |
//|     MONITOR & REPORT ONLY — NEVER interrupts trading            |
//+------------------------------------------------------------------+
#ifndef GM_CENTERPRISE_AUDIT_ENGINE_MQH
#define GM_CENTERPRISE_AUDIT_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "AuditConstants.mqh"
#include "SGmAuditResult.mqh"
#include "CEacAuditSecurity.mqh"
#include "CEacForensicLogging.mqh"
#include "CEacAuditEngine.mqh"
#include "CEacComplianceFramework.mqh"
#include "CEacSystemIntegrity.mqh"
#include "CEacReportEngine.mqh"
#include "CEacAuditDatabase.mqh"
#include "../CEnterpriseCloudEngine.mqh"
#include "../RemoteMonitor/CEnterpriseRemoteMonitorEngine.mqh"
#include "../Notifications/CEnterpriseNotificationEngine.mqh"
#include "../Identity/CEnterpriseIdentityEngine.mqh"
#include "../Backup/CEnterpriseBackupEngine.mqh"
#include "../CCloudSecurity.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../../AI/SGmAISnapshot.mqh"

class CGmEnterpriseAuditEngine
  {
private:
   CGmLogger                        *m_logger;
   CGmEnterpriseCloudEngine         *m_cloud;
   CGmEnterpriseRemoteMonitorEngine *m_remote;
   CGmEnterpriseNotificationEngine  *m_notify;
   CGmEnterpriseIdentityEngine      *m_identity;
   CGmEnterpriseBackupEngine        *m_backup;
   CGmCloudSecurity                  m_sec_core;
   CGmEacAuditSecurity               m_sec;
   CGmEacForensicLogging             m_forensic;
   CGmEacAuditEngine                 m_audit;
   CGmEacComplianceFramework         m_compliance;
   CGmEacSystemIntegrity             m_integrity;
   CGmEacReportEngine                m_reports;
   CGmEacAuditDatabase               m_db;
   SGmAuditResult                    m_last;
   bool                              m_ai_ready;
   bool                              m_dash_ready;
   ulong                             m_last_ms;
   ulong                             m_cycle_us;
   bool                              m_ready;

public:
                     CGmEnterpriseAuditEngine(void)
                       : m_logger(NULL), m_cloud(NULL), m_remote(NULL),
                         m_notify(NULL), m_identity(NULL), m_backup(NULL),
                         m_ai_ready(false), m_dash_ready(false),
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
      const string seed = StringFormat("EAC|%I64d|%s|%s", magic, symbol, GM_EAC_VERSION);
      m_sec_core.Init(seed);
      m_sec.Init(GetPointer(m_sec_core));
      const string sid = StringFormat("EAC-%I64d-%I64d", magic, (long)TimeCurrent());
      m_forensic.Init(GetPointer(m_sec), sid);
      m_audit.Init(GetPointer(m_forensic));
      m_compliance.Init();
      m_integrity.Init(GetPointer(m_sec));
      m_reports.Init(GetPointer(m_sec), files, m_db.Prefix());
      m_forensic.Record(GM_EAC_EVT_SESSION, GM_EAC_SEV_INFO, "Audit session opened");
      m_last.Reset();
      m_ready = true;
      if(m_logger != NULL)
        {
         m_logger.Success("Audit Engine Started | " + GM_EAC_VERSION, "EAC");
         m_logger.Info("POLICY | " + GM_EAC_POLICY, "EAC");
         m_logger.Info("SAFE | " + GM_EAC_SAFE, "EAC");
         m_logger.Info("Audit Started | session=" + sid, "EAC");
        }
      return true;
     }

   void BindCloud(CGmEnterpriseCloudEngine *cloud) { m_cloud = cloud; }
   void BindRemote(CGmEnterpriseRemoteMonitorEngine *remote) { m_remote = remote; }
   void BindNotify(CGmEnterpriseNotificationEngine *notify) { m_notify = notify; }
   void BindIdentity(CGmEnterpriseIdentityEngine *identity) { m_identity = identity; }
   void BindBackup(CGmEnterpriseBackupEngine *backup) { m_backup = backup; }

   void SetObservedFlags(const bool ai_ready, const bool dashboard_ready)
     {
      m_ai_ready = ai_ready;
      m_dash_ready = dashboard_ready;
     }

   void Shutdown(void)
     {
      if(m_ready)
        {
         m_forensic.Record(GM_EAC_EVT_USER_LOGOUT, GM_EAC_SEV_INFO, "Audit session closed");
         if(m_logger != NULL)
            m_logger.Info("Audit Completed | shutdown", "EAC");
        }
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmAuditResult Last(void) const { return m_last; }
   bool MayInterruptTrading(void) const { return false; }

   bool Process(const bool force = false)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(!force && m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_EAC_THROTTLE_MS)
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

      SGmBackupResult bdr_st;
      bdr_st.Reset();
      if(m_backup != NULL && m_backup.IsReady())
         bdr_st = m_backup.Last();

      if(m_logger != NULL)
         m_logger.Info("Audit Started | cycle observe", "EAC");

      m_audit.Observe(cloud_st, rm_st, ntf_st, id_st, bdr_st, m_ai_ready, m_dash_ready);

      SGmAuditResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      m_audit.ApplyScores(r);
      m_compliance.Evaluate(cloud_st, id_st, bdr_st, r.audit_integrity, r);
      m_integrity.Verify(cloud_st, id_st, bdr_st, r.audit_integrity, r);

      // One export-ready report per cycle (rotate types lightly)
      const ENUM_GM_EAC_REPORT rpt = (ENUM_GM_EAC_REPORT)(m_reports.Generated() % 8);
      m_reports.GenerateAndExport(rpt, r, m_forensic);

      if(m_logger != NULL)
        {
         m_logger.Info("Audit Completed | " + r.audit_status, "EAC");
         m_logger.Info("Compliance Verified | score=" + DoubleToString(r.compliance_score, 0), "EAC");
         m_logger.Info("Integrity Verified | rating=" + DoubleToString(r.integrity_rating, 0), "EAC");
         m_logger.Info("Report Generated | " + r.report_status, "EAC");
         m_logger.Info("Report Exported | " + r.export_status, "EAC");
         m_logger.Info("Security Validation Completed | " + r.security_status, "EAC");
        }

      r.center_status = "AUDIT & COMPLIANCE CENTER READY";
      r.insight = StringFormat("%s | Trust=%.0f | %s",
                               r.center_status, r.trust_score, GM_EAC_SAFE);
      r.may_execute = false;
      r.may_modify_risk = false;
      r.may_interrupt_trading = false;
      r.valid = true;

      const string enc = m_sec.EncryptAudit(r.audit_timeline + "|" + r.critical_events);
      const string trail = m_sec.SecurityStatus() + " | may_interrupt=false";
      m_db.Record(r, enc, trail);
      m_last = r;
      m_cycle_us = GetMicrosecondCount() - t0;

      if(m_logger != NULL)
         m_logger.Debug(StringFormat("Performance Statistics | cycle=%I64u us (<1%%)",
                                     m_cycle_us), "EAC");
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = m_last.center_status;
      s.ai_engine = "GoldMind Enterprise Audit Compliance";
      s.current_mode = "CLOUD_AUDIT_COMPLIANCE";
      s.confidence_pct = m_last.trust_score;
      s.confidence_status = StringFormat("%.0f", m_last.trust_score);

      // Phase 6 Sprint 7 widgets
      s.w_trend_detector = m_last.audit_status;                           // Audit Status
      s.future_ai_score = StringFormat("%.0f", m_last.compliance_score);  // Compliance Score
      s.w_recovery_ai = StringFormat("%.0f", m_last.integrity_rating);    // Integrity Score
      s.prediction_status = m_last.recent_events;                         // Recent Events
      s.learning_status = m_last.security_status;                         // Security Status
      s.w_volatility_scanner = m_last.report_status;                      // Report Status
      s.w_market_analyzer = m_last.critical_events;                       // Critical Events
      s.w_news_analyzer = m_last.audit_timeline;                          // Audit Timeline
      s.w_trade_confidence = StringFormat("%.0f", m_last.trust_score);    // Trust Score
      s.ai_version = m_last.export_status;
      s.decision_status = GM_EAC_POLICY;
      s.valid = true;
     }
  };

#endif // GM_CENTERPRISE_AUDIT_ENGINE_MQH
//+------------------------------------------------------------------+
