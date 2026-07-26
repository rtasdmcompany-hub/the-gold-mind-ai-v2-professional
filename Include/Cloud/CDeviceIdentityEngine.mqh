//+------------------------------------------------------------------+
//|                                    CDeviceIdentityEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CDEVICE_IDENTITY_ENGINE_MQH
#define GM_CDEVICE_IDENTITY_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CCloudSecurity.mqh"
#include "../Core/Version.mqh"

class CGmDeviceIdentityEngine
  {
private:
   CGmCloudSecurity *m_sec;
   string            m_install_id_hash;
   string            m_device_uuid_hash;
   string            m_ea_instance_hash;
   string            m_terminal_hash;
   string            m_broker_hash;
   string            m_account_hash;
   string            m_account_type;
   string            m_platform_ver;
   string            m_os_hash;
   string            m_hardware_hash;
   string            m_composite_hash;
   bool              m_ready;

public:
                     CGmDeviceIdentityEngine(void)
                       : m_sec(NULL), m_ready(false) {}

   bool Init(CGmCloudSecurity *sec, const long magic, const string symbol)
     {
      m_sec = sec;
      if(m_sec == NULL || !m_sec.IsReady())
         return false;

      const long login = AccountInfoInteger(ACCOUNT_LOGIN);
      const string server = AccountInfoString(ACCOUNT_SERVER);
      const long trade_mode = AccountInfoInteger(ACCOUNT_TRADE_MODE);
      m_account_type = (trade_mode == ACCOUNT_TRADE_MODE_DEMO) ? "Demo"
                       : ((trade_mode == ACCOUNT_TRADE_MODE_CONTEST) ? "Contest" : "Real");
      m_platform_ver = TerminalInfoString(TERMINAL_NAME) + " build " +
                       IntegerToString((int)TerminalInfoInteger(TERMINAL_BUILD));

      const string install_raw = StringFormat("%s|%I64d|%s|%s",
                                             TerminalInfoString(TERMINAL_DATA_PATH),
                                             magic, symbol, GM_VERSION_STRING);
      const string device_raw = StringFormat("%s|%s|%s",
                                            TerminalInfoString(TERMINAL_COMPANY),
                                            TerminalInfoString(TERMINAL_PATH),
                                            TerminalInfoString(TERMINAL_LANGUAGE));
      const string ea_raw = StringFormat("%I64d|%s|%I64d|%I64u",
                                         magic, symbol, (long)ChartID(),
                                         (ulong)TerminalInfoInteger(TERMINAL_MEMORY_PHYSICAL));
      const string term_raw = StringFormat("%s|%d",
                                          TerminalInfoString(TERMINAL_NAME),
                                          (int)TerminalInfoInteger(TERMINAL_BUILD));
      const string hw_raw = StringFormat("cores=%d|mem=%d|screen=%dx%d",
                                         (int)TerminalInfoInteger(TERMINAL_CPU_CORES),
                                         (int)TerminalInfoInteger(TERMINAL_MEMORY_PHYSICAL),
                                         (int)TerminalInfoInteger(TERMINAL_SCREEN_WIDTH),
                                         (int)TerminalInfoInteger(TERMINAL_SCREEN_HEIGHT));
      const string os_raw = StringFormat("x64=%d|dll=%d|connected=%d|tradeallowed=%d",
                                         (int)TerminalInfoInteger(TERMINAL_X64),
                                         (int)TerminalInfoInteger(TERMINAL_DLLS_ALLOWED),
                                         (int)TerminalInfoInteger(TERMINAL_CONNECTED),
                                         (int)TerminalInfoInteger(TERMINAL_TRADE_ALLOWED));

      m_install_id_hash = m_sec.HashHex(install_raw);
      m_device_uuid_hash = m_sec.HashHex(device_raw);
      m_ea_instance_hash = m_sec.HashHex(ea_raw);
      m_terminal_hash = m_sec.HashHex(term_raw);
      m_broker_hash = m_sec.HashHex(server);
      m_account_hash = m_sec.HashHex(IntegerToString(login));
      m_os_hash = m_sec.HashHex(os_raw);
      m_hardware_hash = m_sec.HashHex(hw_raw);
      m_composite_hash = m_sec.HashHex(
         m_install_id_hash + "|" + m_device_uuid_hash + "|" +
         m_ea_instance_hash + "|" + m_account_hash + "|" + m_hardware_hash);

      m_ready = true;
      return true;
     }

   bool IsReady(void) const { return m_ready; }
   string CompositeHash(void) const { return m_composite_hash; }
   string InstallIdHash(void) const { return m_install_id_hash; }
   string AccountType(void) const { return m_account_type; }
   string PlatformVersion(void) const { return m_platform_ver; }

   string EncryptedRecord(void) const
     {
      if(!m_ready || m_sec == NULL)
         return "";
      const string plain = StringFormat(
         "install=%s;device=%s;ea=%s;term=%s;broker=%s;acct=%s;type=%s;plat=%s;os=%s;hw=%s;comp=%s",
         m_install_id_hash, m_device_uuid_hash, m_ea_instance_hash, m_terminal_hash,
         m_broker_hash, m_account_hash, m_account_type, m_platform_ver,
         m_os_hash, m_hardware_hash, m_composite_hash);
      return m_sec.EncryptToBase64(plain);
     }

   string Summary(void) const
     {
      return StringFormat("Device=%s Type=%s Plat=%s",
                          StringSubstr(m_composite_hash, 0, 8),
                          m_account_type, m_platform_ver);
     }
  };

#endif // GM_CDEVICE_IDENTITY_ENGINE_MQH
//+------------------------------------------------------------------+
