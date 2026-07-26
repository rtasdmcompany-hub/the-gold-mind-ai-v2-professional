//+------------------------------------------------------------------+
//|                                  CEncNotificationSecurity.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CENC_NOTIFICATION_SECURITY_MQH
#define GM_CENC_NOTIFICATION_SECURITY_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "NotificationCenterConstants.mqh"
#include "../CCloudSecurity.mqh"

class CGmEncNotificationSecurity
  {
private:
   CGmCloudSecurity *m_sec;
   bool              m_ready;

public:
                     CGmEncNotificationSecurity(void) : m_sec(NULL), m_ready(false) {}

   bool Init(CGmCloudSecurity *sec)
     {
      m_sec = sec;
      m_ready = (m_sec != NULL && m_sec.IsReady());
      return m_ready;
     }

   bool IsReady(void) const { return m_ready; }

   string SignMessage(const string body) const
     {
      if(!m_ready || m_sec == NULL) return "";
      return m_sec.SignRequest(body);
     }

   string EncryptPayload(const string plain) const
     {
      if(!m_ready || m_sec == NULL) return "";
      return m_sec.EncryptToBase64(plain);
     }

   string ApiTokenHash(const string device_id) const
     {
      if(!m_ready || m_sec == NULL) return "";
      return m_sec.HashHex("ENC_API|" + device_id + "|" + GM_ENC_POLICY);
     }

   bool ValidateWebhook(const string signature, const string body) const
     {
      if(!m_ready) return false;
      return (signature == SignMessage(body) && StringLen(signature) >= 8);
     }
  };

#endif // GM_CENC_NOTIFICATION_SECURITY_MQH
//+------------------------------------------------------------------+
