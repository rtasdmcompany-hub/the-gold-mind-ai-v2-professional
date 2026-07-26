//+------------------------------------------------------------------+
//|                                            CEacAuditEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEAC_AUDIT_ENGINE_MQH
#define GM_CEAC_AUDIT_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "AuditConstants.mqh"
#include "SGmAuditResult.mqh"
#include "CEacForensicLogging.mqh"
#include "../SGmCloudStatus.mqh"
#include "../RemoteMonitor/SGmRemoteMonitorResult.mqh"
#include "../Notifications/SGmNotificationCenterResult.mqh"
#include "../Identity/SGmIdentityResult.mqh"
#include "../Backup/SGmBackupResult.mqh"

class CGmEacAuditEngine
  {
private:
   CGmEacForensicLogging *m_forensic;
   ENUM_GM_CLOUD_STATUS   m_prev_cloud;
   bool                   m_prev_cloud_valid;
   string                 m_prev_auth;
   string                 m_prev_backup;
   bool                   m_ready;

public:
                     CGmEacAuditEngine(void)
                       : m_forensic(NULL),
                         m_prev_cloud(GM_CLOUD_STATUS_IDLE),
                         m_prev_cloud_valid(false),
                         m_prev_auth(""), m_prev_backup(""),
                         m_ready(false) {}

   bool Init(CGmEacForensicLogging *forensic)
     {
      m_forensic = forensic;
      m_ready = (m_forensic != NULL);
      return m_ready;
     }

   void Observe(const SGmCloudStatus &cloud,
                const SGmRemoteMonitorResult &rm,
                const SGmNotificationCenterResult &ntf,
                const SGmIdentityResult &id,
                const SGmBackupResult &bdr,
                const bool ai_ready,
                const bool dashboard_ready)
     {
      if(!m_ready || m_forensic == NULL)
         return;

      // Trading engine status (observe only — never control)
      m_forensic.Record(GM_EAC_EVT_TRADE_LIFECYCLE, GM_EAC_SEV_INFO,
                        "TradingEngine=observe-only status snapshot");

      m_forensic.Record(GM_EAC_EVT_AI_ANALYSIS, GM_EAC_SEV_INFO,
                        ai_ready ? "AI Engine Ready" : "AI Engine Offline");

      m_forensic.Record(GM_EAC_EVT_DASHBOARD, GM_EAC_SEV_INFO,
                        dashboard_ready ? "Dashboard Active" : "Dashboard Idle");

      if(id.valid)
        {
         m_forensic.Record(GM_EAC_EVT_LICENSE_CHANGE, GM_EAC_SEV_INFO,
                           "License=" + id.license_status);
         m_forensic.Record(GM_EAC_EVT_SESSION, GM_EAC_SEV_INFO,
                           "Auth=" + id.auth_status);
         if(m_prev_auth != "" && m_prev_auth != id.auth_status)
           {
            if(StringFind(id.auth_status, "Authenticated") >= 0)
               m_forensic.Record(GM_EAC_EVT_USER_LOGIN, GM_EAC_SEV_INFO, id.auth_status);
            if(StringFind(id.auth_status, "Anonymous") >= 0)
               m_forensic.Record(GM_EAC_EVT_USER_LOGOUT, GM_EAC_SEV_INFO, id.auth_status);
           }
         m_prev_auth = id.auth_status;
        }

      if(cloud.valid)
        {
         if(m_prev_cloud_valid)
           {
            if(m_prev_cloud != GM_CLOUD_STATUS_ONLINE && cloud.cloud_status == GM_CLOUD_STATUS_ONLINE)
               m_forensic.Record(GM_EAC_EVT_CLOUD_CONNECT, GM_EAC_SEV_INFO, "Cloud Online");
            if(m_prev_cloud == GM_CLOUD_STATUS_ONLINE && cloud.cloud_status != GM_CLOUD_STATUS_ONLINE)
               m_forensic.Record(GM_EAC_EVT_CLOUD_DISCONNECT, GM_EAC_SEV_WARN, "Cloud Offline");
           }
         m_prev_cloud = cloud.cloud_status;
         m_prev_cloud_valid = true;
         m_forensic.Record(GM_EAC_EVT_SYNC, GM_EAC_SEV_INFO,
                           StringFormat("SyncQueue=%d", cloud.sync_queue_depth));
        }

      if(bdr.valid)
        {
         m_forensic.Record(GM_EAC_EVT_BACKUP, GM_EAC_SEV_INFO,
                           "Backup=" + bdr.backup_status_text);
         if(m_prev_backup != "" && m_prev_backup != bdr.backup_status_text &&
            bdr.backup_status == GM_BDR_STATUS_FAILED)
            m_forensic.Record(GM_EAC_EVT_SYSTEM_ERROR, GM_EAC_SEV_WARN, "Backup Failed");
         m_prev_backup = bdr.backup_status_text;
        }

      if(ntf.valid)
         m_forensic.Record(GM_EAC_EVT_NOTIFICATION, GM_EAC_SEV_INFO,
                           StringFormat("NtfUnread=%d Q=%d", ntf.unread_count, ntf.queue_depth));

      if(rm.valid)
        {
         m_forensic.Record(GM_EAC_EVT_SECURITY, GM_EAC_SEV_INFO,
                           StringFormat("Health=%.0f", rm.overall_health_score));
         if(rm.overall_health_score < 25.0)
            m_forensic.Record(GM_EAC_EVT_CRITICAL, GM_EAC_SEV_CRITICAL,
                              "Remote health critical");
         if(StringFind(rm.recovery_log, "No recovery") < 0 && StringLen(rm.recovery_log) > 0)
            m_forensic.Record(GM_EAC_EVT_RECOVERY, GM_EAC_SEV_WARN, rm.recovery_log);
        }
     }

   void ApplyScores(SGmAuditResult &out) const
     {
      if(!m_ready || m_forensic == NULL) return;
      out.event_count = m_forensic.Count();
      out.critical_count = m_forensic.CriticalCount();
      out.recent_events = m_forensic.RecentSummary(5);
      out.critical_events = m_forensic.CriticalSummary();
      out.audit_timeline = m_forensic.Timeline();
      out.session_id = m_forensic.SessionId();

      out.audit_health = MathMax(40.0, 100.0 - out.critical_count * 8.0);
      out.audit_integrity = (out.event_count > 0) ? 90.0 : 60.0;
      if(out.critical_count > 3)
         out.audit_integrity = 55.0;
      out.audit_status = StringFormat("Events=%d Critical=%d", out.event_count, out.critical_count);
     }
  };

#endif // GM_CEAC_AUDIT_ENGINE_MQH
//+------------------------------------------------------------------+
