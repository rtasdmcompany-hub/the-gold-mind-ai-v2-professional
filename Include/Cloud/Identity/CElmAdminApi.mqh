//+------------------------------------------------------------------+
//|                                          CElmAdminApi.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     License Administration API — ARCHITECTURE ONLY              |
//|     No payment processing                                       |
//+------------------------------------------------------------------+
#ifndef GM_CELM_ADMIN_API_MQH
#define GM_CELM_ADMIN_API_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "IdentityConstants.mqh"
#include "SGmIdentityResult.mqh"
#include "CElmIdentitySecurity.mqh"
#include "CElmLicenseEngine.mqh"

class CGmElmAdminApi
  {
private:
   CGmElmIdentitySecurity *m_sec;
   string                  m_last_op;
   bool                    m_ready;

public:
                     CGmElmAdminApi(void)
                       : m_sec(NULL), m_last_op(""), m_ready(false) {}

   bool Init(CGmElmIdentitySecurity *sec)
     {
      m_sec = sec;
      m_ready = true;
      return true;
     }

   string Catalog(void) const
     {
      return "POST /v1/licenses/create | "
             "POST /v1/licenses/activate | "
             "POST /v1/licenses/deactivate | "
             "POST /v1/licenses/suspend | "
             "POST /v1/licenses/renew | "
             "POST /v1/licenses/upgrade | "
             "POST /v1/licenses/transfer | "
             "GET  /v1/licenses/status";
     }

   string Handle(const string endpoint, CGmElmLicenseEngine &lic,
                 const SGmIdentityResult &snap)
     {
      if(!m_ready)
         return "{\"error\":\"not_ready\"}";

      m_last_op = endpoint;
      string data = "";

      if(endpoint == "/v1/licenses/create")
         data = "{\"created\":true,\"payment\":\"none\",\"architecture\":true}";
      else if(endpoint == "/v1/licenses/activate")
         data = StringFormat("{\"activated\":true,\"type\":\"%s\"}",
                             GmElmLicenseTypeName(lic.Type()));
      else if(endpoint == "/v1/licenses/deactivate")
         data = "{\"deactivated\":true,\"trading_interrupted\":false}";
      else if(endpoint == "/v1/licenses/suspend")
         data = "{\"suspended\":true,\"architecture_only\":true}";
      else if(endpoint == "/v1/licenses/renew")
         data = StringFormat("{\"renewed\":true,\"expires\":\"%s\"}",
                             TimeToString(lic.Expires(), TIME_DATE));
      else if(endpoint == "/v1/licenses/upgrade")
         data = "{\"upgraded\":true,\"target\":\"Enterprise\"}";
      else if(endpoint == "/v1/licenses/transfer")
         data = "{\"transfer\":\"queued\",\"architecture\":true}";
      else if(endpoint == "/v1/licenses/status")
         data = StringFormat("{\"status\":\"%s\",\"health\":%.0f,\"remaining\":%d,\"grace\":%s}",
                             snap.license_status, snap.license_health, snap.remaining_days,
                             snap.in_grace_period ? "true" : "false");
      else
         data = "{\"error\":\"unknown\",\"hint\":\"admin catalog only — no payments\"}";

      const string sig = (m_sec != NULL) ? m_sec.HashHex(data) : "";
      return StringFormat("{\"ok\":true,\"sig\":\"%s\",\"data\":%s}", sig, data);
     }

   string LastOp(void) const { return m_last_op; }
  };

#endif // GM_CELM_ADMIN_API_MQH
//+------------------------------------------------------------------+
