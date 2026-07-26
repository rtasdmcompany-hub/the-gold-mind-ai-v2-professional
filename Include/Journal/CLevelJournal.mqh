//+------------------------------------------------------------------+
//|                                          CLevelJournal.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CLEVEL_JOURNAL_MQH
#define GM_CLEVEL_JOURNAL_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmLevelJournalRecord.mqh"
#include "JournalConstants.mqh"
#include "../Logging/CLogger.mqh"
#include "../Lifecycle/SGmLevelRecord.mqh"
#include "../Lifecycle/EnumsLifecycle.mqh"
#include "../Calculation/EnumsLevels.mqh"
#include "../Calculation/LevelConstants.mqh"
#include "../Lifecycle/CLevelManager.mqh"

/// @file CLevelJournal.mqh
/// @brief Level Journal — snapshots level lifecycle (READ-ONLY).

class CGmLevelJournal
  {
private:
   CGmLogger            *m_logger;
   SGmLevelJournalRecord m_items[GM_LEVEL_JOURNAL_MAX];
   int                   m_count;

   int FindTag(const string level_id) const
     {
      for(int i = 0; i < m_count; i++)
        {
         if(m_items[i].used && m_items[i].level_id == level_id)
            return i;
        }
      return -1;
     }

   int Alloc(void)
     {
      if(m_count < GM_LEVEL_JOURNAL_MAX)
        {
         const int idx = m_count++;
         m_items[idx].Reset();
         m_items[idx].used = true;
         return idx;
        }
      for(int i = 1; i < GM_LEVEL_JOURNAL_MAX; i++)
         m_items[i - 1] = m_items[i];
      m_items[GM_LEVEL_JOURNAL_MAX - 1].Reset();
      m_items[GM_LEVEL_JOURNAL_MAX - 1].used = true;
      return GM_LEVEL_JOURNAL_MAX - 1;
     }

public:
                     CGmLevelJournal(void) : m_logger(NULL), m_count(0) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_count = 0;
     }

   int Count(void) const { return m_count; }

   bool GetAt(const int index, SGmLevelJournalRecord &out) const
     {
      if(index < 0 || index >= m_count || !m_items[index].used)
         return false;
      out = m_items[index];
      return true;
     }

   void RecordFromLevel(const SGmLevelRecord &rec)
     {
      if(!rec.used || StringLen(rec.level_tag) == 0)
         return;
      int idx = FindTag(rec.level_tag);
      if(idx < 0)
         idx = Alloc();

      SGmLevelJournalRecord j;
      j.Reset();
      j.used = true;
      j.level_id = rec.level_tag;
      j.side = (rec.direction == GM_LEVEL_SIDE_BUY) ? "BUY" : "SELL";
      j.calculated_price = rec.entry_price;
      j.activation_time = rec.open_time;
      j.session_id = (ulong)rec.h4_cycle_id;
      j.magic = rec.magic;
      j.symbol = rec.symbol;
      j.first_sl = (rec.attempt >= 1 &&
                    (rec.state == GM_LVL_SL_FIRST || rec.state == GM_LVL_REACTIVATED ||
                     rec.state == GM_LVL_SL_SECOND || rec.state == GM_LVL_FAILED ||
                     rec.attempt >= 2));
      j.second_sl = (rec.attempt >= 2 &&
                     (rec.state == GM_LVL_SL_SECOND || rec.state == GM_LVL_FAILED));
      j.take_profit = (rec.state == GM_LVL_TP_HIT || rec.state == GM_LVL_COMPLETED);
      j.completed = (rec.state == GM_LVL_COMPLETED || rec.state == GM_LVL_TP_HIT);
      j.failed = (rec.state == GM_LVL_FAILED);
      j.expired = (rec.state == GM_LVL_EXPIRED);
      m_items[idx] = j;

      if(m_logger != NULL)
         m_logger.Debug(StringFormat("Level Recorded | %s | state=%s",
                                     j.level_id, EnumToString(rec.state)),
                        "LevelJournal");
     }

   /// @brief Pull READ-ONLY snapshots from LevelManager DB.
   void SyncFromLevelManager(CGmLevelManager *levels)
     {
      if(levels == NULL)
         return;
      for(int t = 0; t < GM_LEVEL_COUNT; t++)
        {
         SGmLevelRecord rec;
         if(!levels.PeekLevel((ENUM_GM_LEVEL_TAG)t, rec))
            continue;
         RecordFromLevel(rec);
        }
     }
  };

#endif // GM_CLEVEL_JOURNAL_MQH
//+------------------------------------------------------------------+
