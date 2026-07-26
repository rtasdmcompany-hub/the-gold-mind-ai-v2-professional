//+------------------------------------------------------------------+
//|                               CEifInfrastructureSecurity.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEIF_INFRASTRUCTURE_SECURITY_MQH
#define GM_CEIF_INFRASTRUCTURE_SECURITY_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "InfrastructureConstants.mqh"
#include "../CCloudSecurity.mqh"

class CGmEifInfrastructureSecurity
  {
private:
   CGmCloudSecurity *m_sec;
   string            m_trusted[GM_EIF_DEVICE_MAX];
   int               m_trusted_n;
   int               m_unauth_attempts;
   bool              m_ready;

public:
                     CGmEifInfrastructureSecurity(void)
                       : m_sec(NULL), m_trusted_n(0), m_unauth_attempts(0), m_ready(false) {}

   bool Init(CGmCloudSecurity *sec)
     {
      m_sec = sec;
      m_trusted_n = 0;
      m_unauth_attempts = 0;
      m_ready = (m_sec != NULL && m_sec.IsReady());
      return m_ready;
     }

   bool IsReady(void) const { return m_ready; }
   int  UnauthorizedAttempts(void) const { return m_unauth_attempts; }

   string DeviceToken(const string device_id) const
     {
      if(!m_ready || m_sec == NULL) return "";
      return m_sec.HashHex("EIF_DEV|" + device_id + "|" + GM_EIF_POLICY);
     }

   string EncryptSession(const string plain) const
     {
      if(!m_ready || m_sec == NULL) return "";
      return m_sec.EncryptToBase64(plain);
     }

   string SignPayload(const string body) const
     {
      if(!m_ready || m_sec == NULL) return "";
      return m_sec.SignRequest(body);
     }

   bool RegisterTrusted(const string token_hash)
     {
      if(!m_ready || StringLen(token_hash) < 8) return false;
      for(int i = 0; i < m_trusted_n; i++)
         if(m_trusted[i] == token_hash)
            return true;
      if(m_trusted_n >= GM_EIF_DEVICE_MAX) return false;
      m_trusted[m_trusted_n++] = token_hash;
      return true;
     }

   bool ValidateSession(const string token_hash)
     {
      if(!m_ready) return false;
      for(int i = 0; i < m_trusted_n; i++)
         if(m_trusted[i] == token_hash)
            return true;
      m_unauth_attempts++;
      return false;
     }

   string AuditLine(void) const
     {
      return StringFormat("trusted=%d unauth=%d | %s",
                          m_trusted_n, m_unauth_attempts, GM_EIF_POLICY);
     }
  };

#endif // GM_CEIF_INFRASTRUCTURE_SECURITY_MQH
//+------------------------------------------------------------------+
