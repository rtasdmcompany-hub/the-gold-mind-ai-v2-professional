//+------------------------------------------------------------------+
//|                                    CLicenseSessionEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Architecture only — no payment integration                  |
//+------------------------------------------------------------------+
#ifndef GM_CLICENSE_SESSION_ENGINE_MQH
#define GM_CLICENSE_SESSION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CloudConstants.mqh"
#include "CCloudSecurity.mqh"
#include "CDeviceIdentityEngine.mqh"

class CGmLicenseSessionEngine
  {
private:
   CGmCloudSecurity        *m_sec;
   CGmDeviceIdentityEngine *m_device;
   ENUM_GM_LICENSE_TIER     m_tier;
   string                   m_session_token_hash;
   datetime                 m_started_at;
   datetime                 m_grace_until;
   bool                     m_ready;

public:
                     CGmLicenseSessionEngine(void)
                       : m_sec(NULL), m_device(NULL),
                         m_tier(GM_LICENSE_PROFESSIONAL),
                         m_started_at(0), m_grace_until(0), m_ready(false) {}

   bool Init(CGmCloudSecurity *sec, CGmDeviceIdentityEngine *device)
     {
      m_sec = sec;
      m_device = device;
      m_tier = GM_LICENSE_PROFESSIONAL; // default architecture tier
      m_started_at = TimeCurrent();
      m_grace_until = 0;
      if(m_sec != NULL && m_device != NULL && m_device.IsReady())
        {
         m_session_token_hash = m_sec.HashHex(
            StringFormat("LIC|%s|%s|%s|%I64d",
                         GmLicenseTierName(m_tier),
                         m_device.CompositeHash(),
                         GM_CLOUD_POLICY,
                         (long)m_started_at));
         m_ready = m_sec.ValidateSessionToken(m_session_token_hash);
        }
      return m_ready;
     }

   bool IsReady(void) const { return m_ready; }
   ENUM_GM_LICENSE_TIER Tier(void) const { return m_tier; }
   string TokenHash(void) const { return m_session_token_hash; }

   string StatusText(void) const
     {
      if(m_tier == GM_LICENSE_EXPIRED) return "Expired";
      if(m_tier == GM_LICENSE_DISABLED) return "Disabled";
      if(m_tier == GM_LICENSE_GRACE) return "Grace Period";
      return GmLicenseTierName(m_tier) + " (Architecture)";
     }

   // Future: remote license validation — NEVER gates trading in Sprint 1
   bool RefreshArchitectureSession(void)
     {
      if(!m_ready || m_sec == NULL || m_device == NULL)
         return false;
      m_session_token_hash = m_sec.HashHex(
         StringFormat("LIC|%s|%s|%I64u|%I64d",
                      GmLicenseTierName(m_tier),
                      m_device.CompositeHash(),
                      m_sec.NextNonce(),
                      (long)TimeCurrent()));
      return true;
     }
  };

#endif // GM_CLICENSE_SESSION_ENGINE_MQH
//+------------------------------------------------------------------+
