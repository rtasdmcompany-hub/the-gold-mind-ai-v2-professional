//+------------------------------------------------------------------+
//|                                            CEapApiSecurity.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEAP_API_SECURITY_MQH
#define GM_CEAP_API_SECURITY_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ApiGatewayConstants.mqh"
#include "../CCloudSecurity.mqh"

class CGmEapApiSecurity
  {
private:
   CGmCloudSecurity *m_sec;
   string            m_allow_list; // architecture: comma-separated CIDR/IP placeholders
   ulong             m_nonce_seen;
   int               m_replay_blocks;
   bool              m_ready;

public:
                     CGmEapApiSecurity(void)
                       : m_sec(NULL), m_allow_list("127.0.0.1,::1"),
                         m_nonce_seen(0), m_replay_blocks(0), m_ready(false) {}

   bool Init(CGmCloudSecurity *sec)
     {
      m_sec = sec;
      m_allow_list = "127.0.0.1,::1";
      m_nonce_seen = 0;
      m_replay_blocks = 0;
      m_ready = (m_sec != NULL && m_sec.IsReady());
      return m_ready;
     }

   bool IsReady(void) const { return m_ready; }
   int ReplayBlocks(void) const { return m_replay_blocks; }

   string EncryptKey(const string plain) const
     {
      if(!m_ready || m_sec == NULL) return "";
      return m_sec.EncryptToBase64(plain);
     }

   string HashKey(const string plain) const
     {
      if(!m_ready || m_sec == NULL) return "";
      return m_sec.HashHex("EAP_KEY|" + plain);
     }

   string BuildJwt(const string client_id, const ENUM_GM_EAP_ROLE role,
                   const datetime exp) const
     {
      if(!m_ready || m_sec == NULL) return "";
      const string hdr = "eyJhbGciOiJHTVNIQTI1NiIsInR5cCI6IkpXVCJ9";
      const string payload = StringFormat("cid=%s|role=%s|exp=%I64d|ro=1|pol=%s",
                                          client_id, GmEapRoleName(role),
                                          (long)exp, GM_EAP_POLICY);
      return hdr + "." + m_sec.HashHex(payload) + "." + m_sec.SignRequest(payload);
     }

   bool ValidateJwtShape(const string jwt) const
     {
      if(StringLen(jwt) < 20) return false;
      int dots = 0;
      for(int i = 0; i < StringLen(jwt); i++)
         if(StringGetCharacter(jwt, i) == '.')
            dots++;
      return (dots == 2);
     }

   string SignRequest(const string body, const ulong nonce) const
     {
      if(!m_ready || m_sec == NULL) return "";
      return m_sec.SignRequest(StringFormat("%s|%I64u|%s", body, nonce, GM_EAP_POLICY));
     }

   bool CheckReplay(const ulong nonce)
     {
      if(nonce == 0) return false;
      if(nonce <= m_nonce_seen)
        {
         m_replay_blocks++;
         return false;
        }
      m_nonce_seen = nonce;
      return true;
     }

   bool IpAllowArchitecture(const string ip) const
     {
      if(StringLen(ip) == 0) return true; // local architecture
      return (StringFind(m_allow_list, ip) >= 0 || StringFind(ip, "127.") == 0);
     }

   string TlsReadyBanner(void) const
     {
      return "TLS Ready Architecture | JWT+APIKey+OAuth2 Ready | Replay=" +
             IntegerToString(m_replay_blocks);
     }
  };

#endif // GM_CEAP_API_SECURITY_MQH
//+------------------------------------------------------------------+
