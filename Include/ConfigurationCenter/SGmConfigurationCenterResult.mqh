//+------------------------------------------------------------------+
//|                            SGmConfigurationCenterResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_CONFIGURATION_CENTER_RESULT_MQH
#define GM_SGM_CONFIGURATION_CENTER_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ConfigurationCenterConstants.mqh"

struct SGmConfigurationCenterResult
  {
   datetime           stamped_at;
   ENUM_GM_ECC_QUEUE  queue_status;
   ENUM_GM_ECC_PROFILE current_profile;
   ENUM_GM_ECC_TEMPLATE current_template;

   double             configuration_health;
   int                profile_version;
   int                template_version;
   int                active_gm_trades;
   bool               template_locked;
   bool               may_apply_template;

   string             profile_name;
   string             template_name;
   string             workspace_status;
   string             last_backup;
   string             import_status;
   string             export_status;
   string             config_summary;
   string             security_status;
   string             audit_trail;
   string             center_status;
   string             insight;

   bool               may_execute;
   bool               may_modify_risk;
   bool               may_interrupt_trading;
   bool               may_modify_live_params;
   bool               valid;

   void Reset(void)
     {
      stamped_at = 0;
      queue_status = GM_ECC_Q_IDLE;
      current_profile = GM_ECC_PROF_PRODUCTION;
      current_template = GM_ECC_TMPL_GOLDMIND_DEFAULT;
      configuration_health = 0.0;
      profile_version = template_version = 0;
      active_gm_trades = 0;
      template_locked = false;
      may_apply_template = false;
      profile_name = template_name = workspace_status = "";
      last_backup = import_status = export_status = "";
      config_summary = security_status = audit_trail = "";
      center_status = insight = "";
      may_execute = false;
      may_modify_risk = false;
      may_interrupt_trading = false;
      may_modify_live_params = false;
      valid = false;
     }
  };

#endif // GM_SGM_CONFIGURATION_CENTER_RESULT_MQH
//+------------------------------------------------------------------+
