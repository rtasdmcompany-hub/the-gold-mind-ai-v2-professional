//+------------------------------------------------------------------+
//|                                   CRemoteManagementEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CREMOTE_MANAGEMENT_ENGINE_MQH
#define GM_CREMOTE_MANAGEMENT_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmRemoteMonitorResult.mqh"
#include "../SGmCloudStatus.mqh"

class CGmRemoteManagementEngine
  {
public:
   void CollectStatus(const SGmCloudStatus &cloud,
                      const bool ea_running,
                      const bool trading_ready,
                      const bool ai_ready,
                      const bool dashboard_ready,
                      SGmRemoteMonitorResult &r)
     {
      r.ea_status = ea_running ? "Running" : "Stopped";
      r.chart_status = (ChartID() > 0) ? "Active" : "None";
      r.trading_engine_status = trading_ready ? "Ready" : "Not Ready";
      r.ai_status = ai_ready ? "Active" : "Off";
      r.database_status = dashboard_ready ? "Healthy" : "Unknown";

      if(cloud.valid)
        {
         r.cloud_status = GmCloudStatusName(cloud.cloud_status);
         r.connection_status = cloud.server_connection;
         r.license_status = cloud.license_status;
         r.heartbeat_status = cloud.heartbeat_ok ? "OK" : "Missed";
         r.cloud_latency_ms = (double)cloud.latency_ms;
         r.sync_status = StringFormat("Queue=%d", cloud.sync_queue_depth);
        }
      else
        {
         r.cloud_status = "Unavailable";
         r.connection_status = "Disconnected";
         r.license_status = "—";
         r.heartbeat_status = "—";
         r.sync_status = "—";
        }
     }
  };

#endif // GM_CREMOTE_MANAGEMENT_ENGINE_MQH
//+------------------------------------------------------------------+
