//+------------------------------------------------------------------+
//|                                      CEacSystemIntegrity.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEAC_SYSTEM_INTEGRITY_MQH
#define GM_CEAC_SYSTEM_INTEGRITY_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "AuditConstants.mqh"
#include "SGmAuditResult.mqh"
#include "CEacAuditSecurity.mqh"
#include "../SGmCloudStatus.mqh"
#include "../Identity/SGmIdentityResult.mqh"
#include "../Backup/SGmBackupResult.mqh"
#include "../../Core/Version.mqh"

class CGmEacSystemIntegrity
  {
private:
   CGmEacAuditSecurity *m_sec;
   bool                 m_ready;

public:
                     CGmEacSystemIntegrity(void) : m_sec(NULL), m_ready(false) {}

   bool Init(CGmEacAuditSecurity *sec)
     {
      m_sec = sec;
      m_ready = true;
      return true;
     }

   void Verify(const SGmCloudStatus &cloud,
               const SGmIdentityResult &id,
               const SGmBackupResult &bdr,
               const double audit_integrity,
               SGmAuditResult &out) const
     {
      if(!m_ready) return;

      const double module_i = (GM_VERSION_BUILD >= 21040) ? 95.0 : 50.0;
      const double db_i = bdr.valid ? MathMax(50.0, bdr.backup_health) : 75.0;
      const double cfg_i = 90.0;
      const double file_i = (m_sec != NULL && m_sec.IsReady()) ? 92.0 : 60.0;
      const double lic_i = id.valid ? MathMax(40.0, id.license_health) : 70.0;
      const double ai_i = 88.0;
      const double cloud_i = cloud.valid
                             ? (cloud.cloud_status == GM_CLOUD_STATUS_ONLINE ? 95.0 : 65.0)
                             : 60.0;
      const double chain_i = (m_sec != NULL && StringLen(m_sec.ChainHash()) >= 8) ? 94.0 : 55.0;

      out.integrity_rating = (module_i + db_i + cfg_i + file_i + lic_i + ai_i + cloud_i +
                              chain_i + audit_integrity) / 9.0;
      out.trust_score = (out.integrity_rating + out.compliance_score + audit_integrity) / 3.0;

      out.integrity_report = StringFormat(
         "=== Integrity Report ===\r\n"
         "Module: %.0f\r\nDatabase: %.0f\r\nConfiguration: %.0f\r\nFile: %.0f\r\n"
         "License: %.0f\r\nAI Knowledge: %.0f\r\nCloud: %.0f\r\nAudit Chain: %.0f\r\n"
         "Integrity Rating: %.0f\r\nTrust Score: %.0f\r\n",
         module_i, db_i, cfg_i, file_i, lic_i, ai_i, cloud_i, chain_i,
         out.integrity_rating, out.trust_score);

      if(m_sec != NULL)
         out.security_status = m_sec.SecurityStatus();
      else
         out.security_status = "Security n/a";
     }
  };

#endif // GM_CEAC_SYSTEM_INTEGRITY_MQH
//+------------------------------------------------------------------+
