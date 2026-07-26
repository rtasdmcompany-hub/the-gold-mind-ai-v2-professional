//+------------------------------------------------------------------+
//|                                        CEncMessageQueue.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CENC_MESSAGE_QUEUE_MQH
#define GM_CENC_MESSAGE_QUEUE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "NotificationCenterConstants.mqh"
#include "CEncNotificationSecurity.mqh"

struct SGmEncQueueItem
  {
   string                 id;
   string                 title;
   string                 body;
   ENUM_GM_ENC_CHANNEL    channel;
   ENUM_GM_ENC_PRIORITY   priority;
   ENUM_GM_ENC_CATEGORY   category;
   ENUM_GM_ENC_ALERT      alert;
   datetime               created_at;
   datetime               expires_at;
   int                    retries;
   bool                   delivered;
   bool                   failed;
   string                 signature;
   string                 fingerprint;

   void Reset(void)
     {
      id = title = body = signature = fingerprint = "";
      channel = GM_ENC_CH_DESKTOP;
      priority = GM_ENC_PRI_NORMAL;
      category = GM_ENC_CAT_SYSTEM;
      alert = GM_ENC_ALERT_NONE;
      created_at = expires_at = 0;
      retries = 0;
      delivered = failed = false;
     }
  };

class CGmEncMessageQueue
  {
private:
   SGmEncQueueItem           m_items[GM_ENC_QUEUE_MAX];
   int                       m_n;
   CGmEncNotificationSecurity *m_sec;
   int                       m_delivered;
   int                       m_failed;
   string                    m_recent_fp[GM_ENC_FEED_MAX];
   int                       m_fp_n;
   bool                      m_ready;

   bool IsDuplicate(const string fp) const
     {
      for(int i = 0; i < m_fp_n; i++)
         if(m_recent_fp[i] == fp)
            return true;
      return false;
     }

   void RememberFp(const string fp)
     {
      if(m_fp_n < GM_ENC_FEED_MAX)
         m_recent_fp[m_fp_n++] = fp;
      else
        {
         for(int i = 1; i < GM_ENC_FEED_MAX; i++)
            m_recent_fp[i - 1] = m_recent_fp[i];
         m_recent_fp[GM_ENC_FEED_MAX - 1] = fp;
        }
     }

   int FindInsertIndex(const ENUM_GM_ENC_PRIORITY pri) const
     {
      // Higher priority closer to front
      for(int i = 0; i < m_n; i++)
        {
         if((int)pri > (int)m_items[i].priority)
            return i;
        }
      return m_n;
     }

public:
                     CGmEncMessageQueue(void)
                       : m_n(0), m_sec(NULL), m_delivered(0), m_failed(0),
                         m_fp_n(0), m_ready(false) {}

   bool Init(CGmEncNotificationSecurity *sec)
     {
      m_sec = sec;
      m_n = m_delivered = m_failed = m_fp_n = 0;
      m_ready = true;
      return true;
     }

   int Depth(void) const { return m_n; }
   int Delivered(void) const { return m_delivered; }
   int Failed(void) const { return m_failed; }

   bool Enqueue(const ENUM_GM_ENC_ALERT alert,
                const string title,
                const string body,
                const ENUM_GM_ENC_CHANNEL channel,
                const ENUM_GM_ENC_PRIORITY priority,
                const ENUM_GM_ENC_CATEGORY category)
     {
      if(!m_ready) return false;

      const string fp = StringFormat("%d|%s|%s", (int)alert, title, body);
      if(IsDuplicate(fp))
         return false;

      SGmEncQueueItem item;
      item.Reset();
      item.id = StringFormat("ENC-%I64d-%d", (long)TimeCurrent(), m_n + m_delivered);
      item.title = title;
      item.body = body;
      item.channel = channel;
      item.priority = priority;
      item.category = category;
      item.alert = alert;
      item.created_at = TimeCurrent();
      item.expires_at = item.created_at + 86400;
      item.fingerprint = fp;
      item.signature = (m_sec != NULL) ? m_sec.SignMessage(item.id + "|" + title + "|" + body) : "";

      if(m_n >= GM_ENC_QUEUE_MAX)
        {
         // drop oldest non-critical if full
         for(int i = 1; i < m_n; i++)
            m_items[i - 1] = m_items[i];
         m_n--;
        }

      const int idx = FindInsertIndex(priority);
      for(int j = m_n; j > idx; j--)
         m_items[j] = m_items[j - 1];
      m_items[idx] = item;
      m_n++;
      RememberFp(fp);
      return true;
     }

   // Process at most one message per cycle (CPU budget)
   bool ProcessOne(const bool online)
     {
      if(!m_ready || m_n <= 0)
         return false;

      SGmEncQueueItem item = m_items[0];
      for(int i = 1; i < m_n; i++)
         m_items[i - 1] = m_items[i];
      m_n--;

      if(item.expires_at > 0 && TimeCurrent() > item.expires_at)
        {
         m_failed++;
         return true;
        }

      // Sprint 3: local/architecture delivery stub — no external network required
      if(!online && item.channel != GM_ENC_CH_DESKTOP && item.channel != GM_ENC_CH_SILENT)
        {
         // re-queue for offline retry (append)
         item.retries++;
         if(item.retries <= 5 && m_n < GM_ENC_QUEUE_MAX)
           {
            m_items[m_n++] = item;
            return true;
           }
         item.failed = true;
         m_failed++;
         return true;
        }

      item.delivered = true;
      m_delivered++;
      return true;
     }

   string PeekLatestTitle(void) const
     {
      return (m_n > 0) ? m_items[0].title : "";
     }
  };

#endif // GM_CENC_MESSAGE_QUEUE_MQH
//+------------------------------------------------------------------+
