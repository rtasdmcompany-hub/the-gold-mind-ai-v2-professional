//+------------------------------------------------------------------+
//|                                            CEapApiGateway.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEAP_API_GATEWAY_MQH
#define GM_CEAP_API_GATEWAY_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ApiGatewayConstants.mqh"
#include "SGmApiGatewayResult.mqh"
#include "CEapAuthEngine.mqh"
#include "CEapDataServices.mqh"
#include "CEapIntegrationHub.mqh"
#include "../SGmCloudStatus.mqh"
#include "../RemoteMonitor/SGmRemoteMonitorResult.mqh"
#include "../Notifications/SGmNotificationCenterResult.mqh"
#include "../Identity/SGmIdentityResult.mqh"
#include "../Backup/SGmBackupResult.mqh"
#include "../Audit/SGmAuditResult.mqh"

class CGmEapApiGateway
  {
private:
   CGmEapAuthEngine      *m_auth;
   CGmEapDataServices    *m_data;
   CGmEapIntegrationHub  *m_hub;
   string                 m_cache;
   int                    m_queue_depth;
   bool                   m_ready;

public:
                     CGmEapApiGateway(void)
                       : m_auth(NULL), m_data(NULL), m_hub(NULL),
                         m_cache(""), m_queue_depth(0), m_ready(false) {}

   bool Init(CGmEapAuthEngine *auth, CGmEapDataServices *data, CGmEapIntegrationHub *hub)
     {
      m_auth = auth;
      m_data = data;
      m_hub = hub;
      m_ready = (m_auth != NULL && m_data != NULL && m_hub != NULL);
      return m_ready;
     }

   // Process one queued read-only request (CPU budget)
   bool ProcessOne(const string client_id,
                   const string credential,
                   const string endpoint,
                   const SGmCloudStatus &cloud,
                   const SGmRemoteMonitorResult &rm,
                   const SGmNotificationCenterResult &ntf,
                   const SGmIdentityResult &id,
                   const SGmBackupResult &bdr,
                   const SGmAuditResult &audit,
                   SGmApiGatewayResult &out)
     {
      if(!m_ready) return false;
      m_queue_depth = 1;

      const ulong nonce = (ulong)TimeCurrent() + (ulong)m_data.Served() + 1;
      if(!m_auth.Authenticate(client_id, credential, nonce))
        {
         out.auth_status = "Authentication Failed";
         m_queue_depth = 0;
         return false;
        }

      out.auth_status = "Authentication Successful";
      const string resp = m_data.Handle(endpoint, cloud, rm, ntf, id, bdr, audit);
      m_cache = resp; // simple response cache of last payload
      out.last_request = endpoint;
      out.request_count = m_data.Served();

      if(m_hub != NULL)
         m_hub.DeliverWebhook("cloud.reporting",
                              IntegerToString(StringLen(resp)));

      m_queue_depth = 0;
      return true;
     }

   void ApplyHealth(SGmApiGatewayResult &out) const
     {
      if(!m_ready) return;
      out.api_version = GM_EAP_API_VERSION;
      out.connected_clients = m_auth.Connected();
      out.auth_ok = m_auth.AuthOk();
      out.auth_fail = m_auth.AuthFail();
      out.rate_limit_hits = m_auth.RateHits();
      out.rate_limit_status = StringFormat("%d/window hits=%d",
                                           m_auth.RateLimit(), m_auth.RateHits());
      out.webhook_delivered = m_hub.WebhookDelivered();
      out.webhook_status = m_hub.WebhookStatus();
      out.endpoint_catalog = m_data.Catalog();
      out.integration_catalog = m_hub.Catalog();
      out.integration_health = m_hub.IntegrationHealth(out.connected_clients, out.auth_fail);

      out.api_availability = (out.auth_fail > out.auth_ok + 10) ? 55.0 : 95.0;
      out.api_health = (out.api_availability + out.integration_health +
                        (out.rate_limit_hits > 5 ? 60.0 : 90.0)) / 3.0;
      out.api_status = StringFormat("REST+WS+Internal+Cloud+PublicRO+Private+GQL | Clients=%d",
                                    out.connected_clients);
      if(StringLen(out.auth_status) == 0)
         out.auth_status = m_auth.StatusSummary();
     }
  };

#endif // GM_CEAP_API_GATEWAY_MQH
//+------------------------------------------------------------------+
