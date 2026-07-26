//+------------------------------------------------------------------+
//|                                           CEapAuthEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEAP_AUTH_ENGINE_MQH
#define GM_CEAP_AUTH_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ApiGatewayConstants.mqh"
#include "CEapApiSecurity.mqh"

struct SGmEapClient
  {
   string            client_id;
   string            api_key_hash;
   string            jwt;
   ENUM_GM_EAP_ROLE  role;
   ENUM_GM_EAP_AUTH  auth_mode;
   datetime          token_exp;
   datetime          last_seen;
   int               requests;
   bool              connected;
   bool              valid;

   void Reset(void)
     {
      client_id = api_key_hash = jwt = "";
      role = GM_EAP_ROLE_PUBLIC;
      auth_mode = GM_EAP_AUTH_NONE;
      token_exp = last_seen = 0;
      requests = 0;
      connected = false;
      valid = false;
     }
  };

class CGmEapAuthEngine
  {
private:
   CGmEapApiSecurity *m_sec;
   SGmEapClient       m_clients[GM_EAP_CLIENT_MAX];
   int                m_n;
   int                m_auth_ok;
   int                m_auth_fail;
   int                m_rate_limit;
   int                m_rate_hits;
   bool               m_ready;

   int FindClient(const string client_id) const
     {
      for(int i = 0; i < m_n; i++)
         if(m_clients[i].client_id == client_id)
            return i;
      return -1;
     }

public:
                     CGmEapAuthEngine(void)
                       : m_sec(NULL), m_n(0), m_auth_ok(0), m_auth_fail(0),
                         m_rate_limit(GM_EAP_RATE_LIMIT_DEFAULT), m_rate_hits(0),
                         m_ready(false) {}

   bool Init(CGmEapApiSecurity *sec)
     {
      m_sec = sec;
      m_n = 0;
      m_auth_ok = m_auth_fail = m_rate_hits = 0;
      m_rate_limit = GM_EAP_RATE_LIMIT_DEFAULT;
      m_ready = true;
      return true;
     }

   int Connected(void) const
     {
      int c = 0;
      for(int i = 0; i < m_n; i++)
         if(m_clients[i].connected) c++;
      return c;
     }

   int AuthOk(void) const { return m_auth_ok; }
   int AuthFail(void) const { return m_auth_fail; }
   int RateHits(void) const { return m_rate_hits; }
   int RateLimit(void) const { return m_rate_limit; }

   bool RegisterClient(const string client_id, const ENUM_GM_EAP_ROLE role,
                       const string api_key_plain)
     {
      if(!m_ready || m_sec == NULL || StringLen(client_id) < 2)
         return false;
      int idx = FindClient(client_id);
      if(idx < 0)
        {
         if(m_n >= GM_EAP_CLIENT_MAX) return false;
         idx = m_n++;
         m_clients[idx].Reset();
         m_clients[idx].client_id = client_id;
        }
      m_clients[idx].role = role;
      m_clients[idx].auth_mode = GM_EAP_AUTH_API_KEY;
      m_clients[idx].api_key_hash = m_sec.HashKey(api_key_plain);
      m_clients[idx].token_exp = TimeCurrent() + 86400;
      m_clients[idx].jwt = m_sec.BuildJwt(client_id, role, m_clients[idx].token_exp);
      m_clients[idx].connected = true;
      m_clients[idx].last_seen = TimeCurrent();
      m_clients[idx].valid = true;
      return true;
     }

   bool Authenticate(const string client_id, const string api_key_or_jwt,
                     const ulong nonce)
     {
      if(!m_ready || m_sec == NULL)
        {
         m_auth_fail++;
         return false;
        }
      if(!m_sec.CheckReplay(nonce))
        {
         m_auth_fail++;
         return false;
        }

      const int idx = FindClient(client_id);
      if(idx < 0)
        {
         m_auth_fail++;
         return false;
        }

      const bool key_ok = (m_clients[idx].api_key_hash == m_sec.HashKey(api_key_or_jwt));
      const bool jwt_ok = (api_key_or_jwt == m_clients[idx].jwt &&
                           m_sec.ValidateJwtShape(api_key_or_jwt));
      if(!key_ok && !jwt_ok)
        {
         m_auth_fail++;
         m_clients[idx].connected = false;
         return false;
        }

      if(m_clients[idx].token_exp > 0 && TimeCurrent() > m_clients[idx].token_exp)
        {
         m_clients[idx].token_exp = TimeCurrent() + 86400;
         m_clients[idx].jwt = m_sec.BuildJwt(client_id, m_clients[idx].role,
                                             m_clients[idx].token_exp);
        }

      if(m_clients[idx].requests >= m_rate_limit)
        {
         m_rate_hits++;
         m_auth_fail++;
         return false;
        }

      m_clients[idx].requests++;
      m_clients[idx].connected = true;
      m_clients[idx].last_seen = TimeCurrent();
      m_clients[idx].auth_mode = key_ok ? GM_EAP_AUTH_API_KEY : GM_EAP_AUTH_JWT;
      m_auth_ok++;
      return true;
     }

   void Disconnect(const string client_id)
     {
      const int idx = FindClient(client_id);
      if(idx >= 0)
         m_clients[idx].connected = false;
     }

   string StatusSummary(void) const
     {
      return StringFormat("OK=%d Fail=%d | Connected=%d | RateLimit=%d/min hits=%d",
                          m_auth_ok, m_auth_fail, Connected(), m_rate_limit, m_rate_hits);
     }

   string ClientList(void) const
     {
      string out = "";
      for(int i = 0; i < m_n; i++)
        {
         if(StringLen(out) > 0) out += " | ";
         out += m_clients[i].client_id + "=" +
                (m_clients[i].connected ? "up" : "down");
        }
      return out;
     }
  };

#endif // GM_CEAP_AUTH_ENGINE_MQH
//+------------------------------------------------------------------+
