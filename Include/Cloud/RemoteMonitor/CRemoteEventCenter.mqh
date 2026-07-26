//+------------------------------------------------------------------+
//|                                      CRemoteEventCenter.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CREMOTE_EVENT_CENTER_MQH
#define GM_CREMOTE_EVENT_CENTER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmRemoteMonitorResult.mqh"
#include "../SGmCloudStatus.mqh"
#include "../CCloudSecurity.mqh"

class CGmRemoteEventCenter
  {
private:
   CGmCloudSecurity *m_sec;
   string            m_events[GM_RM_EVENT_MAX];
   int               m_n;
   bool              m_prev_cloud_online;
   bool              m_prev_have;
   bool              m_started_logged;
   bool              m_ready;

   void Push(const ENUM_GM_RM_EVENT type, const string detail)
     {
      const string line = StringFormat("%s | %s | %s | sig=%s",
                                       TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS),
                                       GmRmEventName(type),
                                       detail,
                                       (m_sec != NULL) ? m_sec.SignRequest(GmRmEventName(type) + detail) : "");
      if(m_n < GM_RM_EVENT_MAX)
         m_events[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_RM_EVENT_MAX; i++)
            m_events[i - 1] = m_events[i];
         m_events[GM_RM_EVENT_MAX - 1] = line;
        }
     }

public:
                     CGmRemoteEventCenter(void)
                       : m_sec(NULL), m_n(0), m_prev_cloud_online(false),
                         m_prev_have(false), m_started_logged(false), m_ready(false) {}

   bool Init(CGmCloudSecurity *sec)
     {
      m_sec = sec;
      m_n = 0;
      m_ready = true;
      return true;
     }

   int Count(void) const { return m_n; }
   string Latest(void) const { return (m_n > 0) ? m_events[m_n - 1] : ""; }
   string Body(void) const
     {
      string b = "=== remote_events ===\r\n";
      for(int i = 0; i < m_n; i++)
         b += m_events[i] + "\r\n";
      return b;
     }

   void Emit(const SGmCloudStatus &cloud,
             const bool trading_ready,
             SGmRemoteMonitorResult &r)
     {
      if(!m_ready)
         return;

      if(!m_started_logged)
        {
         Push(GM_RM_EVT_EA_STARTED, "Remote Monitor online");
         if(trading_ready)
            Push(GM_RM_EVT_TRADING_READY, "Observed trading engine ready");
         m_started_logged = true;
        }

      const bool online = (cloud.valid && !cloud.offline_mode &&
                           cloud.cloud_status == GM_CLOUD_STATUS_ONLINE);
      if(m_prev_have)
        {
         if(online && !m_prev_cloud_online)
           {
            Push(GM_RM_EVT_CLOUD_CONNECTED, cloud.server_connection);
            Push(GM_RM_EVT_NETWORK_RECOVERY, "Cloud path recovered");
           }
         else if(!online && m_prev_cloud_online)
            Push(GM_RM_EVT_CLOUD_DISCONNECTED, cloud.server_connection);
        }
      m_prev_cloud_online = online;
      m_prev_have = true;

      if(r.cpu_usage_pct >= 50.0)
         Push(GM_RM_EVT_HIGH_CPU, StringFormat("%.0f%%", r.cpu_usage_pct));
      if(r.ram_usage_pct >= 85.0)
         Push(GM_RM_EVT_HIGH_RAM, StringFormat("%.0f%%", r.ram_usage_pct));
      if(r.database_status != "Healthy")
         Push(GM_RM_EVT_DATABASE_ERROR, r.database_status);

      Push(GM_RM_EVT_HEALTH_UPDATED, StringFormat("score=%.0f hb=%s tel=%s",
                                                  r.overall_health_score,
                                                  r.heartbeat_status,
                                                  r.telemetry_status));

      r.event_count = m_n;
      r.latest_event = Latest();
     }

   void OnRecovery(const string detail, SGmRemoteMonitorResult &r)
     {
      Push(GM_RM_EVT_RECOVERY, detail);
      r.latest_event = Latest();
      r.event_count = m_n;
     }

   void OnShutdown(void)
     {
      if(m_ready)
         Push(GM_RM_EVT_EA_STOPPED, "Remote Monitor shutting down");
     }
  };

#endif // GM_CREMOTE_EVENT_CENTER_MQH
//+------------------------------------------------------------------+
