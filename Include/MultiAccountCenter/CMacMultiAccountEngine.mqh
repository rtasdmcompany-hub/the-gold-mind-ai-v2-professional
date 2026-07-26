//+------------------------------------------------------------------+
//|                                    CMacMultiAccountEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CMAC_MULTI_ACCOUNT_ENGINE_MQH
#define GM_CMAC_MULTI_ACCOUNT_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMultiAccountCenterResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmMacMultiAccountEngine
  {
private:
   CGmLogger *m_logger;
   long       m_login;
   string     m_broker;
   string     m_server;
   string     m_company;
   ENUM_GM_MAC_ACCT_TYPE m_type;
   ENUM_GM_MAC_CONN      m_conn;
   double     m_license_health;
   bool       m_licensed;
   double     m_health;

   double Clamp100(const double v) const
     {
      if(v < 0.0) return 0.0;
      if(v > 100.0) return 100.0;
      return v;
     }

public:
                     CGmMacMultiAccountEngine(void)
                       : m_logger(NULL), m_login(0), m_broker(""), m_server(""), m_company(""),
                         m_type(GM_MAC_AT_DEMO), m_conn(GM_MAC_CONN_OFFLINE),
                         m_license_health(0.0), m_licensed(false), m_health(0.0) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_login = 0;
      m_broker = m_server = m_company = "";
      m_type = GM_MAC_AT_DEMO;
      m_conn = GM_MAC_CONN_OFFLINE;
      m_license_health = 0.0;
      m_licensed = false;
      m_health = 0.0;
     }

   bool IsLicensed(void) const { return m_licensed; }
   double Health(void) const { return m_health; }

   void RegisterLocal(const double license_health)
     {
      m_login = AccountInfoInteger(ACCOUNT_LOGIN);
      m_company = AccountInfoString(ACCOUNT_COMPANY);
      m_server = AccountInfoString(ACCOUNT_SERVER);
      m_broker = m_company;
      m_type = ((ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_DEMO)
               ? GM_MAC_AT_DEMO : GM_MAC_AT_LIVE;
      m_license_health = license_health;
      m_licensed = (license_health >= GM_MAC_LICENSE_MIN_HEALTH);

      const long trade_allowed = AccountInfoInteger(ACCOUNT_TRADE_ALLOWED);
      if(!TerminalInfoInteger(TERMINAL_CONNECTED))
         m_conn = GM_MAC_CONN_OFFLINE;
      else if(trade_allowed == 0)
         m_conn = GM_MAC_CONN_WARNING;
      else
         m_conn = GM_MAC_CONN_CONNECTED;

      double h = 40.0;
      h += (m_licensed ? 30.0 : 0.0);
      h += (m_conn == GM_MAC_CONN_CONNECTED ? 20.0 : (m_conn == GM_MAC_CONN_WARNING ? 8.0 : 0.0));
      h += MathMin(10.0, m_license_health * 0.1);
      m_health = Clamp100(h);

      if(m_logger != NULL)
        {
         if(m_licensed)
            m_logger.Success(StringFormat("Account Registered | Login=%I64d | %s | Licensed",
                                          m_login, m_server), "MAC");
         else
            m_logger.Warning(StringFormat(
               "Account EXCLUDED | Login=%I64d | license health %.0f < %.0f — not in analytics",
               m_login, m_license_health, GM_MAC_LICENSE_MIN_HEALTH), "MAC");

         if(m_conn == GM_MAC_CONN_CONNECTED)
            m_logger.Info("Account Connected | " + m_server, "MAC");
         else if(m_conn == GM_MAC_CONN_OFFLINE)
            m_logger.Warning("Account Disconnected | terminal offline", "MAC");
        }
     }

   void ApplyToResult(SGmMultiAccountCenterResult &out) const
     {
      out.accounts_registered = 1;
      out.accounts_licensed = m_licensed ? 1 : 0;
      out.accounts_excluded_unlicensed = m_licensed ? 0 : 1;
      out.connection_status = m_conn;
      out.account_health = m_health;
      out.live_count = (m_type == GM_MAC_AT_LIVE && m_licensed) ? 1 : 0;
      out.demo_count = (m_type == GM_MAC_AT_DEMO && m_licensed) ? 1 : 0;
      out.connected_count = (m_conn == GM_MAC_CONN_CONNECTED && m_licensed) ? 1 : 0;
      out.disconnected_count = (m_conn == GM_MAC_CONN_DISCONNECTED) ? 1 : 0;
      out.offline_count = (m_conn == GM_MAC_CONN_OFFLINE) ? 1 : 0;
      out.warning_count = (m_conn == GM_MAC_CONN_WARNING) ? 1 : 0;
      out.healthy_count = (m_licensed && m_health >= 70.0) ? 1 : 0;

      if(!m_licensed)
        {
         out.account_list = StringFormat(
            "EXCLUDED (unlicensed) | Login=%I64d | LicenseHealth=%.0f\r\n",
            m_login, m_license_health);
         return;
        }

      out.account_list = StringFormat(
         "Login=%I64d | Broker=%s | Server=%s | Type=%s | Conn=%s | Health=%.0f | License=%.0f\r\n",
         m_login, m_broker, m_server,
         (m_type == GM_MAC_AT_LIVE ? "LIVE" : "DEMO"),
         GmMacConnName(m_conn), m_health, m_license_health);
     }
  };

#endif // GM_CMAC_MULTI_ACCOUNT_ENGINE_MQH
//+------------------------------------------------------------------+
