//+------------------------------------------------------------------+
//|                                         CElmIdentitySecurity.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CELM_IDENTITY_SECURITY_MQH
#define GM_CELM_IDENTITY_SECURITY_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "IdentityConstants.mqh"
#include "../CCloudSecurity.mqh"

class CGmElmIdentitySecurity
  {
private:
   CGmCloudSecurity *m_sec;
   string            m_cache_blob;
   datetime          m_cache_at;
   int               m_tamper_flags;
   bool              m_ready;

public:
                     CGmElmIdentitySecurity(void)
                       : m_sec(NULL), m_cache_blob(""), m_cache_at(0),
                         m_tamper_flags(0), m_ready(false) {}

   bool Init(CGmCloudSecurity *sec)
     {
      m_sec = sec;
      m_cache_blob = "";
      m_cache_at = 0;
      m_tamper_flags = 0;
      m_ready = (m_sec != NULL && m_sec.IsReady());
      return m_ready;
     }

   bool IsReady(void) const { return m_ready; }
   int  TamperFlags(void) const { return m_tamper_flags; }

   string EncryptCredential(const string plain) const
     {
      if(!m_ready || m_sec == NULL) return "";
      return m_sec.EncryptToBase64(plain);
     }

   string HashHex(const string payload) const
     {
      if(!m_ready || m_sec == NULL) return "";
      return m_sec.HashHex(payload);
     }

   // Architecture JWT-style token (signed local session — not a payment JWT)
   string BuildJwtSession(const string user_hash, const string device_fp,
                          const ENUM_GM_ELM_ROLE role, const datetime exp) const
     {
      if(!m_ready || m_sec == NULL) return "";
      const string header = "eyJhbGciOiJHTVNIQTI1NiIsInR5cCI6IkpXVCJ9"; // architecture header
      const string payload = StringFormat("uid=%s|dev=%s|role=%s|exp=%I64d|pol=%s",
                                          user_hash, device_fp, GmElmRoleName(role),
                                          (long)exp, GM_ELM_POLICY);
      const string sig = m_sec.SignRequest(payload);
      return header + "." + m_sec.HashHex(payload) + "." + sig;
     }

   bool ValidateJwtShape(const string jwt) const
     {
      if(StringLen(jwt) < 20) return false;
      int dots = 0;
      for(int i = 0; i < StringLen(jwt); i++)
         if(StringGetCharacter(jwt, i) == '.')
            dots++;
      return (dots == 2);
     }

   string DeviceFingerprint(const string terminal_name, const long account) const
     {
      return HashHex(StringFormat("FP|%s|%I64d|%s",
                                  terminal_name, account, TerminalInfoString(TERMINAL_PATH)));
     }

   void StoreOfflineCache(const string encrypted_blob)
     {
      m_cache_blob = encrypted_blob;
      m_cache_at = TimeCurrent();
     }

   bool OfflineCacheValid(const int max_age_sec) const
     {
      if(StringLen(m_cache_blob) == 0 || m_cache_at <= 0) return false;
      return ((TimeCurrent() - m_cache_at) <= max_age_sec);
     }

   string OfflineCache(void) const { return m_cache_blob; }

   bool DetectTamper(const string expected_hash, const string actual_hash)
     {
      if(StringLen(expected_hash) == 0 || expected_hash == actual_hash)
         return false;
      m_tamper_flags++;
      return true;
     }

   string SecurityStatus(const ENUM_GM_ELM_ROLE role) const
     {
      return StringFormat("AES+JWT+RBAC=%s | tamper=%d | cache=%s",
                          GmElmRoleName(role), m_tamper_flags,
                          OfflineCacheValid(GM_ELM_GRACE_DAYS * 86400) ? "OK" : "Empty");
     }
  };

#endif // GM_CELM_IDENTITY_SECURITY_MQH
//+------------------------------------------------------------------+
