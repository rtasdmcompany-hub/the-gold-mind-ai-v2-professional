//+------------------------------------------------------------------+
//|                                         CEapDataServices.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Read-only endpoints — NEVER execute or modify trades        |
//+------------------------------------------------------------------+
#ifndef GM_CEAP_DATA_SERVICES_MQH
#define GM_CEAP_DATA_SERVICES_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ApiGatewayConstants.mqh"
#include "CEapApiSecurity.mqh"
#include "../SGmCloudStatus.mqh"
#include "../RemoteMonitor/SGmRemoteMonitorResult.mqh"
#include "../Notifications/SGmNotificationCenterResult.mqh"
#include "../Identity/SGmIdentityResult.mqh"
#include "../Backup/SGmBackupResult.mqh"
#include "../Audit/SGmAuditResult.mqh"

class CGmEapDataServices
  {
private:
   CGmEapApiSecurity *m_sec;
   string             m_last_endpoint;
   string             m_last_response;
   int                m_served;
   bool               m_ready;

public:
                     CGmEapDataServices(void)
                       : m_sec(NULL), m_last_endpoint(""), m_last_response(""),
                         m_served(0), m_ready(false) {}

   bool Init(CGmEapApiSecurity *sec)
     {
      m_sec = sec;
      m_ready = true;
      return true;
     }

   int Served(void) const { return m_served; }
   string LastEndpoint(void) const { return m_last_endpoint; }
   string LastResponse(void) const { return m_last_response; }

   string Catalog(void) const
     {
      return "GET /" + GM_EAP_API_VERSION + "/dashboard/stats | "
             "GET /" + GM_EAP_API_VERSION + "/ai/analysis | "
             "GET /" + GM_EAP_API_VERSION + "/trades/stats | "
             "GET /" + GM_EAP_API_VERSION + "/performance | "
             "GET /" + GM_EAP_API_VERSION + "/health | "
             "GET /" + GM_EAP_API_VERSION + "/license | "
             "GET /" + GM_EAP_API_VERSION + "/cloud/status | "
             "GET /" + GM_EAP_API_VERSION + "/audit/reports | "
             "GET /" + GM_EAP_API_VERSION + "/notifications/history | "
             "GET /" + GM_EAP_API_VERSION + "/recovery/stats | "
             "GET /" + GM_EAP_API_VERSION + "/reports/historical";
     }

   string Handle(const string endpoint,
                 const SGmCloudStatus &cloud,
                 const SGmRemoteMonitorResult &rm,
                 const SGmNotificationCenterResult &ntf,
                 const SGmIdentityResult &id,
                 const SGmBackupResult &bdr,
                 const SGmAuditResult &audit)
     {
      if(!m_ready)
         return "{\"error\":\"not_ready\",\"trade_control\":false}";

      m_last_endpoint = endpoint;
      string data = "";
      const string pfx = "/" + GM_EAP_API_VERSION;

      if(endpoint == pfx + "/dashboard/stats")
         data = StringFormat("{\"mode\":\"read-only\",\"health\":%.0f}",
                             rm.valid ? rm.overall_health_score : 0.0);
      else if(endpoint == pfx + "/ai/analysis")
         data = "{\"scope\":\"observe\",\"authority\":\"none\"}";
      else if(endpoint == pfx + "/trades/stats")
         data = "{\"scope\":\"statistics-only\",\"may_execute\":false}";
      else if(endpoint == pfx + "/performance")
         data = StringFormat("{\"bc\":%.0f,\"trust\":%.0f}",
                             bdr.valid ? bdr.business_continuity : 0.0,
                             audit.valid ? audit.trust_score : 0.0);
      else if(endpoint == pfx + "/health")
         data = StringFormat("{\"cpu\":%.0f,\"ram\":%.0f}",
                             rm.valid ? rm.cpu_usage_pct : 0.0,
                             rm.valid ? rm.ram_usage_pct : 0.0);
      else if(endpoint == pfx + "/license")
         data = StringFormat("{\"status\":\"%s\",\"health\":%.0f,\"interrupt\":false}",
                             id.valid ? id.license_status : "n/a",
                             id.valid ? id.license_health : 0.0);
      else if(endpoint == pfx + "/cloud/status")
         data = StringFormat("{\"cloud\":\"%s\",\"offline\":%s}",
                             cloud.valid ? GmCloudStatusName(cloud.cloud_status) : "n/a",
                             cloud.offline_mode ? "true" : "false");
      else if(endpoint == pfx + "/audit/reports")
         data = StringFormat("{\"trust\":%.0f,\"compliance\":%.0f}",
                             audit.valid ? audit.trust_score : 0.0,
                             audit.valid ? audit.compliance_score : 0.0);
      else if(endpoint == pfx + "/notifications/history")
         data = StringFormat("{\"unread\":%d,\"delivered\":%d}",
                             ntf.valid ? ntf.unread_count : 0,
                             ntf.valid ? ntf.delivered_count : 0);
      else if(endpoint == pfx + "/recovery/stats")
         data = StringFormat("{\"readiness\":%.0f,\"restore\":\"%s\"}",
                             bdr.valid ? bdr.recovery_readiness : 0.0,
                             bdr.valid ? bdr.restore_status : "n/a");
      else if(endpoint == pfx + "/reports/historical")
         data = "{\"export\":\"read-only\",\"payment\":false}";
      else
         data = "{\"error\":\"unknown_endpoint\",\"hint\":\"read-only catalog only\"}";

      const string body = StringFormat("{\"ok\":true,\"read_only\":true,\"may_execute\":false,\"data\":%s}",
                                       data);
      string sig = "";
      if(m_sec != NULL)
         sig = m_sec.SignRequest(body, (ulong)TimeCurrent());
      m_last_response = StringFormat("{\"signed\":\"%s\",\"body\":%s}", sig, body);
      m_served++;
      return m_last_response;
     }
  };

#endif // GM_CEAP_DATA_SERVICES_MQH
//+------------------------------------------------------------------+
