//+------------------------------------------------------------------+
//|                                     CEdpDeploymentEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEDP_DEPLOYMENT_ENGINE_MQH
#define GM_CEDP_DEPLOYMENT_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "DeploymentConstants.mqh"
#include "SGmDeploymentResult.mqh"
#include "CEdpReleaseManagement.mqh"

class CGmEdpDeploymentEngine
  {
private:
   CGmEdpReleaseManagement *m_rel;
   ENUM_GM_EDP_ENV          m_env;
   ENUM_GM_EDP_DEPLOY       m_status;
   bool                     m_ready;

public:
                     CGmEdpDeploymentEngine(void)
                       : m_rel(NULL), m_env(GM_EDP_ENV_PRODUCTION),
                         m_status(GM_EDP_DEP_IDLE), m_ready(false) {}

   bool Init(CGmEdpReleaseManagement *rel)
     {
      m_rel = rel;
      m_env = GM_EDP_ENV_PRODUCTION;
      m_status = GM_EDP_DEP_IDLE;
      m_ready = true;
      return true;
     }

   ENUM_GM_EDP_ENV Environment(void) const { return m_env; }
   ENUM_GM_EDP_DEPLOY Status(void) const { return m_status; }

   void Promote(const ENUM_GM_EDP_ENV target, const bool trades_clear)
     {
      if(!m_ready) return;
      m_status = GM_EDP_DEP_PREPARING;
      if(!trades_clear)
        {
         m_status = GM_EDP_DEP_ROLLBACK_READY; // cannot promote while trading
         return;
        }
      m_status = GM_EDP_DEP_VALIDATING;
      // Architecture promotion path: Dev→Test→Staging→Production
      if(target == GM_EDP_ENV_PRODUCTION && m_rel != NULL &&
         StringFind(m_rel.Approval(), "Approved") >= 0)
        {
         m_status = GM_EDP_DEP_PROMOTING;
         m_env = target;
         m_status = GM_EDP_DEP_OK;
        }
      else
        {
         m_env = target;
         m_status = GM_EDP_DEP_OK;
        }
     }

   void ApplyTo(SGmDeploymentResult &out) const
     {
      if(!m_ready) return;
      out.environment = m_env;
      out.deploy_status = m_status;
      out.deployment_status_text = GmEdpDeployName(m_status) + " | Env=" + GmEdpEnvName(m_env);
      out.deployment_health = (m_status == GM_EDP_DEP_OK) ? 92.0
                              : (m_status == GM_EDP_DEP_FAILED ? 30.0 : 70.0);
     }
  };

#endif // GM_CEDP_DEPLOYMENT_ENGINE_MQH
//+------------------------------------------------------------------+
