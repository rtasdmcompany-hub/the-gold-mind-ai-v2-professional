//+------------------------------------------------------------------+
//|                                    CAIFleetHealthMonitor.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_FLEET_HEALTH_MONITOR_MQH
#define GM_CAI_FLEET_HEALTH_MONITOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmEnterpriseResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../../MultiInstance/SGmGlobalMonitorSnapshot.mqh"

class CGmAIFleetHealthMonitor
  {
public:
   void Analyze(const SGmEnterpriseResult &partial,
                const SGmAssistantResult &sup,
                const SGmGlobalMonitorSnapshot &mi,
                SGmEnterpriseResult &r)
     {
      r.connected_systems = partial.accounts_monitored;
      r.active_sessions = 1;
      if(mi.valid)
         r.active_sessions = MathMax(1, mi.active_symbols);

      double score = 55.0;
      if(partial.core_status == "Operational") score += 8.0;
      if(partial.dashboard_status == "Operational") score += 7.0;
      if(partial.connection_health == "Online") score += 8.0;
      if(partial.learning_service == "Available") score += 5.0;
      if(partial.reporting_service == "Available") score += 5.0;
      if(partial.assistant_service == "Available") score += 5.0;
      if(sup.valid) score += 0.10 * GmEntClamp(sup.system_health_score);
      if(mi.valid) score = 0.75 * score + 0.25 * GmEntClamp(mi.global_health);

      // Penalize critical/warning accounts
      score -= (double)partial.critical_accounts * 12.0;
      score -= (double)partial.warning_accounts * 4.0;
      r.fleet_health_score = GmEntClamp(score);

      if(r.fleet_health_score >= 90.0)
         r.fleet_status = "Operational";
      else if(r.fleet_health_score >= 70.0)
         r.fleet_status = "Stable";
      else if(r.fleet_health_score >= 50.0)
         r.fleet_status = "Degraded";
      else
         r.fleet_status = "Attention Required";

      if(partial.critical_accounts > 0)
         r.enterprise_alerts = StringFormat("CriticalAccounts=%d", partial.critical_accounts);
      else if(partial.warning_accounts > 0)
         r.enterprise_alerts = StringFormat("WarningAccounts=%d", partial.warning_accounts);
      else if(partial.connection_health != "Online")
         r.enterprise_alerts = "ConnectionOffline";
      else
         r.enterprise_alerts = "None";
     }
  };

#endif // GM_CAI_FLEET_HEALTH_MONITOR_MQH
//+------------------------------------------------------------------+
