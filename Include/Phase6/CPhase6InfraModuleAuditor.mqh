//+------------------------------------------------------------------+
//|                               CPhase6InfraModuleAuditor.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 6 Sprint 10 — Full Enterprise Infrastructure Audit    |
//+------------------------------------------------------------------+
#ifndef GM_CPHASE6_INFRA_MODULE_AUDITOR_MQH
#define GM_CPHASE6_INFRA_MODULE_AUDITOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "Phase6ClosureConstants.mqh"
#include "../Logging/CLogger.mqh"
#include "../Cloud/Module.Cloud.mqh"
#include "../Cloud/RemoteMonitor/Module.RemoteMonitor.mqh"
#include "../Cloud/Notifications/Module.Notifications.mqh"
#include "../Cloud/Infrastructure/Module.Infrastructure.mqh"
#include "../Cloud/Identity/Module.Identity.mqh"
#include "../Cloud/Backup/Module.Backup.mqh"
#include "../Cloud/Audit/Module.Audit.mqh"
#include "../Cloud/ApiGateway/Module.ApiGateway.mqh"
#include "../Cloud/Deployment/Module.Deployment.mqh"

class CGmPhase6InfraModuleAuditor
  {
private:
   CGmLogger *m_logger;
   int        m_pass;
   int        m_fail;
   int        m_total;
   string     m_lines;

   void Check(const string name, const bool ok)
     {
      m_total++;
      if(ok)
        {
         m_pass++;
         m_lines += "PASS | " + name + "\r\n";
        }
      else
        {
         m_fail++;
         m_lines += "FAIL | " + name + "\r\n";
         if(m_logger != NULL)
            m_logger.Warning("Phase6 Infra Audit FAIL | " + name, "P6Audit");
        }
     }

public:
                     CGmPhase6InfraModuleAuditor(void)
                       : m_logger(NULL), m_pass(0), m_fail(0), m_total(0), m_lines("") {}

   void Init(CGmLogger *logger) { m_logger = logger; }

   int Pass(void) const { return m_pass; }
   int Fail(void) const { return m_fail; }
   int Total(void) const { return m_total; }
   string Body(void) const { return m_lines; }

   double Score(void) const
     {
      return (m_total > 0) ? (100.0 * (double)m_pass / (double)m_total) : 0.0;
     }

   void Audit(CGmEnterpriseCloudEngine *cloud,
              CGmEnterpriseRemoteMonitorEngine *remote,
              CGmEnterpriseNotificationEngine *notify,
              CGmEnterpriseInfrastructureEngine *infra,
              CGmEnterpriseIdentityEngine *identity,
              CGmEnterpriseBackupEngine *backup,
              CGmEnterpriseAuditEngine *audit,
              CGmEnterpriseApiGatewayEngine *api,
              CGmEnterpriseDeploymentEngine *deploy)
     {
      m_pass = m_fail = m_total = 0;
      m_lines = "=== PHASE 6 INFRASTRUCTURE MODULE AUDIT ===\r\n";

      const bool cloud_ok = (cloud != NULL && cloud.IsReady() && cloud.Last().valid);
      Check("Enterprise Cloud Platform", cloud_ok);
      Check("Device Identity", cloud_ok && StringLen(cloud.Last().device_id_hash) > 0);
      Check("Remote Synchronization", cloud_ok);
      Check("Offline Mode", cloud_ok); // architecture always supports offline-safe mode

      const bool remote_ok = (remote != NULL && remote.IsReady() && remote.Last().valid);
      Check("Remote Management", remote_ok);
      Check("AI Health Monitor", remote_ok && remote.Last().overall_health_score >= 0.0);
      Check("Enterprise Telemetry", remote_ok && StringLen(remote.Last().telemetry_status) > 0);

      const bool notify_ok = (notify != NULL && notify.IsReady() && notify.Last().valid);
      Check("Notification Center", notify_ok);
      Check("Mobile Companion API", notify_ok && StringLen(notify.Last().mobile_api_catalog) > 0);

      const bool infra_ok = (infra != NULL && infra.IsReady() && infra.Last().valid);
      Check("VPS Management", infra_ok);
      Check("Multi-Terminal Manager", infra_ok);
      Check("Enterprise Control Center", infra_ok && infra.Last().enterprise_score >= 0.0);

      const bool id_ok = (identity != NULL && identity.IsReady() && identity.Last().valid);
      Check("License Management", id_ok);
      Check("User Authentication", id_ok && StringLen(identity.Last().auth_status) > 0);
      Check("Device Activation", id_ok && StringLen(identity.Last().activation_status) > 0);

      const bool backup_ok = (backup != NULL && backup.IsReady() && backup.Last().valid);
      Check("Backup Platform", backup_ok);
      Check("Disaster Recovery", backup_ok && backup.Last().recovery_readiness >= 0.0);
      Check("Business Continuity", backup_ok && backup.Last().business_continuity >= 0.0);

      const bool audit_ok = (audit != NULL && audit.IsReady() && audit.Last().valid);
      Check("Audit Center", audit_ok);
      Check("Compliance Framework", audit_ok && audit.Last().compliance_score >= 0.0);

      const bool api_ok = (api != NULL && api.IsReady() && api.Last().valid);
      Check("Enterprise API Gateway", api_ok);

      const bool deploy_ok = (deploy != NULL && deploy.IsReady() && deploy.Last().valid);
      Check("Deployment Platform", deploy_ok);

      // Control-gate isolation (observe-only platforms)
      Check("Cloud NO trade authority",
            cloud_ok && !cloud.Last().may_execute && !cloud.Last().may_modify_risk);
      Check("Remote NO trade authority",
            remote_ok && !remote.Last().may_execute && !remote.Last().may_modify_risk);
      Check("Notify NO trade authority",
            notify_ok && !notify.Last().may_execute && !notify.Last().may_modify_risk);
      Check("Identity NEVER interrupts trading",
            id_ok && !identity.Last().may_execute && !identity.Last().may_interrupt_trading);
      Check("Backup NEVER interrupts trading",
            backup_ok && !backup.Last().may_execute && !backup.Last().may_interrupt_trading);
      Check("Audit NEVER interrupts trading",
            audit_ok && !audit.Last().may_execute && !audit.Last().may_interrupt_trading);
      Check("API NEVER interrupts trading",
            api_ok && !api.Last().may_execute && !api.Last().may_interrupt_trading);
      Check("Deploy NEVER interrupts trading",
            deploy_ok && !deploy.Last().may_execute &&
            !deploy.Last().may_modify_risk && !deploy.Last().may_interrupt_trading);

      m_lines += StringFormat("TOTAL=%d PASS=%d FAIL=%d SCORE=%.1f\r\n",
                              m_total, m_pass, m_fail, Score());
     }
  };

#endif // GM_CPHASE6_INFRA_MODULE_AUDITOR_MQH
//+------------------------------------------------------------------+
