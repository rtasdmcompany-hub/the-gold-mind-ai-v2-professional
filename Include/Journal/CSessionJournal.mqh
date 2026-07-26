//+------------------------------------------------------------------+
//|                                             CSessionJournal.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|              Phase 2 Sprint 5 — H4 Session Journal              |
//+------------------------------------------------------------------+
#ifndef GM_CSESSION_JOURNAL_MQH
#define GM_CSESSION_JOURNAL_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "JournalConstants.mqh"
#include "SGmSessionJournalRecord.mqh"
#include "../Logging/CLogger.mqh"
#include "../Session/CH4SessionEngine.mqh"
#include "../Analytics/SGmAnalyticsSnapshot.mqh"

/// @file CSessionJournal.mqh
/// @brief READ-ONLY H4 session journal.

class CGmSessionJournal
  {
private:
   CGmLogger                *m_logger;
   SGmSessionJournalRecord   m_rows[GM_SESSION_JOURNAL_MAX];
   int                       m_count;
   ulong                     m_seq;

   int FindByStart(const datetime start) const
     {
      for(int i = 0; i < m_count; i++)
        {
         if(m_rows[i].used && m_rows[i].start_time == start)
            return i;
        }
      return -1;
     }

   int Alloc(void)
     {
      if(m_count < GM_SESSION_JOURNAL_MAX)
        {
         const int idx = m_count++;
         m_rows[idx].Reset();
         m_rows[idx].used = true;
         return idx;
        }
      for(int i = 1; i < GM_SESSION_JOURNAL_MAX; i++)
         m_rows[i - 1] = m_rows[i];
      m_rows[GM_SESSION_JOURNAL_MAX - 1].Reset();
      m_rows[GM_SESSION_JOURNAL_MAX - 1].used = true;
      return GM_SESSION_JOURNAL_MAX - 1;
     }

public:
                     CGmSessionJournal(void) : m_logger(NULL), m_count(0), m_seq(0) {}
                    ~CGmSessionJournal(void) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_count = 0;
      m_seq = 0;
     }

   int Count(void) const { return m_count; }

   bool GetAt(const int index, SGmSessionJournalRecord &out) const
     {
      if(index < 0 || index >= m_count || !m_rows[index].used)
         return false;
      out = m_rows[index];
      return true;
     }

   bool GetCurrent(SGmSessionJournalRecord &out) const
     {
      if(m_count <= 0)
         return false;
      out = m_rows[m_count - 1];
      return out.used;
     }

   void SyncFromSession(CGmH4SessionEngine *sess, const SGmAnalyticsSnapshot &an)
     {
      if(sess == NULL)
         return;
      const SGmSessionRecord cur = sess.Current();
      if(!cur.used || cur.session_id == 0)
         return;

      int idx = FindByStart(cur.h4_bar_time);
      if(idx < 0)
        {
         idx = Alloc();
         m_seq++;
         m_rows[idx].session_number = m_seq;
         if(m_logger != NULL)
            m_logger.Info(StringFormat("Session Recorded | #%I64u | SID=%I64u",
                                       m_rows[idx].session_number, cur.session_id),
                          "SessionJournal");
        }

      SGmSessionJournalRecord r = m_rows[idx];
      r.used = true;
      r.start_time = cur.h4_bar_time;
      r.end_time = cur.candle_close;
      r.generated_levels = (cur.generated_levels > 0) ? cur.generated_levels : 6;
      r.completed_trades = an.total_trades;
      r.winning_trades = an.winning_trades;
      r.losing_trades = an.losing_trades;
      r.net_profit = an.total_net_profit;
      r.win_rate = an.overall_win_rate;
      r.drawdown = an.current_dd_pct;
      r.magic = an.magic;
      r.symbol = an.symbol;
      m_rows[idx] = r;
     }
  };

#endif // GM_CSESSION_JOURNAL_MQH
//+------------------------------------------------------------------+
