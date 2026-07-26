//+------------------------------------------------------------------+
//|                                       IdentityConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 6 Sprint 5 — License / Auth / Subscription            |
//|     IDENTITY ONLY — NEVER interrupts trading                    |
//+------------------------------------------------------------------+
#ifndef GM_IDENTITY_CONSTANTS_MQH
#define GM_IDENTITY_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_ELM_VERSION              "1.0.0-enterprise-identity"
#define GM_ELM_DB_PREFIX            "GM_CLOUD_ELM_"
#define GM_ELM_THROTTLE_MS          15000
#define GM_ELM_DEVICE_MAX           8
#define GM_ELM_HIST_MAX             48
#define GM_ELM_GRACE_DAYS           7
#define GM_ELM_SESSION_TIMEOUT_SEC  86400
#define GM_ELM_POLICY               "IDENTITY & LICENSE ONLY — NO TRADING AUTHORITY"
#define GM_ELM_SAFE                 "GRACE PERIOD — TRADING CONTINUES IF LICENSE SERVER OFFLINE"

enum ENUM_GM_ELM_LICENSE_TYPE
  {
   GM_ELM_LIC_TRIAL = 0,
   GM_ELM_LIC_MONTHLY,
   GM_ELM_LIC_QUARTERLY,
   GM_ELM_LIC_YEARLY,
   GM_ELM_LIC_LIFETIME,
   GM_ELM_LIC_ENTERPRISE,
   GM_ELM_LIC_DEVELOPER,
   GM_ELM_LIC_DEMO,
   GM_ELM_LIC_EXPIRED,
   GM_ELM_LIC_SUSPENDED,
   GM_ELM_LIC_GRACE
  };

enum ENUM_GM_ELM_AUTH_STATE
  {
   GM_ELM_AUTH_ANONYMOUS = 0,
   GM_ELM_AUTH_AUTHENTICATED,
   GM_ELM_AUTH_SESSION_EXPIRED,
   GM_ELM_AUTH_FAILED,
   GM_ELM_AUTH_2FA_PENDING,
   GM_ELM_AUTH_SSO_READY
  };

enum ENUM_GM_ELM_ROLE
  {
   GM_ELM_ROLE_VIEWER = 0,
   GM_ELM_ROLE_TRADER,
   GM_ELM_ROLE_ADMIN,
   GM_ELM_ROLE_DEVELOPER,
   GM_ELM_ROLE_ENTERPRISE
  };

enum ENUM_GM_ELM_DEVICE_ROLE
  {
   GM_ELM_DEV_PRIMARY = 0,
   GM_ELM_DEV_SECONDARY,
   GM_ELM_DEV_REVOKED,
   GM_ELM_DEV_PENDING
  };

string GmElmLicenseTypeName(const ENUM_GM_ELM_LICENSE_TYPE t)
  {
   switch(t)
     {
      case GM_ELM_LIC_TRIAL:      return "Trial";
      case GM_ELM_LIC_MONTHLY:    return "Monthly";
      case GM_ELM_LIC_QUARTERLY:  return "Quarterly";
      case GM_ELM_LIC_YEARLY:     return "Yearly";
      case GM_ELM_LIC_LIFETIME:   return "Lifetime";
      case GM_ELM_LIC_ENTERPRISE: return "Enterprise";
      case GM_ELM_LIC_DEVELOPER:  return "Developer";
      case GM_ELM_LIC_DEMO:       return "Demo";
      case GM_ELM_LIC_EXPIRED:    return "Expired";
      case GM_ELM_LIC_SUSPENDED:  return "Suspended";
      case GM_ELM_LIC_GRACE:      return "Grace Period";
     }
   return "Unknown";
  }

string GmElmAuthStateName(const ENUM_GM_ELM_AUTH_STATE s)
  {
   switch(s)
     {
      case GM_ELM_AUTH_AUTHENTICATED:   return "Authenticated";
      case GM_ELM_AUTH_SESSION_EXPIRED: return "Session Expired";
      case GM_ELM_AUTH_FAILED:          return "Failed";
      case GM_ELM_AUTH_2FA_PENDING:     return "2FA Pending";
      case GM_ELM_AUTH_SSO_READY:       return "SSO Ready";
     }
   return "Anonymous";
  }

string GmElmRoleName(const ENUM_GM_ELM_ROLE r)
  {
   switch(r)
     {
      case GM_ELM_ROLE_TRADER:     return "Trader";
      case GM_ELM_ROLE_ADMIN:      return "Admin";
      case GM_ELM_ROLE_DEVELOPER:  return "Developer";
      case GM_ELM_ROLE_ENTERPRISE: return "Enterprise";
     }
   return "Viewer";
  }

string GmElmDeviceRoleName(const ENUM_GM_ELM_DEVICE_ROLE d)
  {
   switch(d)
     {
      case GM_ELM_DEV_PRIMARY:   return "Primary";
      case GM_ELM_DEV_SECONDARY: return "Secondary";
      case GM_ELM_DEV_REVOKED:   return "Revoked";
      case GM_ELM_DEV_PENDING:   return "Pending";
     }
   return "Unknown";
  }

#endif // GM_IDENTITY_CONSTANTS_MQH
//+------------------------------------------------------------------+
