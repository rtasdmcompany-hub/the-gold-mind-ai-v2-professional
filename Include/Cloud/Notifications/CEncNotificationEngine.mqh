//+------------------------------------------------------------------+
//|                                   CEncNotificationEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Multi-channel delivery orchestration (stubs / architecture) |
//+------------------------------------------------------------------+
#ifndef GM_CENC_NOTIFICATION_ENGINE_MQH
#define GM_CENC_NOTIFICATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "NotificationCenterConstants.mqh"
#include "CEncMessageQueue.mqh"

class CGmEncNotificationEngine
  {
private:
   CGmEncMessageQueue *m_queue;
   int                 m_desktop_sent;
   int                 m_mobile_sent;
   int                 m_email_sent;
   int                 m_push_sent;
   int                 m_cloud_sent;
   int                 m_webhook_sent;
   int                 m_api_sent;
   int                 m_silent_sent;
   bool                m_ready;

public:
                     CGmEncNotificationEngine(void)
                       : m_queue(NULL),
                         m_desktop_sent(0), m_mobile_sent(0), m_email_sent(0),
                         m_push_sent(0), m_cloud_sent(0), m_webhook_sent(0),
                         m_api_sent(0), m_silent_sent(0), m_ready(false) {}

   bool Init(CGmEncMessageQueue *queue)
     {
      m_queue = queue;
      m_ready = (m_queue != NULL);
      return m_ready;
     }

   // Drain at most one queued message — keeps CPU overhead near zero
   bool DrainOne(const bool online)
     {
      if(!m_ready || m_queue == NULL)
         return false;
      const int before = m_queue.Delivered() + m_queue.Failed();
      if(!m_queue.ProcessOne(online))
         return false;
      // Channel counters are architectural tallies after local delivery
      m_desktop_sent++;
      if(online)
        {
         m_cloud_sent++;
         m_api_sent++;
        }
      else
         m_silent_sent++;
      return (m_queue.Delivered() + m_queue.Failed() > before);
     }

   string ChannelSummary(void) const
     {
      return StringFormat("D=%d M=%d E=%d P=%d C=%d W=%d A=%d S=%d",
                          m_desktop_sent, m_mobile_sent, m_email_sent,
                          m_push_sent, m_cloud_sent, m_webhook_sent,
                          m_api_sent, m_silent_sent);
     }
  };

#endif // GM_CENC_NOTIFICATION_ENGINE_MQH
//+------------------------------------------------------------------+
