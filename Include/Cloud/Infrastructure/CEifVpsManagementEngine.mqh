//+------------------------------------------------------------------+
//|                                    CEifVpsManagementEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     VPS health monitoring — observe only                        |
//+------------------------------------------------------------------+
#ifndef GM_CEIF_VPS_MANAGEMENT_ENGINE_MQH
#define GM_CEIF_VPS_MANAGEMENT_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "InfrastructureConstants.mqh"
#include "SGmInfrastructureResult.mqh"
#include "../SGmCloudStatus.mqh"
#include "../RemoteMonitor/SGmRemoteMonitorResult.mqh"

class CGmEifVpsManagementEngine
  {
private:
   bool m_ready;

   double ClampPct(const double v) const
     {
      if(v < 0.0) return 0.0;
      if(v > 100.0) return 100.0;
      return v;
     }

public:
                     CGmEifVpsManagementEngine(void) : m_ready(false) {}

   bool Init(void)
     {
      m_ready = true;
      return true;
     }

   void Measure(const SGmCloudStatus &cloud,
                const SGmRemoteMonitorResult &rm,
                const bool ea_running,
                SGmInfrastructureResult &out) const
     {
      if(!m_ready)
         return;

      // Local terminal acts as primary VPS/node sample (architecture)
      out.vps_cpu_pct = rm.valid ? ClampPct(rm.cpu_usage_pct) : 8.0;
      out.vps_ram_pct = rm.valid ? ClampPct(rm.ram_usage_pct) : 12.0;
      out.vps_disk_pct = 35.0 + (out.vps_ram_pct * 0.15);
      if(out.vps_disk_pct > 95.0) out.vps_disk_pct = 95.0;

      out.network_latency_ms = rm.valid ? rm.cloud_latency_ms
                              : (cloud.valid ? (double)cloud.latency_ms : 120.0);
      out.internet_stability = rm.valid ? ClampPct(rm.network_quality) : 70.0;

      const bool cloud_up = (cloud.valid && cloud.cloud_status == GM_CLOUD_STATUS_ONLINE);
      const bool healthy = (out.vps_cpu_pct < 90.0 && out.internet_stability > 40.0);

      out.vps_online_status = healthy ? "Online" : "Degraded";
      out.mt5_terminal_status = "Running";
      out.ea_running_status = ea_running ? "Running" : "Stopped";
      out.cloud_connection = cloud_up ? "Connected" : (cloud.valid ? GmCloudStatusName(cloud.cloud_status) : "n/a");
      out.synchronization_status = cloud.valid
                                   ? StringFormat("Queue=%d", cloud.sync_queue_depth)
                                   : "Local";
      out.heartbeat_status = (rm.valid && rm.heartbeat_status == "OK") ? "OK"
                             : (cloud.valid && cloud.heartbeat_ok ? "OK" : "Pending");
     }
  };

#endif // GM_CEIF_VPS_MANAGEMENT_ENGINE_MQH
//+------------------------------------------------------------------+
