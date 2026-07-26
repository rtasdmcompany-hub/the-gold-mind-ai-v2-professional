//+------------------------------------------------------------------+
//|                                           CEapApiDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEAP_API_DATABASE_MQH
#define GM_CEAP_API_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ApiGatewayConstants.mqh"
#include "SGmApiGatewayResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmEapApiDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_hist[GM_EAP_HIST_MAX];
   int             m_n;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL) return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmEapApiDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_n(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_EAP_DB_PREFIX, magic, sym);
      m_n = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("API Database Ready | " + m_pfx, "EAP");
      return true;
     }

   string Prefix(void) const { return m_pfx; }

   void Shutdown(void)
     {
      Persist();
      m_ready = false;
     }

   void Persist(void)
     {
      if(!m_ready || m_files == NULL) return;
      string body = "=== integration_history ===\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_hist[i] + "\r\n";
      m_files.WriteText(m_pfx + "integration_history.txt", body);
     }

   void Record(const SGmApiGatewayResult &r,
               const string clients,
               const string keys_enc,
               const string audit)
     {
      if(!m_ready || !r.valid) return;
      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s\r\n", ts);

      WriteTable("api_clients",
                 "=== api_clients ===\r\n" + head + clients + "\r\n");

      WriteTable("api_keys",
                 "=== api_keys (encrypted) ===\r\n" + head + keys_enc + "\r\n");

      WriteTable("access_tokens",
                 "=== access_tokens ===\r\n" + head +
                 "Auth=" + r.auth_status + "\r\n");

      WriteTable("request_logs",
                 "=== request_logs ===\r\n" + head +
                 "Last=" + r.last_request + "\r\n" +
                 "Count=" + IntegerToString(r.request_count) + "\r\n");

      WriteTable("webhook_logs",
                 "=== webhook_logs ===\r\n" + head +
                 r.webhook_status + "\r\n");

      WriteTable("rate_limit_history",
                 "=== rate_limit_history ===\r\n" + head +
                 r.rate_limit_status + "\r\n" +
                 "Hits=" + IntegerToString(r.rate_limit_hits) + "\r\n");

      WriteTable("api_audit_trail",
                 "=== api_audit_trail ===\r\n" + head + audit + "\r\n" +
                 "POLICY=" + GM_EAP_POLICY + "\r\n");

      const string line = StringFormat("%s | health=%.0f | clients=%d | req=%d | %s",
                                       ts, r.api_health, r.connected_clients,
                                       r.request_count, r.api_status);
      if(m_n < GM_EAP_HIST_MAX)
         m_hist[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_EAP_HIST_MAX; i++)
            m_hist[i - 1] = m_hist[i];
         m_hist[GM_EAP_HIST_MAX - 1] = line;
        }
     }
  };

#endif // GM_CEAP_API_DATABASE_MQH
//+------------------------------------------------------------------+
