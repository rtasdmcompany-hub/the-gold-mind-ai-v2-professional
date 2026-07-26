//+------------------------------------------------------------------+
//|                                          CBdrBackupSecurity.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CBDR_BACKUP_SECURITY_MQH
#define GM_CBDR_BACKUP_SECURITY_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "BackupConstants.mqh"
#include "../CCloudSecurity.mqh"

class CGmBdrBackupSecurity
  {
private:
   CGmCloudSecurity *m_sec;
   string            m_key_hash;
   int               m_tamper;
   bool              m_ready;

public:
                     CGmBdrBackupSecurity(void)
                       : m_sec(NULL), m_key_hash(""), m_tamper(0), m_ready(false) {}

   bool Init(CGmCloudSecurity *sec)
     {
      m_sec = sec;
      m_key_hash = (m_sec != NULL) ? m_sec.HashHex("BDR_KEY|" + GM_BDR_VERSION + "|" + GM_BDR_POLICY) : "";
      m_tamper = 0;
      m_ready = (m_sec != NULL && m_sec.IsReady());
      return m_ready;
     }

   bool IsReady(void) const { return m_ready; }
   string KeyHash(void) const { return m_key_hash; }
   int TamperCount(void) const { return m_tamper; }

   string EncryptPayload(const string plain) const
     {
      if(!m_ready || m_sec == NULL) return "";
      return m_sec.EncryptToBase64(plain);
     }

   string SignBackup(const string body) const
     {
      if(!m_ready || m_sec == NULL) return "";
      return m_sec.SignRequest(body);
     }

   string IntegrityHash(const string body) const
     {
      if(!m_ready || m_sec == NULL) return "";
      return m_sec.HashHex(body);
     }

   bool VerifyIntegrity(const string body, const string expected)
     {
      const string actual = IntegrityHash(body);
      if(StringLen(expected) == 0 || actual == expected)
         return true;
      m_tamper++;
      return false;
     }

   string AccessControlLine(void) const
     {
      return "RBAC=BackupOperator | key=" +
             (StringLen(m_key_hash) > 8 ? StringSubstr(m_key_hash, 0, 8) : "n/a") +
             " | tamper=" + IntegerToString(m_tamper);
     }
  };

#endif // GM_CBDR_BACKUP_SECURITY_MQH
//+------------------------------------------------------------------+
