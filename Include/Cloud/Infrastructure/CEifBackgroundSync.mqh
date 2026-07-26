//+------------------------------------------------------------------+
//|                                      CEifBackgroundSync.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEIF_BACKGROUND_SYNC_MQH
#define GM_CEIF_BACKGROUND_SYNC_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "InfrastructureConstants.mqh"
#include "SGmInfrastructureResult.mqh"
#include "CEifInfrastructureSecurity.mqh"
#include "../SGmCloudStatus.mqh"
#include "../RemoteMonitor/SGmRemoteMonitorResult.mqh"
#include "../Notifications/SGmNotificationCenterResult.mqh"

class CGmEifBackgroundSync
  {
private:
   CGmEifInfrastructureSecurity *m_sec;
   int                           m_cycles;
   int                           m_queue;
   ENUM_GM_EIF_SYNC_STATE        m_state;
   string                        m_last_payload_hash;
   bool                          m_ready;

public:
                     CGmEifBackgroundSync(void)
                       : m_sec(NULL), m_cycles(0), m_queue(0),
                         m_state(GM_EIF_SYNC_IDLE), m_last_payload_hash(""),
                         m_ready(false) {}

   bool Init(CGmEifInfrastructureSecurity *sec)
     {
      m_sec = sec;
      m_cycles = 0;
      m_queue = 0;
      m_state = GM_EIF_SYNC_IDLE;
      m_ready = true;
      return true;
     }

   ENUM_GM_EIF_SYNC_STATE State(void) const { return m_state; }
   int QueueDepth(void) const { return m_queue; }

   void Synchronize(const SGmCloudStatus &cloud,
                    const SGmRemoteMonitorResult &rm,
                    const SGmNotificationCenterResult &ntf,
                    SGmInfrastructureResult &out)
     {
      if(!m_ready)
         return;

      m_state = GM_EIF_SYNC_RUNNING;
      m_cycles++;

      // Async local sync packet (architecture) — never touches trading
      string body = StringFormat(
         "device|health=%.0f|cpu=%.0f|ram=%.0f|cloud=%s|ntf_q=%d|hb=%s",
         rm.valid ? rm.overall_health_score : 0.0,
         out.vps_cpu_pct,
         out.vps_ram_pct,
         cloud.valid ? GmCloudStatusName(cloud.cloud_status) : "n/a",
         ntf.valid ? ntf.queue_depth : 0,
         out.heartbeat_status);

      if(m_sec != NULL)
         m_last_payload_hash = m_sec.SignPayload(body);
      else
         m_last_payload_hash = "";

      m_queue = (cloud.valid ? cloud.sync_queue_depth : 0) +
                (ntf.valid ? ntf.queue_depth : 0);
      out.sync_queue_depth = m_queue;
      out.notification_queue_depth = ntf.valid ? ntf.queue_depth : 0;

      const bool ok = (StringLen(m_last_payload_hash) > 0) || !cloud.valid;
      m_state = ok ? GM_EIF_SYNC_OK : GM_EIF_SYNC_DEGRADED;
      out.sync_state = m_state;
      out.synchronization_status = GmEifSyncStateName(m_state) +
                                   " | hash=" +
                                   (StringLen(m_last_payload_hash) > 8
                                    ? StringSubstr(m_last_payload_hash, 0, 8)
                                    : "local");
      out.sync_health = (m_state == GM_EIF_SYNC_OK) ? 95.0
                        : (m_state == GM_EIF_SYNC_DEGRADED ? 60.0 : 40.0);
     }
  };

#endif // GM_CEIF_BACKGROUND_SYNC_MQH
//+------------------------------------------------------------------+
