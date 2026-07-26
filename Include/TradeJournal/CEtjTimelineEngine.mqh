//+------------------------------------------------------------------+
//|                                        CEtjTimelineEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CETJ_TIMELINE_ENGINE_MQH
#define GM_CETJ_TIMELINE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmEtjTradeRecord.mqh"
#include "CEtjJournalEngine.mqh"
#include "../Logging/CLogger.mqh"

class CGmEtjTimelineEngine
  {
private:
   CGmLogger           *m_logger;
   SGmEtjTimelineEvent  m_events[GM_ETJ_MAX_EVENTS];
   int                  m_count;

   bool Exists(const ulong tid, const ENUM_GM_ETJ_EVENT ev) const
     {
      for(int i = 0; i < m_count; i++)
         if(m_events[i].used && m_events[i].trade_id == tid && m_events[i].event_type == ev)
            return true;
      return false;
     }

   void Push(const ulong tid, const ENUM_GM_ETJ_EVENT ev,
             const datetime ts, const string detail, const double price)
     {
      if(tid == 0 || Exists(tid, ev))
         return;
      int idx = m_count;
      if(m_count >= GM_ETJ_MAX_EVENTS)
        {
         for(int i = 1; i < GM_ETJ_MAX_EVENTS; i++)
            m_events[i - 1] = m_events[i];
         idx = GM_ETJ_MAX_EVENTS - 1;
         m_count = GM_ETJ_MAX_EVENTS;
        }
      else
         m_count++;

      m_events[idx].Reset();
      m_events[idx].used = true;
      m_events[idx].trade_id = tid;
      m_events[idx].event_type = ev;
      m_events[idx].stamped_at = (ts > 0) ? ts : TimeCurrent();
      m_events[idx].detail = detail;
      m_events[idx].price = price;
      if(m_logger != NULL)
         m_logger.Debug(StringFormat("Timeline Updated | TID=%I64u | %s",
                                     tid, GmEtjEventName(ev)), "ETJ");
     }

public:
                     CGmEtjTimelineEngine(void) : m_logger(NULL), m_count(0) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_count = 0;
     }

   int Count(void) const { return m_count; }

   string Summary(const int max_lines = 6) const
     {
      string s = "";
      const int start = MathMax(0, m_count - max_lines);
      for(int i = start; i < m_count; i++)
        {
         if(!m_events[i].used) continue;
         s += StringFormat("%s TID=%I64u @ %s | ",
                           GmEtjEventName(m_events[i].event_type),
                           m_events[i].trade_id,
                           TimeToString(m_events[i].stamped_at, TIME_MINUTES));
        }
      if(StringLen(s) == 0)
         return "No timeline events";
      return s;
     }

   void RebuildFromTrades(CGmEtjJournalEngine *journal)
     {
      if(journal == NULL)
         return;
      SGmEtjTradeRecord r;
      for(int i = 0; i < journal.Count(); i++)
        {
         if(!journal.GetAt(i, r))
            continue;
         Push(r.trade_id, GM_ETJ_EV_TRADE_ACTIVATED, r.open_time,
              "Trade Activated | " + GmEtjSideName(r.side), r.entry_price);
         if(r.break_even)
            Push(r.trade_id, GM_ETJ_EV_BREAK_EVEN, r.open_time,
                 "Break Even Activated", r.stop_loss);
         if(r.partial_close)
            Push(r.trade_id, GM_ETJ_EV_PARTIAL_80, r.open_time,
                 "80% Partial Close", r.entry_price);
         if(r.trailing)
            Push(r.trade_id, GM_ETJ_EV_TRAILING_STARTED, r.open_time,
                 "Trailing Started", r.stop_loss);
         if(StringFind(r.recovery_status, "Active") >= 0 ||
            StringFind(r.recovery_status, "Running") >= 0)
            Push(r.trade_id, GM_ETJ_EV_RECOVERY_STARTED, r.open_time,
                 "Recovery Started", r.entry_price);
         if(StringFind(r.recovery_status, "Done") >= 0 ||
            StringFind(r.recovery_status, "Finished") >= 0)
            Push(r.trade_id, GM_ETJ_EV_RECOVERY_FINISHED, r.close_time,
                 "Recovery Finished", r.exit_price);
         if(r.status == GM_ETJ_ST_CLOSED)
            Push(r.trade_id, GM_ETJ_EV_TRADE_CLOSED, r.close_time,
                 StringFormat("Trade Closed | P/L=%.2f | Duration=%ds",
                              r.profit_loss, r.duration_sec),
                 r.exit_price);
        }
     }
  };

#endif // GM_CETJ_TIMELINE_ENGINE_MQH
//+------------------------------------------------------------------+
