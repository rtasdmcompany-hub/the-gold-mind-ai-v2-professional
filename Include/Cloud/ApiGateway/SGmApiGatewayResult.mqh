//+------------------------------------------------------------------+
//|                                      SGmApiGatewayResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_API_GATEWAY_RESULT_MQH
#define GM_SGM_API_GATEWAY_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ApiGatewayConstants.mqh"

struct SGmApiGatewayResult
  {
   datetime   stamped_at;
   string     api_version;
   string     api_status;
   double     api_health;
   double     api_availability;
   double     integration_health;
   int        connected_clients;
   int        request_count;
   int        auth_ok;
   int        auth_fail;
   int        rate_limit_hits;
   int        webhook_delivered;
   string     auth_status;
   string     rate_limit_status;
   string     webhook_status;
   string     developer_status;
   string     endpoint_catalog;
   string     integration_catalog;
   string     last_request;
   string     center_status;
   string     insight;
   bool       may_execute;
   bool       may_modify_risk;
   bool       may_interrupt_trading;
   bool       valid;

   void Reset(void)
     {
      stamped_at = 0;
      api_version = GM_EAP_API_VERSION;
      api_status = "";
      api_health = api_availability = integration_health = 0.0;
      connected_clients = request_count = 0;
      auth_ok = auth_fail = rate_limit_hits = webhook_delivered = 0;
      auth_status = rate_limit_status = webhook_status = "";
      developer_status = endpoint_catalog = integration_catalog = "";
      last_request = center_status = insight = "";
      may_execute = false;
      may_modify_risk = false;
      may_interrupt_trading = false;
      valid = false;
     }
  };

#endif // GM_SGM_API_GATEWAY_RESULT_MQH
//+------------------------------------------------------------------+
