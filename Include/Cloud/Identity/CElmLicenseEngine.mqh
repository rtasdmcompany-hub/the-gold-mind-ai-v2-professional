//+------------------------------------------------------------------+
//|                                      CElmLicenseEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CELM_LICENSE_ENGINE_MQH
#define GM_CELM_LICENSE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "IdentityConstants.mqh"
#include "SGmIdentityResult.mqh"
#include "CElmIdentitySecurity.mqh"

class CGmElmLicenseEngine
  {
private:
   CGmElmIdentitySecurity  *m_sec;
   ENUM_GM_ELM_LICENSE_TYPE m_type;
   string                   m_key_hash;
   datetime                 m_activated;
   datetime                 m_expires;
   datetime                 m_grace_until;
   bool                     m_ready;

   int DaysBetween(const datetime from_t, const datetime to_t) const
     {
      if(to_t <= from_t) return 0;
      return (int)((to_t - from_t) / 86400);
     }

public:
                     CGmElmLicenseEngine(void)
                       : m_sec(NULL), m_type(GM_ELM_LIC_ENTERPRISE),
                         m_key_hash(""), m_activated(0), m_expires(0),
                         m_grace_until(0), m_ready(false) {}

   bool Init(CGmElmIdentitySecurity *sec,
             const ENUM_GM_ELM_LICENSE_TYPE type = GM_ELM_LIC_ENTERPRISE)
     {
      m_sec = sec;
      m_type = type;
      m_activated = TimeCurrent();
      // Architecture defaults: yearly enterprise window
      if(type == GM_ELM_LIC_LIFETIME)
         m_expires = m_activated + (3650 * 86400);
      else if(type == GM_ELM_LIC_MONTHLY)
         m_expires = m_activated + (30 * 86400);
      else if(type == GM_ELM_LIC_QUARTERLY)
         m_expires = m_activated + (90 * 86400);
      else if(type == GM_ELM_LIC_TRIAL || type == GM_ELM_LIC_DEMO)
         m_expires = m_activated + (14 * 86400);
      else
         m_expires = m_activated + (365 * 86400);

      m_grace_until = 0;
      m_key_hash = (m_sec != NULL)
                   ? m_sec.HashHex(StringFormat("LICKEY|%s|%I64d|%s",
                                                GmElmLicenseTypeName(type),
                                                (long)m_activated, GM_ELM_VERSION))
                   : "";
      m_ready = true;
      return true;
     }

   ENUM_GM_ELM_LICENSE_TYPE Type(void) const { return m_type; }
   string KeyHash(void) const { return m_key_hash; }
   datetime Activated(void) const { return m_activated; }
   datetime Expires(void) const { return m_expires; }
   datetime GraceUntil(void) const { return m_grace_until; }

   void EnterGrace(void)
     {
      if(m_grace_until == 0)
         m_grace_until = TimeCurrent() + (GM_ELM_GRACE_DAYS * 86400);
      m_type = GM_ELM_LIC_GRACE;
     }

   void ClearGrace(const ENUM_GM_ELM_LICENSE_TYPE restore)
     {
      m_grace_until = 0;
      if(m_type == GM_ELM_LIC_GRACE)
         m_type = restore;
     }

   void ApplyTo(SGmIdentityResult &out) const
     {
      if(!m_ready) return;

      out.license_type = m_type;
      out.license_key_hash = m_key_hash;
      out.activation_date = m_activated;
      out.expiration_date = m_expires;
      out.remaining_days = DaysBetween(TimeCurrent(), m_expires);
      out.activation_status = "Activated";

      const bool past = (TimeCurrent() > m_expires);
      const bool in_grace = (m_grace_until > 0 && TimeCurrent() <= m_grace_until) ||
                            (m_type == GM_ELM_LIC_GRACE);

      out.in_grace_period = in_grace;
      out.grace_period_status = in_grace
                                ? StringFormat("Active until %s",
                                               TimeToString(m_grace_until > 0 ? m_grace_until : m_expires,
                                                            TIME_DATE))
                                : "Not Required";

      if(m_type == GM_ELM_LIC_SUSPENDED)
        {
         out.license_status = "Suspended";
         out.expiration_status = "Suspended";
         out.license_health = 25.0;
        }
      else if(past && !in_grace)
        {
         out.license_status = "Expired";
         out.expiration_status = "Expired";
         out.license_health = 10.0;
        }
      else if(in_grace)
        {
         out.license_status = "Grace Period";
         out.expiration_status = "Grace";
         out.license_health = 55.0;
        }
      else
        {
         out.license_status = GmElmLicenseTypeName(m_type);
         out.expiration_status = (out.remaining_days <= 14) ? "Expiring Soon" : "Valid";
         out.license_health = MathMin(100.0, 60.0 + (double)out.remaining_days * 0.1);
         if(out.license_health > 100.0) out.license_health = 100.0;
        }

      // CRITICAL: never block trading from this layer
      out.trading_allowed_by_grace = true;
     }
  };

#endif // GM_CELM_LICENSE_ENGINE_MQH
//+------------------------------------------------------------------+
