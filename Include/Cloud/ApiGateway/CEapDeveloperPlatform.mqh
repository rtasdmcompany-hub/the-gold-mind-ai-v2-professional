//+------------------------------------------------------------------+
//|                                    CEapDeveloperPlatform.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEAP_DEVELOPER_PLATFORM_MQH
#define GM_CEAP_DEVELOPER_PLATFORM_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ApiGatewayConstants.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Core/Version.mqh"

class CGmEapDeveloperPlatform
  {
private:
   CGmFileManager *m_files;
   string          m_pfx;
   bool            m_ready;

public:
                     CGmEapDeveloperPlatform(void)
                       : m_files(NULL), m_pfx(""), m_ready(false) {}

   bool Init(CGmFileManager *files, const string pfx)
     {
      m_files = files;
      m_pfx = pfx;
      m_ready = true;
      PublishDocs();
      return true;
     }

   string Status(void) const
     {
      return "Developer Platform Ready | API " + GM_EAP_API_VERSION +
             " | SDK Structure Published";
     }

   void PublishDocs(void)
     {
      if(!m_ready || m_files == NULL) return;

      string doc = "=== GoldMind Enterprise API Documentation ===\r\n";
      doc += "Version: " + GM_EAP_API_VERSION + " | Build " + IntegerToString(GM_VERSION_BUILD) + "\r\n";
      doc += "Policy: " + GM_EAP_POLICY + "\r\n\r\n";
      doc += "## Surfaces\r\nREST | WebSocket | Internal | Cloud | Public RO | Private | GraphQL Ready\r\n\r\n";
      doc += "## Authentication Guide\r\n";
      doc += "- API Keys (hashed at rest)\r\n- JWT sessions\r\n- OAuth 2.0 Ready\r\n";
      doc += "- Device authentication\r\n- Token refresh\r\n\r\n";
      doc += "## Rate Limits\r\nDefault " + IntegerToString(GM_EAP_RATE_LIMIT_DEFAULT) + " requests / window\r\n\r\n";
      doc += "## Error Codes\r\n";
      doc += "400 bad_request | 401 unauthorized | 403 forbidden | 404 not_found | ";
      doc += "429 rate_limited | 500 internal | E-TRADE-DENIED (trade control blocked)\r\n\r\n";
      doc += "## Webhooks\r\nOutbound event notifications only. Never accept trade-control callbacks.\r\n\r\n";
      doc += "## SDK Structure\r\n";
      doc += "sdk/csharp | sdk/python | sdk/js | examples/readonly_client\r\n\r\n";
      doc += "## Integration Examples\r\n";
      doc += "GET /v1/health with Authorization: Bearer <jwt>\r\n";
      m_files.WriteText(m_pfx + "api_documentation.txt", doc);

      string explorer = "=== Endpoint Explorer ===\r\n";
      explorer += "GET /v1/dashboard/stats\r\nGET /v1/ai/analysis\r\nGET /v1/trades/stats\r\n";
      explorer += "GET /v1/performance\r\nGET /v1/health\r\nGET /v1/license\r\n";
      explorer += "GET /v1/cloud/status\r\nGET /v1/audit/reports\r\n";
      explorer += "GET /v1/notifications/history\r\nGET /v1/recovery/stats\r\n";
      explorer += "GET /v1/reports/historical\r\n";
      m_files.WriteText(m_pfx + "endpoint_explorer.txt", explorer);

      m_files.WriteText(m_pfx + "version_management.txt",
                        "API Version=" + GM_EAP_API_VERSION + "\r\nCompatible Builds>=21040\r\n");
     }
  };

#endif // GM_CEAP_DEVELOPER_PLATFORM_MQH
//+------------------------------------------------------------------+
