//+------------------------------------------------------------------+
//|                                       CLevelHistoryManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CLEVEL_HISTORY_MANAGER_MQH
#define GM_CLEVEL_HISTORY_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmLevelRecord.mqh"
#include "../Logging/CLogger.mqh"

/// @file CLevelHistoryManager.mqh
/// @brief Append-only in-record history for AI / audit trails.

class CGmLevelHistoryManager
  {
private:
   CGmLogger *m_logger;

public:
                     CGmLevelHistoryManager(void) : m_logger(NULL) {}
                    ~CGmLevelHistoryManager(void) { m_logger = NULL; }

   void Init(CGmLogger *logger) { m_logger = logger; }

   void Append(SGmLevelRecord &rec,
               const ENUM_GM_LEVEL_EVENT evt,
               const ENUM_GM_LEVEL_STATE state_after,
               const string note)
     {
      if(rec.history_count >= GM_LEVEL_HISTORY_MAX)
        {
         // Drop oldest by shifting left.
         for(int i = 1; i < GM_LEVEL_HISTORY_MAX; i++)
            rec.history[i - 1] = rec.history[i];
         rec.history_count = GM_LEVEL_HISTORY_MAX - 1;
        }

      const int idx = rec.history_count;
      rec.history[idx].time = TimeCurrent();
      rec.history[idx].event_id = evt;
      rec.history[idx].state_after = state_after;
      rec.history[idx].note = note;
      rec.history_count++;

      if(m_logger != NULL)
         m_logger.Info(StringFormat("LevelHistory | %s | LID=%I64u | %s | %s",
                                    rec.level_tag, rec.level_id,
                                    SGmLevelRecord::StateToString(state_after), note),
                       "LevelHistory");
     }
  };

#endif // GM_CLEVEL_HISTORY_MANAGER_MQH
//+------------------------------------------------------------------+
