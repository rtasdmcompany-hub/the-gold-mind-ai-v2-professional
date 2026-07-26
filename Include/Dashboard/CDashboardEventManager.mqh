//+------------------------------------------------------------------+
//|                                  CDashboardEventManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CDASHBOARD_EVENT_MANAGER_MQH
#define GM_CDASHBOARD_EVENT_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "DashboardConstants.mqh"
#include "EnumsDashboard.mqh"
#include "../Logging/CLogger.mqh"

/// @file CDashboardEventManager.mqh
/// @brief Lightweight dashboard event queue (UI notifications only).

struct SGmDashEvent
  {
   ENUM_GM_DASH_EVENT type;
   datetime           stamped_at;
   string             message;
   ulong              ticket_or_id;
  };

class CGmDashboardEventManager
  {
private:
   CGmLogger   *m_logger;
   SGmDashEvent m_queue[];
   int          m_count;
   int          m_head;
   string       m_last_note;

public:
                     CGmDashboardEventManager(void)
                       : m_logger(NULL), m_count(0), m_head(0), m_last_note("")
     {
      ArrayResize(m_queue, GM_DASH_EVENT_QUEUE_MAX);
     }

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_count = 0;
      m_head = 0;
      m_last_note = "";
     }

   void Publish(const ENUM_GM_DASH_EVENT type,
                const string message,
                const ulong ticket_or_id = 0)
     {
      const int idx = (m_head + m_count) % GM_DASH_EVENT_QUEUE_MAX;
      if(m_count >= GM_DASH_EVENT_QUEUE_MAX)
        {
         m_head = (m_head + 1) % GM_DASH_EVENT_QUEUE_MAX;
         m_count = GM_DASH_EVENT_QUEUE_MAX - 1;
        }
      m_queue[idx].type = type;
      m_queue[idx].stamped_at = TimeCurrent();
      m_queue[idx].message = message;
      m_queue[idx].ticket_or_id = ticket_or_id;
      m_count++;
      m_last_note = message;
      if(m_logger != NULL && type == GM_DASH_EVT_ERROR)
         m_logger.Warning("DashEvent | " + message, "DashboardEvents");
     }

   bool Pop(SGmDashEvent &out)
     {
      if(m_count <= 0)
         return false;
      out = m_queue[m_head];
      m_head = (m_head + 1) % GM_DASH_EVENT_QUEUE_MAX;
      m_count--;
      return true;
     }

   int Count(void) const { return m_count; }
   string LastNote(void) const { return m_last_note; }

   void Clear(void)
     {
      m_count = 0;
      m_head = 0;
     }
  };

#endif // GM_CDASHBOARD_EVENT_MANAGER_MQH
//+------------------------------------------------------------------+
