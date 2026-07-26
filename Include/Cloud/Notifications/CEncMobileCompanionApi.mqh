//+------------------------------------------------------------------+
//|                                  CEncMobileCompanionApi.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Read-only Mobile Companion API — ARCHITECTURE ONLY          |
//+------------------------------------------------------------------+
#ifndef GM_CENC_MOBILE_COMPANION_API_MQH
#define GM_CENC_MOBILE_COMPANION_API_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "NotificationCenterConstants.mqh"
#include "CEncNotificationSecurity.mqh"
#include "SGmNotificationCenterResult.mqh"
#include "../SGmCloudStatus.mqh"
#include "../RemoteMonitor/SGmRemoteMonitorResult.mqh"

/// @brief Catalog of secure read-only endpoints. No mobile app in Sprint 3.
class CGmEncMobileCompanionApi
  {
private:
   CGmEncNotificationSecurity *m_sec;
   string                      m_token_hash;
   string                      m_last_request;
   bool                        m_ready;

public:
                     CGmEncMobileCompanionApi(void)
                       : m_sec(NULL), m_token_hash(""), m_last_request(""), m_ready(false) {}

   bool Init(CGmEncNotificationSecurity *sec, const string device_id)
     {
      m_sec = sec;
      m_token_hash = (m_sec != NULL) ? m_sec.ApiTokenHash(device_id) : "";
      m_ready = true;
      return true;
     }

   string ConnectionStatus(void) const
     {
      return m_ready ? "REST Catalog Ready (read-only)" : "Offline";
     }

   string Catalog(void) const
     {
      return "GET /v1/account/status | "
             "GET /v1/ai/status | "
             "GET /v1/dashboard | "
             "GET /v1/trades/stats | "
             "GET /v1/daily/stats | "
             "GET /v1/performance | "
             "GET /v1/health | "
             "GET /v1/cloud/status | "
             "GET /v1/notifications/feed";
     }

   /// Simulate a read-only API request (architecture exercise)
   string HandleReadOnly(const string endpoint,
                         const SGmNotificationCenterResult &ntf,
                         const SGmCloudStatus &cloud,
                         const SGmRemoteMonitorResult &rm)
     {
      if(!m_ready)
         return "{\"error\":\"not_ready\"}";

      m_last_request = endpoint;
      string body = "";

      if(endpoint == "/v1/account/status")
         body = StringFormat("{\"balance_observe\":true,\"unread\":%d}", ntf.unread_count);
      else if(endpoint == "/v1/ai/status")
         body = StringFormat("{\"ai\":\"observe\",\"mode\":\"%s\"}", ntf.ai_notifications);
      else if(endpoint == "/v1/dashboard")
         body = StringFormat("{\"latest\":\"%s\",\"critical\":%d}", ntf.latest_alert, ntf.critical_count);
      else if(endpoint == "/v1/trades/stats")
         body = "{\"scope\":\"read-only\",\"authority\":\"none\"}";
      else if(endpoint == "/v1/daily/stats")
         body = "{\"scope\":\"read-only\"}";
      else if(endpoint == "/v1/performance")
         body = StringFormat("{\"delivered\":%d,\"failed\":%d}", ntf.delivered_count, ntf.failed_count);
      else if(endpoint == "/v1/health")
         body = StringFormat("{\"health\":%.0f}", rm.valid ? rm.overall_health_score : 0.0);
      else if(endpoint == "/v1/cloud/status")
         body = StringFormat("{\"cloud\":\"%s\",\"offline\":%s}",
                             cloud.valid ? GmCloudStatusName(cloud.cloud_status) : "n/a",
                             cloud.offline_mode ? "true" : "false");
      else if(endpoint == "/v1/notifications/feed")
         body = StringFormat("{\"feed\":\"%s\"}", ntf.notification_feed);
      else
         body = "{\"error\":\"unknown_endpoint\",\"hint\":\"read-only catalog only\"}";

      const string sig = (m_sec != NULL) ? m_sec.SignMessage(body) : "";
      return StringFormat("{\"ok\":true,\"signed\":\"%s\",\"token\":\"%s\",\"data\":%s}",
                          sig, m_token_hash, body);
     }

   string LastRequest(void) const { return m_last_request; }
  };

#endif // GM_CENC_MOBILE_COMPANION_API_MQH
//+------------------------------------------------------------------+
