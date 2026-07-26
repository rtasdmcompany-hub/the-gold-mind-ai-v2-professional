//+------------------------------------------------------------------+
//|                                          CEtjReplayEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     READ-ONLY historical replay architecture                    |
//+------------------------------------------------------------------+
#ifndef GM_CETJ_REPLAY_ENGINE_MQH
#define GM_CETJ_REPLAY_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmEtjTradeRecord.mqh"
#include "CEtjJournalEngine.mqh"
#include "CEtjTimelineEngine.mqh"
#include "../Logging/CLogger.mqh"

class CGmEtjReplayEngine
  {
private:
   CGmLogger          *m_logger;
   ENUM_GM_ETJ_REPLAY  m_status;
   ulong               m_focus_tid;
   int                 m_event_cursor;
   string              m_summary;
   bool                m_chart_sync_future; // architecture reserved

public:
                     CGmEtjReplayEngine(void)
                       : m_logger(NULL), m_status(GM_ETJ_RP_IDLE),
                         m_focus_tid(0), m_event_cursor(0),
                         m_summary(""), m_chart_sync_future(true) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_status = GM_ETJ_RP_IDLE;
      m_focus_tid = 0;
      m_event_cursor = 0;
      m_summary = "Replay Idle | Chart sync = FUTURE";
     }

   ENUM_GM_ETJ_REPLAY Status(void) const { return m_status; }
   string Summary(void) const { return m_summary; }

   /// @brief Build read-only replay package for latest closed trade.
   void Generate(CGmEtjJournalEngine *journal, CGmEtjTimelineEngine *timeline)
     {
      if(journal == NULL)
        {
         m_status = GM_ETJ_RP_IDLE;
         m_summary = "No journal";
         return;
        }

      SGmEtjTradeRecord r;
      ulong best_tid = 0;
      datetime best_t = 0;
      for(int i = 0; i < journal.Count(); i++)
        {
         if(!journal.GetAt(i, r))
            continue;
         if(r.status != GM_ETJ_ST_CLOSED)
            continue;
         if(r.close_time >= best_t)
           {
            best_t = r.close_time;
            best_tid = r.trade_id;
           }
        }

      if(best_tid == 0)
        {
         // Fall back to any trade
         for(int j = journal.Count() - 1; j >= 0; j--)
           {
            if(journal.GetAt(j, r))
              {
               best_tid = r.trade_id;
               break;
              }
           }
        }

      m_focus_tid = best_tid;
      m_event_cursor = 0;
      if(m_focus_tid == 0)
        {
         m_status = GM_ETJ_RP_IDLE;
         m_summary = "Replay Idle | No GM trades";
         return;
        }

      m_status = GM_ETJ_RP_READY;
      m_summary = StringFormat(
         "Replay Ready | TID=%I64u | Events=%d | Price/AI/Dashboard replay ARCH | ChartSync=FUTURE",
         m_focus_tid,
         (timeline != NULL) ? timeline.Count() : 0);

      if(m_logger != NULL)
         m_logger.Info("Replay Generated | " + m_summary, "ETJ");
     }

   // Navigation stubs (read-only architecture)
   void Play(void)
     {
      if(m_status == GM_ETJ_RP_READY || m_status == GM_ETJ_RP_PAUSED)
         m_status = GM_ETJ_RP_PLAYING;
     }

   void Pause(void)
     {
      if(m_status == GM_ETJ_RP_PLAYING)
         m_status = GM_ETJ_RP_PAUSED;
     }

   void StepEvent(void) { m_event_cursor++; }
  };

#endif // GM_CETJ_REPLAY_ENGINE_MQH
//+------------------------------------------------------------------+
