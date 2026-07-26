//+------------------------------------------------------------------+
//|                                            CJournalSearch.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CJOURNAL_SEARCH_MQH
#define GM_CJOURNAL_SEARCH_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "JournalConstants.mqh"
#include "SGmTradeJournalRecord.mqh"
#include "CTradeJournal.mqh"
#include "../Logging/CLogger.mqh"

/// @file CJournalSearch.mqh
/// @brief Search & filter engine for Trade Journal (READ-ONLY).

struct SGmJournalFilter
  {
   datetime from_date;
   datetime to_date;
   ulong    trade_id;
   ulong    session_id;
   ENUM_GM_JOURNAL_FILTER filter;
   bool     used;

   void Reset(void)
     {
      from_date = 0;
      to_date = 0;
      trade_id = 0;
      session_id = 0;
      filter = GM_JF_ALL;
      used = false;
     }
  };

class CGmJournalSearch
  {
private:
   CGmLogger *m_logger;
   int        m_hits[GM_SEARCH_RESULT_MAX];
   int        m_hit_count;
   ulong      m_last_us;

   bool Match(const SGmTradeJournalRecord &r, const SGmJournalFilter &f) const
     {
      if(!r.used)
         return false;
      if(f.trade_id > 0 && r.trade_id != f.trade_id)
         return false;
      if(f.session_id > 0 && r.session_id != f.session_id)
         return false;
      if(f.from_date > 0 && r.open_time > 0 && r.open_time < f.from_date)
         return false;
      if(f.to_date > 0 && r.open_time > 0 && r.open_time > f.to_date)
         return false;

      switch(f.filter)
        {
         case GM_JF_BUY:
            return (r.side == "BUY");
         case GM_JF_SELL:
            return (r.side == "SELL");
         case GM_JF_WINNING:
            return (!r.is_open && r.profit_loss >= 0.0);
         case GM_JF_LOSING:
            return (!r.is_open && r.profit_loss < 0.0);
         case GM_JF_OPEN:
            return r.is_open;
         case GM_JF_CLOSED:
            return !r.is_open;
         case GM_JF_RECOVERY:
            return r.is_recovery;
         default:
            return true;
        }
     }

public:
                     CGmJournalSearch(void)
                       : m_logger(NULL), m_hit_count(0), m_last_us(0)
     {
      ArrayInitialize(m_hits, -1);
     }

   void Init(CGmLogger *logger) { m_logger = logger; }

   int HitCount(void) const { return m_hit_count; }
   ulong LastSearchUs(void) const { return m_last_us; }

   bool GetHitIndex(const int n, int &journal_index) const
     {
      if(n < 0 || n >= m_hit_count)
         return false;
      journal_index = m_hits[n];
      return (journal_index >= 0);
     }

   int Execute(CGmTradeJournal *journal, const SGmJournalFilter &filter)
     {
      const ulong t0 = GetMicrosecondCount();
      m_hit_count = 0;
      ArrayInitialize(m_hits, -1);
      if(journal == NULL)
         return 0;

      const int n = journal.Count();
      for(int i = 0; i < n && m_hit_count < GM_SEARCH_RESULT_MAX; i++)
        {
         SGmTradeJournalRecord r;
         if(!journal.GetAt(i, r))
            continue;
         if(!Match(r, filter))
            continue;
         m_hits[m_hit_count++] = i;
        }

      m_last_us = GetMicrosecondCount() - t0;
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Search Executed | filter=%d | hits=%d | %I64u us",
                                    (int)filter.filter, m_hit_count, m_last_us),
                       "JournalSearch");
      return m_hit_count;
     }
  };

#endif // GM_CJOURNAL_SEARCH_MQH
//+------------------------------------------------------------------+
