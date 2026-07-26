//+------------------------------------------------------------------+
//|                                       CEifControlCenter.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEIF_CONTROL_CENTER_MQH
#define GM_CEIF_CONTROL_CENTER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "InfrastructureConstants.mqh"
#include "SGmInfrastructureResult.mqh"
#include "../SGmCloudStatus.mqh"

class CGmEifControlCenter
  {
private:
   bool m_ready;

   double Avg3(const double a, const double b, const double c) const
     {
      return (a + b + c) / 3.0;
     }

public:
                     CGmEifControlCenter(void) : m_ready(false) {}

   bool Init(void)
     {
      m_ready = true;
      return true;
     }

   void Compose(const SGmCloudStatus &cloud,
                SGmInfrastructureResult &out) const
     {
      if(!m_ready)
         return;

      out.avg_latency_ms = out.network_latency_ms;
      out.avg_cpu_pct = out.vps_cpu_pct;
      out.avg_ram_pct = out.vps_ram_pct;

      out.cloud_health = cloud.valid
                        ? (cloud.cloud_status == GM_CLOUD_STATUS_ONLINE ? 95.0
                           : (cloud.cloud_status == GM_CLOUD_STATUS_OFFLINE ? 40.0 : 65.0))
                        : 50.0;

      out.license_health = cloud.valid
                           ? (StringFind(cloud.license_status, "Architecture") >= 0 ? 80.0 : 90.0)
                           : 75.0;

      out.infra_health = Avg3(
         out.internet_stability,
         (out.vps_cpu_pct < 85.0 ? 90.0 : 55.0),
         out.sync_health);

      out.enterprise_score = Avg3(out.cloud_health, out.license_health, out.infra_health);
      if(out.online_devices > 0)
         out.enterprise_score = (out.enterprise_score + 5.0);
      if(out.enterprise_score > 100.0)
         out.enterprise_score = 100.0;

      out.center_status = "ENTERPRISE CONTROL CENTER READY";
      out.enterprise_status = StringFormat(
         "Devices=%d Online=%d Offline=%d | Cloud=%.0f License=%.0f SyncQ=%d NtfQ=%d | Score=%.0f",
         out.connected_devices, out.online_devices, out.offline_devices,
         out.cloud_health, out.license_health,
         out.sync_queue_depth, out.notification_queue_depth,
         out.enterprise_score);
      out.insight = StringFormat("%s | %s | %s",
                                 out.center_status, GM_EIF_POLICY, GM_EIF_SAFE);
      out.may_execute = false;
      out.may_modify_risk = false;
      out.valid = true;
     }
  };

#endif // GM_CEIF_CONTROL_CENTER_MQH
//+------------------------------------------------------------------+
