//+------------------------------------------------------------------+
//|                                        CCloudOfflineMode.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CCLOUD_OFFLINE_MODE_MQH
#define GM_CCLOUD_OFFLINE_MODE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CloudConstants.mqh"

class CGmCloudOfflineMode
  {
private:
   bool     m_offline;
   datetime m_since;
   int      m_failures;
   ulong    m_next_retry_ms;

public:
                     CGmCloudOfflineMode(void)
                       : m_offline(true), m_since(0), m_failures(0), m_next_retry_ms(0) {}

   void Enable(void)
     {
      if(!m_offline)
         m_since = TimeCurrent();
      m_offline = true;
      m_failures++;
     }

   void Disable(void)
     {
      m_offline = false;
      m_failures = 0;
      m_next_retry_ms = 0;
     }

   bool IsOffline(void) const { return m_offline; }
   int Failures(void) const { return m_failures; }
   datetime Since(void) const { return m_since; }

   bool ShouldRetry(const ulong now_ms)
     {
      if(!m_offline) return false;
      if(m_next_retry_ms == 0 || now_ms >= m_next_retry_ms)
        {
         m_next_retry_ms = now_ms + (ulong)GM_CLOUD_RETRY_MS;
         return true;
        }
      return false;
     }
  };

#endif // GM_CCLOUD_OFFLINE_MODE_MQH
//+------------------------------------------------------------------+
