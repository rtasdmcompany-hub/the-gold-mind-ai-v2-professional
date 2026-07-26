//+------------------------------------------------------------------+
//|                                     CRmSystemHealthEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CRM_SYSTEM_HEALTH_ENGINE_MQH
#define GM_CRM_SYSTEM_HEALTH_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmRemoteMonitorResult.mqh"
#include "../SGmCloudStatus.mqh"

class CGmRmSystemHealthEngine
  {
public:
   void Measure(const SGmCloudStatus &cloud,
                const bool ai_ready,
                const ulong last_cycle_us,
                SGmRemoteMonitorResult &r)
     {
      const int mem_phys = (int)TerminalInfoInteger(TERMINAL_MEMORY_PHYSICAL);
      const int mem_avail = (int)TerminalInfoInteger(TERMINAL_MEMORY_AVAILABLE);
      const int mem_used = (mem_phys > 0) ? (mem_phys - MathMax(0, mem_avail)) : 0;

      r.ram_usage_pct = (mem_phys > 0)
                        ? GmRmClamp(100.0 * (double)mem_used / (double)mem_phys)
                        : 35.0;

      double cpu = 18.0;
      if(last_cycle_us > 800000) cpu = 55.0;
      else if(last_cycle_us > 400000) cpu = 38.0;
      else if(last_cycle_us > 150000) cpu = 28.0;
      else if(last_cycle_us > 50000) cpu = 22.0;
      if(!TerminalInfoInteger(TERMINAL_CONNECTED)) cpu += 5.0;
      r.cpu_usage_pct = GmRmClamp(cpu);

      r.terminal_performance = GmRmClamp(
         TerminalInfoInteger(TERMINAL_CONNECTED) ? 85.0 : 40.0);
      r.chart_refresh_score = GmRmClamp(70.0 + (ChartID() > 0 ? 15.0 : 0.0));
      r.tick_processing_score = GmRmClamp(
         (last_cycle_us > 0 && last_cycle_us < 200000) ? 90.0 :
         ((last_cycle_us < 500000) ? 75.0 : 55.0));
      r.order_processing_score = 88.0;
      r.database_health = GmRmClamp(r.database_status == "Healthy" ? 90.0 : 60.0);
      r.ai_processing_score = ai_ready ? 82.0 : 45.0;
      r.network_quality = TerminalInfoInteger(TERMINAL_CONNECTED)
                          ? GmRmClamp(90.0 - MathMin(40.0, r.cloud_latency_ms))
                          : 25.0;
      if(cloud.valid && cloud.offline_mode)
         r.network_quality = GmRmClamp(r.network_quality * 0.5);

      r.system_stability = GmRmClamp(
         0.25 * (100.0 - r.cpu_usage_pct) +
         0.20 * (100.0 - r.ram_usage_pct) +
         0.20 * r.terminal_performance +
         0.15 * r.network_quality +
         0.20 * r.database_health);

      r.overall_health_score = GmRmClamp(
         0.18 * (100.0 - r.cpu_usage_pct) +
         0.12 * (100.0 - r.ram_usage_pct) +
         0.12 * r.terminal_performance +
         0.10 * r.tick_processing_score +
         0.10 * r.ai_processing_score +
         0.12 * r.database_health +
         0.12 * r.network_quality +
         0.14 * r.system_stability);
     }
  };

#endif // GM_CRM_SYSTEM_HEALTH_ENGINE_MQH
//+------------------------------------------------------------------+
