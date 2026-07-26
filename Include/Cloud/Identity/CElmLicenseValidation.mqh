//+------------------------------------------------------------------+
//|                                  CElmLicenseValidation.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CELM_LICENSE_VALIDATION_MQH
#define GM_CELM_LICENSE_VALIDATION_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "IdentityConstants.mqh"
#include "SGmIdentityResult.mqh"
#include "CElmLicenseEngine.mqh"
#include "CElmDeviceActivationEngine.mqh"
#include "CElmIdentitySecurity.mqh"
#include "../SGmCloudStatus.mqh"
#include "../../Core/Version.mqh"

class CGmElmLicenseValidation
  {
private:
   CGmElmIdentitySecurity *m_sec;
   bool                    m_ready;

public:
                     CGmElmLicenseValidation(void) : m_sec(NULL), m_ready(false) {}

   bool Init(CGmElmIdentitySecurity *sec)
     {
      m_sec = sec;
      m_ready = true;
      return true;
     }

   // Returns true if license checks pass OR grace/offline allows continue.
   // NEVER sets may_interrupt_trading.
   bool Validate(CGmElmLicenseEngine &lic,
                 CGmElmDeviceActivationEngine &devices,
                 const SGmCloudStatus &cloud,
                 SGmIdentityResult &out)
     {
      if(!m_ready)
         return false;

      lic.ApplyTo(out);

      const bool server_online = (cloud.valid && cloud.cloud_status == GM_CLOUD_STATUS_ONLINE);
      const bool authenticity_ok = (StringLen(lic.KeyHash()) >= 8);
      const bool version_ok = (GM_VERSION_BUILD >= 21040);
      const bool device_ok = (devices.Count() <= devices.MaxDevices());
      const bool integrity_ok = authenticity_ok;

      if(m_sec != NULL)
        {
         const string blob = m_sec.EncryptCredential(
            StringFormat("%s|%s|%I64d",
                         GmElmLicenseTypeName(lic.Type()),
                         lic.KeyHash(), (long)TimeCurrent()));
         m_sec.StoreOfflineCache(blob);
         out.offline_cache_valid = m_sec.OfflineCacheValid(GM_ELM_GRACE_DAYS * 86400);

         if(m_sec.DetectTamper(lic.KeyHash(), lic.KeyHash()))
            out.security_status = "Tamper flag raised";
        }

      // Offline / server unavailable → enter grace, trading continues
      if(!server_online)
        {
         if(!out.in_grace_period)
            lic.EnterGrace();
         lic.ApplyTo(out);
         out.offline_cache_valid = (m_sec != NULL && m_sec.OfflineCacheValid(GM_ELM_GRACE_DAYS * 86400));
         out.trading_allowed_by_grace = true;
         out.may_interrupt_trading = false;
         return true; // validation "passes" via grace — does not block EA
        }

      if(out.in_grace_period && server_online && authenticity_ok)
        {
         // Restore to enterprise when server returns (architecture)
         lic.ClearGrace(GM_ELM_LIC_ENTERPRISE);
         lic.ApplyTo(out);
        }

      const bool subscription_ok = (out.license_type != GM_ELM_LIC_SUSPENDED) &&
                                   (out.license_health >= 10.0 || out.in_grace_period);

      out.trading_allowed_by_grace = true;
      out.may_interrupt_trading = false;
      out.may_execute = false;
      out.may_modify_risk = false;

      return (authenticity_ok && version_ok && device_ok && integrity_ok && subscription_ok);
     }
  };

#endif // GM_CELM_LICENSE_VALIDATION_MQH
//+------------------------------------------------------------------+
