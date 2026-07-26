//+------------------------------------------------------------------+
//|                                   CCloudMonitoringEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Cloud-ready telemetry foundation — local observation first  |
//+------------------------------------------------------------------+
#ifndef GM_CCLOUD_MONITORING_ENGINE_MQH
#define GM_CCLOUD_MONITORING_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmEnterpriseResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../Memory/SGmMemoryLearningResult.mqh"
#include "../Reporting/SGmReportingResult.mqh"
#include "../Conversation/SGmConversationResult.mqh"

class CGmCloudMonitoringEngine
  {
public:
   void Analyze(const SGmAssistantResult &sup,
                const SGmMemoryLearningResult &mem,
                const SGmReportingResult &rpt,
                const SGmConversationResult &chat,
                const bool core_ready,
                const bool dashboard_ok,
                SGmEnterpriseResult &r)
     {
      const bool connected = (TerminalInfoInteger(TERMINAL_CONNECTED) != 0);
      r.connection_health = connected ? "Online" : "Offline";
      r.core_status = core_ready ? "Operational" : "Unavailable";
      r.dashboard_status = dashboard_ok ? "Operational" : "Degraded";
      r.api_health = "Read-only foundation ready";
      r.database_health = "File-backed enterprise DB ready";

      r.learning_service = (mem.valid ? "Available" : "Warming");
      r.reporting_service = (rpt.valid ? "Available" : "Warming");
      r.assistant_service = (chat.valid ? "Available" : "Warming");

      int services_up = 0;
      if(core_ready) services_up++;
      if(dashboard_ok) services_up++;
      if(mem.valid) services_up++;
      if(rpt.valid) services_up++;
      if(chat.valid) services_up++;
      if(connected) services_up++;

      r.service_availability = StringFormat("%d/6 services observable", services_up);
      r.cloud_system_status = (services_up >= 5 && connected) ? "Cloud Foundation Healthy"
                              : (connected ? "Cloud Foundation Degraded"
                                           : "Cloud Foundation Offline");

      const double health = sup.valid ? sup.system_health_score : 70.0;
      r.cloud_health_report = StringFormat(
                                 "=== CLOUD HEALTH REPORT ===\r\nStatus=%s\r\nCore=%s\r\nDashboard=%s\r\nAPI=%s\r\nDB=%s\r\nConnection=%s\r\nServices=%s\r\nLocalSysHealth=%.0f\r\n%s\r\n",
                                 r.cloud_system_status,
                                 r.core_status,
                                 r.dashboard_status,
                                 r.api_health,
                                 r.database_health,
                                 r.connection_health,
                                 r.service_availability,
                                 health,
                                 GM_ENT_ADVISORY);
     }
  };

#endif // GM_CCLOUD_MONITORING_ENGINE_MQH
//+------------------------------------------------------------------+
