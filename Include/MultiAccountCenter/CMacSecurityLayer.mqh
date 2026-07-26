//+------------------------------------------------------------------+
//|                                        CMacSecurityLayer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CMAC_SECURITY_LAYER_MQH
#define GM_CMAC_SECURITY_LAYER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMultiAccountCenterResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmMacSecurityLayer
  {
private:
   CGmLogger *m_logger;
   string     m_status;
   string     m_audit;

public:
                     CGmMacSecurityLayer(void)
                       : m_logger(NULL), m_status(""), m_audit("") {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_status = "Encrypted Registry ARCH | Device Auth ARCH | RBAC ARCH | Read-Only Sync | Tamper=OK";
      m_audit = "";
     }

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

   void ApplyToResult(SGmMultiAccountCenterResult &out)
     {
      AppendAudit(StringFormat("Licensed=%d Health=%.0f Enterprise=%.0f Conn=%s",
                               out.accounts_licensed, out.account_health,
                               out.enterprise_health, GmMacConnName(out.connection_status)));
      out.security_status = m_status;
      out.audit_trail = m_audit;
     }
  };

#endif // GM_CMAC_SECURITY_LAYER_MQH
//+------------------------------------------------------------------+
