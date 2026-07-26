//+------------------------------------------------------------------+
//|                                      SGmDeploymentResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_DEPLOYMENT_RESULT_MQH
#define GM_SGM_DEPLOYMENT_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "DeploymentConstants.mqh"

struct SGmDeploymentResult
  {
   datetime              stamped_at;
   ENUM_GM_EDP_ENV       environment;
   ENUM_GM_EDP_CHANNEL   channel;
   ENUM_GM_EDP_UPDATE     update_status;
   ENUM_GM_EDP_DEPLOY    deploy_status;

   string                current_version;
   string                latest_version;
   int                   current_build;
   int                   latest_build;
   string                release_notes;
   string                deployment_status_text;
   string                update_status_text;
   string                rollback_status;
   string                package_integrity;
   string                production_readiness;
   string                approval_status;
   double                deployment_health;
   double                release_readiness;
   double                production_health;
   int                   active_gm_trades;
   bool                  update_deferred;
   bool                  may_execute;
   bool                  may_modify_risk;
   bool                  may_interrupt_trading;
   bool                  may_install_now;
   string                center_status;
   string                insight;
   bool                  valid;

   void Reset(void)
     {
      stamped_at = 0;
      environment = GM_EDP_ENV_PRODUCTION;
      channel = GM_EDP_CH_STABLE;
      update_status = GM_EDP_UPD_IDLE;
      deploy_status = GM_EDP_DEP_IDLE;
      current_version = latest_version = "";
      current_build = latest_build = 0;
      release_notes = deployment_status_text = update_status_text = "";
      rollback_status = package_integrity = production_readiness = "";
      approval_status = "";
      deployment_health = release_readiness = production_health = 0.0;
      active_gm_trades = 0;
      update_deferred = false;
      may_execute = false;
      may_modify_risk = false;
      may_interrupt_trading = false;
      may_install_now = false;
      center_status = insight = "";
      valid = false;
     }
  };

#endif // GM_SGM_DEPLOYMENT_RESULT_MQH
//+------------------------------------------------------------------+
