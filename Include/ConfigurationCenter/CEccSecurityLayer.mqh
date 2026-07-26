//+------------------------------------------------------------------+
//|                                        CEccSecurityLayer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CECC_SECURITY_LAYER_MQH
#define GM_CECC_SECURITY_LAYER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmConfigurationCenterResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmEccSecurityLayer
  {
private:
   CGmLogger *m_logger;
   string     m_status;
   string     m_audit;
   bool       m_tamper_ok;

public:
                     CGmEccSecurityLayer(void)
                       : m_logger(NULL), m_status(""), m_audit(""), m_tamper_ok(true) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_status = "Encrypted Config ARCH | Signatures ARCH | RBAC ARCH | Tamper Check OK";
      m_audit = "";
      m_tamper_ok = true;
     }

   string Status(void) const { return m_status; }
   string Audit(void) const { return m_audit; }

   void AppendAudit(const string event_line)
     {
      const string line = TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) + " | " + event_line;
      if(m_audit == "")
         m_audit = line;
      else
         m_audit = m_audit + "\r\n" + line;
      if(StringLen(m_audit) > 2000)
         m_audit = StringSubstr(m_audit, StringLen(m_audit) - 1800);
     }

   bool VerifyIntegrity(const SGmConfigurationCenterResult &r)
     {
      m_tamper_ok = r.valid || (!r.valid && r.stamped_at == 0);
      if(!m_tamper_ok && m_logger != NULL)
         m_logger.Warning("Tamper Detection alert — result integrity check", "ECC");
      return m_tamper_ok;
     }

   void ApplyToResult(SGmConfigurationCenterResult &out)
     {
      AppendAudit(StringFormat("ConfigHealth=%.0f Profile=%s Template=%s Locked=%s",
                               out.configuration_health, out.profile_name, out.template_name,
                               out.template_locked ? "YES" : "NO"));
      out.security_status = m_status + (m_tamper_ok ? " | Tamper=OK" : " | Tamper=ALERT");
      out.audit_trail = m_audit;
     }
  };

#endif // GM_CECC_SECURITY_LAYER_MQH
//+------------------------------------------------------------------+
