//+------------------------------------------------------------------+
//|                                    CActivityTimeline.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CACTIVITY_TIMELINE_MQH
#define GM_CACTIVITY_TIMELINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "DashboardConstants.mqh"
#include "EnumsDashboard.mqh"

/// @file CActivityTimeline.mqh
/// @brief Live activity timeline — latest 100 events (READ-ONLY UI).

struct SGmTimelineEntry
  {
   datetime                 stamped_at;
   string                   module_name;
   string                   description;
   string                   status;
   ENUM_GM_NOTIFY_SEVERITY  severity;
   ulong                    trade_id;
   string                   level_id;
   ulong                    session_id;
  };

class CGmActivityTimeline
  {
private:
   SGmTimelineEntry m_items[GM_DASH_TIMELINE_MAX];
   int              m_count;
   int              m_head; // next write index (ring)

public:
                     CGmActivityTimeline(void) : m_count(0), m_head(0)
     {
      for(int i = 0; i < GM_DASH_TIMELINE_MAX; i++)
        {
         m_items[i].stamped_at = 0;
         m_items[i].module_name = "";
         m_items[i].description = "";
         m_items[i].status = "";
         m_items[i].severity = GM_SEV_INFO;
         m_items[i].trade_id = 0;
         m_items[i].level_id = "";
         m_items[i].session_id = 0;
        }
     }

   void Clear(void)
     {
      m_count = 0;
      m_head = 0;
     }

   int Count(void) const { return m_count; }

   void Push(const string module_name,
             const string description,
             const string status,
             const ENUM_GM_NOTIFY_SEVERITY severity,
             const ulong trade_id = 0,
             const string level_id = "",
             const ulong session_id = 0)
     {
      m_items[m_head].stamped_at = TimeCurrent();
      m_items[m_head].module_name = module_name;
      m_items[m_head].description = description;
      m_items[m_head].status = status;
      m_items[m_head].severity = severity;
      m_items[m_head].trade_id = trade_id;
      m_items[m_head].level_id = level_id;
      m_items[m_head].session_id = session_id;
      m_head = (m_head + 1) % GM_DASH_TIMELINE_MAX;
      if(m_count < GM_DASH_TIMELINE_MAX)
         m_count++;
     }

   /// @brief Newest-first index (0 = most recent).
   bool GetRecent(const int newest_index, SGmTimelineEntry &out) const
     {
      if(newest_index < 0 || newest_index >= m_count)
         return false;
      int idx = m_head - 1 - newest_index;
      while(idx < 0)
         idx += GM_DASH_TIMELINE_MAX;
      out = m_items[idx];
      return true;
     }

   string FormatLine(const SGmTimelineEntry &e) const
     {
      string tid = (e.trade_id > 0) ? StringFormat(" T%I64u", e.trade_id) : "";
      string lid = (StringLen(e.level_id) > 0) ? (" " + e.level_id) : "";
      return StringFormat("%s | %s | %s | %s%s%s",
                          TimeToString(e.stamped_at, TIME_SECONDS),
                          e.module_name,
                          e.description,
                          e.status,
                          tid, lid);
     }
  };

#endif // GM_CACTIVITY_TIMELINE_MQH
//+------------------------------------------------------------------+
