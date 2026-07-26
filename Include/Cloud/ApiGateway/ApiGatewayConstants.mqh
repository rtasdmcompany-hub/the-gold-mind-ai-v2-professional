//+------------------------------------------------------------------+
//|                                      ApiGatewayConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 6 Sprint 8 — API Gateway / Integration / Developer    |
//|     READ-ONLY DATA ACCESS — NEVER executes trades               |
//+------------------------------------------------------------------+
#ifndef GM_API_GATEWAY_CONSTANTS_MQH
#define GM_API_GATEWAY_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_EAP_VERSION              "1.0.0-enterprise-api"
#define GM_EAP_DB_PREFIX            "GM_CLOUD_EAP_"
#define GM_EAP_THROTTLE_MS          16000
#define GM_EAP_CLIENT_MAX           12
#define GM_EAP_HIST_MAX             48
#define GM_EAP_RATE_LIMIT_DEFAULT   120
#define GM_EAP_API_VERSION          "v1"
#define GM_EAP_POLICY               "API READ-ONLY — NO TRADING AUTHORITY"
#define GM_EAP_SAFE                 "ASYNC GATEWAY — TRADING NEVER INTERRUPTED"

enum ENUM_GM_EAP_SURFACE
  {
   GM_EAP_SURFACE_REST = 0,
   GM_EAP_SURFACE_WEBSOCKET,
   GM_EAP_SURFACE_INTERNAL,
   GM_EAP_SURFACE_CLOUD,
   GM_EAP_SURFACE_PUBLIC_RO,
   GM_EAP_SURFACE_PRIVATE,
   GM_EAP_SURFACE_GRAPHQL_READY
  };

enum ENUM_GM_EAP_ROLE
  {
   GM_EAP_ROLE_PUBLIC = 0,
   GM_EAP_ROLE_APP,
   GM_EAP_ROLE_INTEGRATOR,
   GM_EAP_ROLE_ADMIN
  };

enum ENUM_GM_EAP_AUTH
  {
   GM_EAP_AUTH_NONE = 0,
   GM_EAP_AUTH_API_KEY,
   GM_EAP_AUTH_JWT,
   GM_EAP_AUTH_OAUTH_READY,
   GM_EAP_AUTH_DEVICE
  };

string GmEapSurfaceName(const ENUM_GM_EAP_SURFACE s)
  {
   switch(s)
     {
      case GM_EAP_SURFACE_REST:          return "REST";
      case GM_EAP_SURFACE_WEBSOCKET:     return "WebSocket";
      case GM_EAP_SURFACE_INTERNAL:      return "Internal";
      case GM_EAP_SURFACE_CLOUD:         return "Cloud";
      case GM_EAP_SURFACE_PUBLIC_RO:     return "Public Read-Only";
      case GM_EAP_SURFACE_PRIVATE:       return "Private";
      case GM_EAP_SURFACE_GRAPHQL_READY: return "GraphQL Ready";
     }
   return "REST";
  }

string GmEapRoleName(const ENUM_GM_EAP_ROLE r)
  {
   switch(r)
     {
      case GM_EAP_ROLE_APP:         return "App";
      case GM_EAP_ROLE_INTEGRATOR:  return "Integrator";
      case GM_EAP_ROLE_ADMIN:       return "Admin";
     }
   return "Public";
  }

string GmEapAuthName(const ENUM_GM_EAP_AUTH a)
  {
   switch(a)
     {
      case GM_EAP_AUTH_API_KEY:     return "API Key";
      case GM_EAP_AUTH_JWT:         return "JWT";
      case GM_EAP_AUTH_OAUTH_READY: return "OAuth 2.0 Ready";
      case GM_EAP_AUTH_DEVICE:      return "Device";
     }
   return "None";
  }

#endif // GM_API_GATEWAY_CONSTANTS_MQH
//+------------------------------------------------------------------+
