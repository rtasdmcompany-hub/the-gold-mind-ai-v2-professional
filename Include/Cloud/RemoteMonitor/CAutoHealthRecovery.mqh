//+------------------------------------------------------------------+
//|                                     CAutoHealthRecovery.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Restarts background cloud services ONLY — never MT5/trades  |
//+------------------------------------------------------------------+
#ifndef GM_CAUTO_HEALTH_RECOVERY_MQH
#define GM_CAUTO_HEALTH_RECOVERY_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmRemoteMonitorResult.mqh"
#include "CEnterpriseTelemetry.mqh"
#include "CRemoteEventCenter.mqh"
#include "../CEnterpriseCloudEngine.mqh"

class CGmAutoHealthRecovery
  {
private:
   int  m_actions;
   bool m_ready;

public:
                     CGmAutoHealthRecovery(void) : m_actions(0), m_ready(false) {}

   bool Init(void)
     {
      m_actions = 0;
      m_ready = true;
      return true;
     }

   int Actions(void) const { return m_actions; }

   void Evaluate(CGmEnterpriseCloudEngine *cloud,
                 CGmEnterpriseTelemetry *telemetry,
                 CGmRemoteEventCenter *events,
                 SGmRemoteMonitorResult &r)
     {
      if(!m_ready)
         return;

      string log = "";
      bool acted = false;

      if(cloud != NULL && cloud.IsReady())
        {
         const SGmCloudStatus cs = cloud.Last();
         if(cs.valid && cs.offline_mode)
           {
            cloud.Process(true);
            log += "Cloud reconnect attempted; ";
            acted = true;
           }
         if(cs.valid && cs.sync_queue_depth > 20)
           {
            cloud.Process(true);
            log += "Sync service nudged; ";
            acted = true;
           }
        }

      if(telemetry != NULL && r.telemetry_status == "Unavailable")
        {
         log += "Telemetry service observed unavailable; ";
         acted = true;
        }

      if(r.cpu_usage_pct >= 60.0 || r.overall_health_score < 45.0)
        {
         log += "Background services soft-reset flag; ";
         acted = true;
        }

      if(acted)
        {
         m_actions++;
         r.recovery_actions = m_actions;
         r.recovery_log = log + GM_RM_SAFE;
         if(events != NULL)
            events.OnRecovery(r.recovery_log, r);
        }
      else
        {
         r.recovery_actions = m_actions;
         r.recovery_log = "No recovery needed";
        }
     }
  };

#endif // GM_CAUTO_HEALTH_RECOVERY_MQH
//+------------------------------------------------------------------+
