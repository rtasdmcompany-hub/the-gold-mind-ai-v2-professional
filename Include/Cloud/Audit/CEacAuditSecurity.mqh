//+------------------------------------------------------------------+
//|                                           CEacAuditSecurity.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEAC_AUDIT_SECURITY_MQH
#define GM_CEAC_AUDIT_SECURITY_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "AuditConstants.mqh"
#include "../CCloudSecurity.mqh"

class CGmEacAuditSecurity
  {
private:
   CGmCloudSecurity   *m_sec;
   ENUM_GM_EAC_ROLE    m_role;
   string              m_chain_hash;
   int                 m_tamper;
   bool                m_ready;

public:
                     CGmEacAuditSecurity(void)
                       : m_sec(NULL), m_role(GM_EAC_ROLE_AUDITOR),
                         m_chain_hash(""), m_tamper(0), m_ready(false) {}

   bool Init(CGmCloudSecurity *sec)
     {
      m_sec = sec;
      m_role = GM_EAC_ROLE_AUDITOR;
      m_chain_hash = "";
      m_tamper = 0;
      m_ready = (m_sec != NULL && m_sec.IsReady());
      if(m_ready)
         m_chain_hash = m_sec.HashHex("EAC_GENESIS|" + GM_EAC_VERSION);
      return m_ready;
     }

   bool IsReady(void) const { return m_ready; }
   ENUM_GM_EAC_ROLE Role(void) const { return m_role; }
   int TamperCount(void) const { return m_tamper; }
   string ChainHash(void) const { return m_chain_hash; }

   string EncryptAudit(const string plain) const
     {
      if(!m_ready || m_sec == NULL) return "";
      return m_sec.EncryptToBase64(plain);
     }

   string SignEntry(const string body) const
     {
      if(!m_ready || m_sec == NULL) return "";
      return m_sec.SignRequest(body + "|" + m_chain_hash);
     }

   // Append-only chain: each entry seals previous hash (immutable architecture)
   string SealEntry(const string body)
     {
      if(!m_ready || m_sec == NULL) return "";
      const string next = m_sec.HashHex(m_chain_hash + "|" + body);
      m_chain_hash = next;
      return next;
     }

   bool VerifyExport(const string payload, const string signature) const
     {
      if(!m_ready || m_sec == NULL) return false;
      return (signature == m_sec.SignRequest(payload) && StringLen(signature) >= 8);
     }

   bool CanExport(void) const
     {
      return (m_role == GM_EAC_ROLE_AUDITOR ||
              m_role == GM_EAC_ROLE_COMPLIANCE ||
              m_role == GM_EAC_ROLE_ADMIN);
     }

   bool DetectTamper(const string expected, const string actual)
     {
      if(StringLen(expected) == 0 || expected == actual)
         return false;
      m_tamper++;
      return true;
     }

   string SecurityStatus(void) const
     {
      return StringFormat("Immutable+Signed | role=%s | tamper=%d | chain=%s",
                          GmEacRoleName(m_role), m_tamper,
                          StringLen(m_chain_hash) > 8 ? StringSubstr(m_chain_hash, 0, 8) : "n/a");
     }
  };

#endif // GM_CEAC_AUDIT_SECURITY_MQH
//+------------------------------------------------------------------+
