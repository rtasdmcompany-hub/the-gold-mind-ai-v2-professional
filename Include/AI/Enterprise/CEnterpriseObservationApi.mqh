//+------------------------------------------------------------------+
//|                             CEnterpriseObservationApi.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Read-only remote observation API foundation                 |
//+------------------------------------------------------------------+
#ifndef GM_CENTERPRISE_OBSERVATION_API_MQH
#define GM_CENTERPRISE_OBSERVATION_API_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmEnterpriseResult.mqh"

/// @brief Documents / emits read-only endpoint catalog. No execution routes.
class CGmEnterpriseObservationApi
  {
public:
   string EndpointCatalog(void) const
     {
      return "GET /api/enterprise/accounts | GET /api/enterprise/account-health | "
             "GET /api/enterprise/fleet-status | GET /api/enterprise/reports | "
             "EXECUTION_ENDPOINTS=NONE";
     }

   string AccountsJson(const SGmEnterpriseResult &r) const
     {
      return StringFormat("{\"accounts_monitored\":%d,\"healthy\":%d,\"warning\":%d,\"critical\":%d,\"local_id\":\"%s\"}",
                          r.accounts_monitored, r.healthy_accounts, r.warning_accounts,
                          r.critical_accounts, r.local_profile.account_id);
     }

   string FleetJson(const SGmEnterpriseResult &r) const
     {
      return StringFormat("{\"fleet_health\":%.1f,\"status\":\"%s\",\"alerts\":\"%s\",\"execution_enabled\":false}",
                          r.fleet_health_score, r.fleet_status, r.enterprise_alerts);
     }

   string AccountHealthJson(const SGmEnterpriseResult &r) const
     {
      return StringFormat("{\"local_health\":\"%s\",\"equity\":%.2f,\"dd_pct\":%.2f,\"rank\":\"%s\"}",
                          GmEntAcctHealthName(r.local_health), r.local_equity,
                          r.local_dd_pct, GmEntRankName(r.local_rank));
     }
  };

#endif // GM_CENTERPRISE_OBSERVATION_API_MQH
//+------------------------------------------------------------------+
