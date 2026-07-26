//+------------------------------------------------------------------+
//|                                     CElmIdentityDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CELM_IDENTITY_DATABASE_MQH
#define GM_CELM_IDENTITY_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "IdentityConstants.mqh"
#include "SGmIdentityResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmElmIdentityDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_hist[GM_ELM_HIST_MAX];
   int             m_n;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL) return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmElmIdentityDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_n(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_ELM_DB_PREFIX, magic, sym);
      m_n = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Identity Database Ready | " + m_pfx, "ELM");
      return true;
     }

   void Shutdown(void)
     {
      Persist();
      m_ready = false;
     }

   void Persist(void)
     {
      if(!m_ready || m_files == NULL) return;
      string body = "=== license_history ===\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_hist[i] + "\r\n";
      m_files.WriteText(m_pfx + "license_history.txt", body);
     }

   void Record(const SGmIdentityResult &r, const string audit)
     {
      if(!m_ready || !r.valid) return;
      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s\r\n", ts);

      WriteTable("users",
                 "=== users ===\r\n" + head +
                 "User=" + r.user_profile + "\r\n" +
                 "Role=" + GmElmRoleName(r.role) + "\r\n");

      WriteTable("licenses",
                 "=== licenses ===\r\n" + head +
                 "Type=" + GmElmLicenseTypeName(r.license_type) + "\r\n" +
                 "Status=" + r.license_status + "\r\n" +
                 "KeyHash=" + r.license_key_hash + "\r\n" +
                 "Health=" + DoubleToString(r.license_health, 1) + "\r\n" +
                 "Activated=" + TimeToString(r.activation_date, TIME_DATE) + "\r\n" +
                 "Expires=" + TimeToString(r.expiration_date, TIME_DATE) + "\r\n" +
                 "Remaining=" + IntegerToString(r.remaining_days) + "\r\n");

      WriteTable("devices",
                 "=== devices ===\r\n" + head +
                 "Current=" + r.current_device + "\r\n" +
                 "Activated=" + IntegerToString(r.activated_devices) + "/" +
                 IntegerToString(r.max_devices) + "\r\n" +
                 "Summary=" + r.device_manager_summary + "\r\n");

      WriteTable("sessions",
                 "=== sessions ===\r\n" + head +
                 "Auth=" + r.auth_status + "\r\n" +
                 "Session=" + r.session_status + "\r\n" +
                 "JWT_len=" + IntegerToString(StringLen(r.session_token_jwt)) + "\r\n");

      WriteTable("activation_history",
                 "=== activation_history ===\r\n" + head +
                 r.activation_history + "\r\n");

      WriteTable("authentication_logs",
                 "=== authentication_logs ===\r\n" + head +
                 "State=" + GmElmAuthStateName(r.auth_state) + "\r\n" +
                 "Security=" + r.security_status + "\r\n");

      WriteTable("grace_period_history",
                 "=== grace_period_history ===\r\n" + head +
                 "Grace=" + r.grace_period_status + "\r\n" +
                 "InGrace=" + (r.in_grace_period ? "yes" : "no") + "\r\n" +
                 "TradingAllowed=" + (r.trading_allowed_by_grace ? "yes" : "yes") + "\r\n");

      WriteTable("audit_trail",
                 "=== audit_trail ===\r\n" + head + audit + "\r\n" +
                 "POLICY=" + GM_ELM_POLICY + "\r\n" +
                 "SAFE=" + GM_ELM_SAFE + "\r\n");

      const string line = StringFormat("%s | %s | health=%.0f | auth=%s | devices=%d",
                                       ts, r.license_status, r.license_health,
                                       r.auth_status, r.activated_devices);
      if(m_n < GM_ELM_HIST_MAX)
         m_hist[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_ELM_HIST_MAX; i++)
            m_hist[i - 1] = m_hist[i];
         m_hist[GM_ELM_HIST_MAX - 1] = line;
        }
     }
  };

#endif // GM_CELM_IDENTITY_DATABASE_MQH
//+------------------------------------------------------------------+
