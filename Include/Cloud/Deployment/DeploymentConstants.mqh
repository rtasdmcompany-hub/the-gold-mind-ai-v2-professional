//+------------------------------------------------------------------+
//|                                    DeploymentConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 6 Sprint 9 — Deployment / Auto-Update / Release Mgmt  |
//|     LIFECYCLE ONLY — NEVER interrupts trading                   |
//+------------------------------------------------------------------+
#ifndef GM_DEPLOYMENT_CONSTANTS_MQH
#define GM_DEPLOYMENT_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_EDP_VERSION              "1.0.0-enterprise-deployment"
#define GM_EDP_DB_PREFIX            "GM_CLOUD_EDP_"
#define GM_EDP_THROTTLE_MS          20000
#define GM_EDP_HIST_MAX             48
#define GM_EDP_POLICY               "DEPLOYMENT LIFECYCLE ONLY — NO TRADING AUTHORITY"
#define GM_EDP_SAFE                 "DEFER UPDATES WHILE GM TRADES ACTIVE — TRADING FIRST"

enum ENUM_GM_EDP_ENV
  {
   GM_EDP_ENV_DEVELOPMENT = 0,
   GM_EDP_ENV_TESTING,
   GM_EDP_ENV_STAGING,
   GM_EDP_ENV_PRODUCTION
  };

enum ENUM_GM_EDP_CHANNEL
  {
   GM_EDP_CH_STABLE = 0,
   GM_EDP_CH_BETA,
   GM_EDP_CH_HOTFIX,
   GM_EDP_CH_PATCH
  };

enum ENUM_GM_EDP_UPDATE
  {
   GM_EDP_UPD_IDLE = 0,
   GM_EDP_UPD_AVAILABLE,
   GM_EDP_UPD_DOWNLOADING,
   GM_EDP_UPD_VERIFYING,
   GM_EDP_UPD_SCHEDULED,
   GM_EDP_UPD_DEFERRED,
   GM_EDP_UPD_INSTALLING,
   GM_EDP_UPD_OK,
   GM_EDP_UPD_FAILED,
   GM_EDP_UPD_MANDATORY_PENDING
  };

enum ENUM_GM_EDP_DEPLOY
  {
   GM_EDP_DEP_IDLE = 0,
   GM_EDP_DEP_PREPARING,
   GM_EDP_DEP_VALIDATING,
   GM_EDP_DEP_PROMOTING,
   GM_EDP_DEP_OK,
   GM_EDP_DEP_FAILED,
   GM_EDP_DEP_ROLLBACK_READY
  };

string GmEdpEnvName(const ENUM_GM_EDP_ENV e)
  {
   switch(e)
     {
      case GM_EDP_ENV_DEVELOPMENT: return "Development";
      case GM_EDP_ENV_TESTING:     return "Testing";
      case GM_EDP_ENV_STAGING:     return "Staging";
      case GM_EDP_ENV_PRODUCTION:  return "Production";
     }
   return "Development";
  }

string GmEdpChannelName(const ENUM_GM_EDP_CHANNEL c)
  {
   switch(c)
     {
      case GM_EDP_CH_BETA:   return "Beta";
      case GM_EDP_CH_HOTFIX: return "Hotfix";
      case GM_EDP_CH_PATCH:  return "Patch";
     }
   return "Stable";
  }

string GmEdpUpdateName(const ENUM_GM_EDP_UPDATE u)
  {
   switch(u)
     {
      case GM_EDP_UPD_AVAILABLE:         return "Update Available";
      case GM_EDP_UPD_DOWNLOADING:       return "Downloading";
      case GM_EDP_UPD_VERIFYING:         return "Verifying";
      case GM_EDP_UPD_SCHEDULED:         return "Scheduled";
      case GM_EDP_UPD_DEFERRED:          return "Deferred (Trades Active)";
      case GM_EDP_UPD_INSTALLING:        return "Installing";
      case GM_EDP_UPD_OK:                return "Update OK";
      case GM_EDP_UPD_FAILED:            return "Update Failed";
      case GM_EDP_UPD_MANDATORY_PENDING: return "Mandatory Pending";
     }
   return "Idle";
  }

string GmEdpDeployName(const ENUM_GM_EDP_DEPLOY d)
  {
   switch(d)
     {
      case GM_EDP_DEP_PREPARING:      return "Preparing";
      case GM_EDP_DEP_VALIDATING:     return "Validating";
      case GM_EDP_DEP_PROMOTING:      return "Promoting";
      case GM_EDP_DEP_OK:             return "Deployed";
      case GM_EDP_DEP_FAILED:         return "Failed";
      case GM_EDP_DEP_ROLLBACK_READY: return "Rollback Ready";
     }
   return "Idle";
  }

#endif // GM_DEPLOYMENT_CONSTANTS_MQH
//+------------------------------------------------------------------+
