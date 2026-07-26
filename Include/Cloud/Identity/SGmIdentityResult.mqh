//+------------------------------------------------------------------+
//|                                      SGmIdentityResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_IDENTITY_RESULT_MQH
#define GM_SGM_IDENTITY_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "IdentityConstants.mqh"

struct SGmIdentityResult
  {
   datetime                 stamped_at;
   ENUM_GM_ELM_LICENSE_TYPE license_type;
   ENUM_GM_ELM_AUTH_STATE   auth_state;
   ENUM_GM_ELM_ROLE         role;

   string                   license_status;
   string                   license_key_hash;
   datetime                 activation_date;
   datetime                 expiration_date;
   int                      remaining_days;
   double                   license_health;
   string                   activation_status;
   string                   expiration_status;
   string                   grace_period_status;
   bool                     in_grace_period;
   bool                     offline_cache_valid;
   bool                     trading_allowed_by_grace; // always true during grace/offline

   string                   user_id_hash;
   string                   user_profile;
   string                   session_token_jwt;
   string                   session_status;
   string                   auth_status;
   string                   security_status;
   bool                     two_factor_architecture;
   bool                     sso_ready;

   int                      activated_devices;
   int                      max_devices;
   string                   current_device;
   string                   device_manager_summary;
   string                   activation_history;
   string                   admin_api_catalog;

   string                   center_status;
   string                   insight;
   bool                     may_execute;       // ALWAYS false
   bool                     may_modify_risk;   // ALWAYS false
   bool                     may_interrupt_trading; // ALWAYS false
   bool                     valid;

   void Reset(void)
     {
      stamped_at = 0;
      license_type = GM_ELM_LIC_ENTERPRISE;
      auth_state = GM_ELM_AUTH_ANONYMOUS;
      role = GM_ELM_ROLE_VIEWER;
      license_status = activation_status = expiration_status = "";
      license_key_hash = "";
      activation_date = expiration_date = 0;
      remaining_days = 0;
      license_health = 0.0;
      grace_period_status = "";
      in_grace_period = false;
      offline_cache_valid = false;
      trading_allowed_by_grace = true;
      user_id_hash = user_profile = "";
      session_token_jwt = session_status = auth_status = security_status = "";
      two_factor_architecture = true;
      sso_ready = true;
      activated_devices = max_devices = 0;
      current_device = device_manager_summary = activation_history = "";
      admin_api_catalog = "";
      center_status = insight = "";
      may_execute = false;
      may_modify_risk = false;
      may_interrupt_trading = false;
      valid = false;
     }
  };

#endif // GM_SGM_IDENTITY_RESULT_MQH
//+------------------------------------------------------------------+
