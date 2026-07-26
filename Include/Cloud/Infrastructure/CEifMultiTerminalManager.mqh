//+------------------------------------------------------------------+
//|                                  CEifMultiTerminalManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEIF_MULTI_TERMINAL_MANAGER_MQH
#define GM_CEIF_MULTI_TERMINAL_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "InfrastructureConstants.mqh"
#include "SGmInfrastructureResult.mqh"
#include "CEifDeviceGroupManager.mqh"
#include "CEifInfrastructureSecurity.mqh"
#include "../SGmCloudStatus.mqh"
#include "../../Core/Version.mqh"

class CGmEifMultiTerminalManager
  {
private:
   SGmEifTerminalRecord          m_devices[GM_EIF_DEVICE_MAX];
   int                           m_n;
   CGmEifDeviceGroupManager     *m_groups;
   CGmEifInfrastructureSecurity *m_sec;
   bool                          m_ready;

public:
                     CGmEifMultiTerminalManager(void)
                       : m_n(0), m_groups(NULL), m_sec(NULL), m_ready(false) {}

   bool Init(CGmEifDeviceGroupManager *groups, CGmEifInfrastructureSecurity *sec)
     {
      m_groups = groups;
      m_sec = sec;
      m_n = 0;
      m_ready = true;
      return true;
     }

   int Count(void) const { return m_n; }

   void UpsertLocal(const SGmCloudStatus &cloud,
                    const string broker,
                    const long account,
                    const string account_type,
                    const string server,
                    const bool ea_running,
                    const bool is_vps_node)
     {
      if(!m_ready) return;

      SGmEifTerminalRecord rec;
      rec.Reset();
      rec.terminal_name = "MT5-" + IntegerToString((int)TerminalInfoInteger(TERMINAL_BUILD));
      rec.device_name = TerminalInfoString(TERMINAL_NAME);
      if(StringLen(rec.device_name) == 0)
         rec.device_name = "LocalDevice";
      rec.broker = broker;
      rec.account_number = account;
      rec.account_type = account_type;
      rec.server = server;
      rec.ea_version = GM_VERSION_STRING + "." + IntegerToString(GM_VERSION_BUILD);
      rec.license_type = cloud.valid ? cloud.license_status : "Professional";
      rec.running_status = ea_running ? "Running" : "Stopped";
      rec.connection_quality = cloud.valid
                               ? (cloud.cloud_status == GM_CLOUD_STATUS_ONLINE ? "Excellent" : "Fair")
                               : "Local";
      rec.last_heartbeat = TimeCurrent();
      rec.group = is_vps_node ? GM_EIF_GROUP_VPS : GM_EIF_GROUP_PRODUCTION;
      rec.is_vps = is_vps_node;
      rec.state = ea_running ? GM_EIF_DEV_ONLINE : GM_EIF_DEV_OFFLINE;
      if(cloud.valid && cloud.cloud_status == GM_CLOUD_STATUS_DEGRADED)
         rec.state = GM_EIF_DEV_DEGRADED;

      const string raw_id = StringFormat("%s|%I64d|%s",
                                         rec.device_name, account, rec.terminal_name);
      rec.device_token_hash = (m_sec != NULL) ? m_sec.DeviceToken(raw_id) : "";
      rec.trusted = false;
      if(m_sec != NULL && StringLen(rec.device_token_hash) > 0)
        {
         m_sec.RegisterTrusted(rec.device_token_hash);
         rec.trusted = m_sec.ValidateSession(rec.device_token_hash);
        }

      // Replace existing same account or append
      for(int i = 0; i < m_n; i++)
        {
         if(m_devices[i].account_number == account &&
            m_devices[i].device_name == rec.device_name)
           {
            m_devices[i] = rec;
            return;
           }
        }
      if(m_n < GM_EIF_DEVICE_MAX)
         m_devices[m_n++] = rec;
     }

   // Architecture: secondary placeholder slots for multi-install visibility
   void EnsureDemoSlots(void)
     {
      if(!m_ready || m_n >= 3) return;
      // Keep registry expandable; local node is primary. Placeholders offline.
      SGmEifTerminalRecord office;
      office.Reset();
      office.terminal_name = "Office-Terminal";
      office.device_name = "Office-PC";
      office.broker = "—";
      office.account_number = 0;
      office.account_type = "Demo";
      office.server = "—";
      office.ea_version = GM_VERSION_STRING;
      office.license_type = "Professional";
      office.running_status = "Standby";
      office.connection_quality = "n/a";
      office.last_heartbeat = 0;
      office.group = GM_EIF_GROUP_OFFICE;
      office.state = GM_EIF_DEV_OFFLINE;
      office.is_vps = false;
      office.trusted = false;
      if(m_n < GM_EIF_DEVICE_MAX) m_devices[m_n++] = office;

      SGmEifTerminalRecord vps;
      vps.Reset();
      vps.terminal_name = "VPS-Node-1";
      vps.device_name = "Enterprise-VPS";
      vps.broker = "—";
      vps.account_number = 0;
      vps.account_type = "Live";
      vps.server = "—";
      vps.ea_version = GM_VERSION_STRING;
      vps.license_type = "Professional";
      vps.running_status = "Standby";
      vps.connection_quality = "n/a";
      vps.last_heartbeat = 0;
      vps.group = GM_EIF_GROUP_VPS;
      vps.state = GM_EIF_DEV_OFFLINE;
      vps.is_vps = true;
      vps.trusted = false;
      if(m_n < GM_EIF_DEVICE_MAX) m_devices[m_n++] = vps;
     }

   void Aggregate(SGmInfrastructureResult &out) const
     {
      if(!m_ready) return;

      int connected = 0, online = 0, offline = 0;
      int on_vps = 0, off_vps = 0, on_term = 0, off_term = 0;
      string summary = "";

      for(int i = 0; i < m_n; i++)
        {
         if(m_groups != NULL && !m_groups.Passes(m_devices[i]))
            continue;

         connected++;
         const bool is_on = (m_devices[i].state == GM_EIF_DEV_ONLINE ||
                             m_devices[i].state == GM_EIF_DEV_DEGRADED);
         if(is_on) online++; else offline++;

         if(m_devices[i].is_vps)
           {
            if(is_on) on_vps++; else off_vps++;
           }
         else
           {
            if(is_on) on_term++; else off_term++;
           }

         if(StringLen(summary) > 0) summary += " | ";
         summary += m_devices[i].terminal_name + "=" +
                    GmEifDeviceStateName(m_devices[i].state);
        }

      out.connected_devices = connected;
      out.online_devices = online;
      out.offline_devices = offline;
      out.online_vps = on_vps;
      out.offline_vps = off_vps;
      out.online_terminals = on_term;
      out.offline_terminals = off_term;
      out.device_summary = summary;
      out.group_filter = (m_groups != NULL) ? m_groups.Summary() : "All";
     }
  };

#endif // GM_CEIF_MULTI_TERMINAL_MANAGER_MQH
//+------------------------------------------------------------------+
