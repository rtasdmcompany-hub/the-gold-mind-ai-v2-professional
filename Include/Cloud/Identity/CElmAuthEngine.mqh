//+------------------------------------------------------------------+
//|                                         CElmAuthEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CELM_AUTH_ENGINE_MQH
#define GM_CELM_AUTH_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "IdentityConstants.mqh"
#include "SGmIdentityResult.mqh"
#include "CElmIdentitySecurity.mqh"

class CGmElmAuthEngine
  {
private:
   CGmElmIdentitySecurity *m_sec;
   ENUM_GM_ELM_AUTH_STATE  m_state;
   ENUM_GM_ELM_ROLE        m_role;
   string                  m_user_hash;
   string                  m_cred_enc;
   string                  m_jwt;
   datetime                m_session_exp;
   int                     m_fail_count;
   bool                    m_ready;

public:
                     CGmElmAuthEngine(void)
                       : m_sec(NULL), m_state(GM_ELM_AUTH_ANONYMOUS),
                         m_role(GM_ELM_ROLE_VIEWER), m_user_hash(""),
                         m_cred_enc(""), m_jwt(""), m_session_exp(0),
                         m_fail_count(0), m_ready(false) {}

   bool Init(CGmElmIdentitySecurity *sec)
     {
      m_sec = sec;
      m_state = GM_ELM_AUTH_ANONYMOUS;
      m_role = GM_ELM_ROLE_ENTERPRISE;
      m_fail_count = 0;
      m_ready = true;
      return true;
     }

   ENUM_GM_ELM_AUTH_STATE State(void) const { return m_state; }
   ENUM_GM_ELM_ROLE Role(void) const { return m_role; }
   string UserHash(void) const { return m_user_hash; }
   string Jwt(void) const { return m_jwt; }
   int FailCount(void) const { return m_fail_count; }

   // Architecture login — local secure token, no remote password store
   bool Login(const string username, const string password_or_token,
              const string device_fp)
     {
      if(!m_ready || m_sec == NULL) return false;
      if(StringLen(username) < 2 || StringLen(password_or_token) < 4)
        {
         m_fail_count++;
         m_state = GM_ELM_AUTH_FAILED;
         return false;
        }

      m_user_hash = m_sec.HashHex("USER|" + username);
      m_cred_enc = m_sec.EncryptCredential(password_or_token);
      m_role = GM_ELM_ROLE_ENTERPRISE;
      m_session_exp = TimeCurrent() + GM_ELM_SESSION_TIMEOUT_SEC;
      m_jwt = m_sec.BuildJwtSession(m_user_hash, device_fp, m_role, m_session_exp);
      if(!m_sec.ValidateJwtShape(m_jwt))
        {
         m_fail_count++;
         m_state = GM_ELM_AUTH_FAILED;
         return false;
        }
      m_state = GM_ELM_AUTH_AUTHENTICATED;
      return true;
     }

   void Logout(void)
     {
      m_jwt = "";
      m_session_exp = 0;
      m_state = GM_ELM_AUTH_ANONYMOUS;
     }

   void RefreshSession(const string device_fp)
     {
      if(!m_ready || m_sec == NULL || StringLen(m_user_hash) == 0) return;
      if(m_session_exp > 0 && TimeCurrent() > m_session_exp)
        {
         m_state = GM_ELM_AUTH_SESSION_EXPIRED;
         return;
        }
      m_session_exp = TimeCurrent() + GM_ELM_SESSION_TIMEOUT_SEC;
      m_jwt = m_sec.BuildJwtSession(m_user_hash, device_fp, m_role, m_session_exp);
      m_state = GM_ELM_AUTH_AUTHENTICATED;
     }

   // Framework stubs
   string PasswordResetFramework(void) const
     {
      return "POST /v1/auth/password-reset (architecture)";
     }

   void ApplyTo(SGmIdentityResult &out) const
     {
      if(!m_ready) return;
      out.auth_state = m_state;
      out.role = m_role;
      out.user_id_hash = m_user_hash;
      out.user_profile = StringFormat("role=%s | uid=%s",
                                      GmElmRoleName(m_role),
                                      StringLen(m_user_hash) > 8
                                      ? StringSubstr(m_user_hash, 0, 8) : "n/a");
      out.session_token_jwt = m_jwt;
      out.session_status = (m_state == GM_ELM_AUTH_AUTHENTICATED)
                           ? StringFormat("Active until %s",
                                          TimeToString(m_session_exp, TIME_DATE | TIME_MINUTES))
                           : GmElmAuthStateName(m_state);
      out.auth_status = GmElmAuthStateName(m_state);
      out.two_factor_architecture = true;
      out.sso_ready = true;
     }
  };

#endif // GM_CELM_AUTH_ENGINE_MQH
//+------------------------------------------------------------------+
