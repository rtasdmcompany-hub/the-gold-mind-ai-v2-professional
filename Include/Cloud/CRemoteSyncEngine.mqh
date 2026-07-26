//+------------------------------------------------------------------+
//|                                       CRemoteSyncEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Queued sync — never blocks trading                          |
//+------------------------------------------------------------------+
#ifndef GM_CREMOTE_SYNC_ENGINE_MQH
#define GM_CREMOTE_SYNC_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CloudConstants.mqh"
#include "CCloudSecurity.mqh"

class CGmRemoteSyncEngine
  {
private:
   CGmCloudSecurity *m_sec;
   string            m_queue[GM_CLOUD_SYNC_QUEUE_MAX];
   int               m_q;
   datetime          m_last_sync_at;
   int               m_completed;
   int               m_failed;
   bool              m_ready;

   void Push(const string item)
     {
      if(m_q >= GM_CLOUD_SYNC_QUEUE_MAX)
        {
         for(int i = 1; i < GM_CLOUD_SYNC_QUEUE_MAX; i++)
            m_queue[i - 1] = m_queue[i];
         m_queue[GM_CLOUD_SYNC_QUEUE_MAX - 1] = item;
         return;
        }
      m_queue[m_q++] = item;
     }

public:
                     CGmRemoteSyncEngine(void)
                       : m_sec(NULL), m_q(0), m_last_sync_at(0),
                         m_completed(0), m_failed(0), m_ready(false) {}

   bool Init(CGmCloudSecurity *sec)
     {
      m_sec = sec;
      m_q = 0;
      m_completed = m_failed = 0;
      m_ready = (m_sec != NULL);
      if(m_ready)
        {
         Enqueue("EA Settings");
         Enqueue("Dashboard Preferences");
         Enqueue("Theme");
         Enqueue("Panel Layout");
         Enqueue("Language");
         Enqueue("AI Preferences");
         Enqueue("Notification Settings");
         Enqueue("Cloud Configuration");
        }
      return m_ready;
     }

   void Enqueue(const string channel)
     {
      if(!m_ready) return;
      const string sig = (m_sec != NULL) ? m_sec.SignRequest(channel) : "";
      Push(StringFormat("%s|%s|%s",
                        TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS),
                        channel, sig));
     }

   int QueueDepth(void) const { return m_q; }
   datetime LastSyncAt(void) const { return m_last_sync_at; }
   int Completed(void) const { return m_completed; }
   int Failed(void) const { return m_failed; }

   // Local/offline flush simulation — does not call remote servers in Sprint 1
   bool ProcessOne(const bool online)
     {
      if(!m_ready || m_q <= 0)
         return false;
      if(!online)
         return false; // keep queued while offline

      // Pop front
      for(int i = 1; i < m_q; i++)
         m_queue[i - 1] = m_queue[i];
      m_q--;
      m_completed++;
      m_last_sync_at = TimeCurrent();
      return true;
     }

   string QueueSummary(void) const
     {
      return StringFormat("Queue=%d Done=%d Fail=%d", m_q, m_completed, m_failed);
     }
  };

#endif // GM_CREMOTE_SYNC_ENGINE_MQH
//+------------------------------------------------------------------+
