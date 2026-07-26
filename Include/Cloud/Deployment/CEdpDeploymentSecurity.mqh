//+------------------------------------------------------------------+
//|                                   CEdpDeploymentSecurity.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEDP_DEPLOYMENT_SECURITY_MQH
#define GM_CEDP_DEPLOYMENT_SECURITY_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "DeploymentConstants.mqh"
#include "../CCloudSecurity.mqh"

class CGmEdpDeploymentSecurity
  {
private:
   CGmCloudSecurity *m_sec;
   string            m_trusted_source;
   int               m_tamper;
   bool              m_ready;

public:
                     CGmEdpDeploymentSecurity(void)
                       : m_sec(NULL), m_trusted_source("rtas.group/goldmind/releases"),
                         m_tamper(0), m_ready(false) {}

   bool Init(CGmCloudSecurity *sec)
     {
      m_sec = sec;
      m_tamper = 0;
      m_ready = (m_sec != NULL && m_sec.IsReady());
      return m_ready;
     }

   bool IsReady(void) const { return m_ready; }
   string TrustedSource(void) const { return m_trusted_source; }
   int TamperCount(void) const { return m_tamper; }

   string EncryptPackage(const string plain) const
     {
      if(!m_ready || m_sec == NULL) return "";
      return m_sec.EncryptToBase64(plain);
     }

   string SignPackage(const string body) const
     {
      if(!m_ready || m_sec == NULL) return "";
      return m_sec.SignRequest("EDP|" + body + "|" + m_trusted_source);
     }

   string PackageHash(const string body) const
     {
      if(!m_ready || m_sec == NULL) return "";
      return m_sec.HashHex(body);
     }

   bool VerifySignature(const string body, const string signature)
     {
      const string expect = SignPackage(body);
      if(StringLen(signature) >= 8 && signature == expect)
         return true;
      m_tamper++;
      return false;
     }

   bool ApproveRelease(const string release_id, const string approver_hash) const
     {
      if(!m_ready || m_sec == NULL) return false;
      return (StringLen(approver_hash) >= 8 &&
              StringLen(m_sec.HashHex("APPROVE|" + release_id + "|" + approver_hash)) >= 8);
     }

   string AuditLine(void) const
     {
      return StringFormat("SignedUpdates+EncryptedPkgs | source=%s | tamper=%d",
                          m_trusted_source, m_tamper);
     }
  };

#endif // GM_CEDP_DEPLOYMENT_SECURITY_MQH
//+------------------------------------------------------------------+
