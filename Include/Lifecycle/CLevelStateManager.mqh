//+------------------------------------------------------------------+
//|                                         CLevelStateManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CLEVEL_STATE_MANAGER_MQH
#define GM_CLEVEL_STATE_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmLevelRecord.mqh"
#include "CLevelHistoryManager.mqh"
#include "../Logging/CLogger.mqh"

/// @file CLevelStateManager.mqh
/// @brief Controlled state transitions for level lifecycle.

class CGmLevelStateManager
  {
private:
   CGmLogger              *m_logger;
   CGmLevelHistoryManager *m_history;

public:
                     CGmLevelStateManager(void)
                       : m_logger(NULL), m_history(NULL) {}
                    ~CGmLevelStateManager(void)
     {
      m_logger = NULL;
      m_history = NULL;
     }

   void Init(CGmLogger *logger, CGmLevelHistoryManager *history)
     {
      m_logger = logger;
      m_history = history;
     }

   bool SetState(SGmLevelRecord &rec,
                 const ENUM_GM_LEVEL_STATE new_state,
                 const ENUM_GM_LEVEL_EVENT evt,
                 const string note)
     {
      const ENUM_GM_LEVEL_STATE old_state = rec.state;
      rec.state = new_state;

      if(new_state == GM_LVL_COMPLETED || new_state == GM_LVL_FAILED || new_state == GM_LVL_EXPIRED)
         rec.active_for_cycle = false;
      else if(new_state == GM_LVL_WAITING || new_state == GM_LVL_PENDING_PLACED ||
              new_state == GM_LVL_REACTIVATED || new_state == GM_LVL_TRADE_RUNNING)
         rec.active_for_cycle = true;

      if(m_history != NULL)
         m_history.Append(rec, evt, new_state, note);

      if(m_logger != NULL)
         m_logger.Info(StringFormat("State | %s | %s → %s | %s",
                                    rec.level_tag,
                                    SGmLevelRecord::StateToString(old_state),
                                    SGmLevelRecord::StateToString(new_state),
                                    note),
                       "LevelState");
      return true;
     }

   bool IsTerminal(const ENUM_GM_LEVEL_STATE st) const
     {
      return (st == GM_LVL_COMPLETED || st == GM_LVL_FAILED || st == GM_LVL_EXPIRED);
     }

   bool CanPlacePending(const SGmLevelRecord &rec) const
     {
      if(!rec.used || !rec.active_for_cycle)
         return false;
      if(IsTerminal(rec.state))
         return false;
      if(rec.state == GM_LVL_TRADE_RUNNING || rec.state == GM_LVL_TRADE_ACTIVATED)
         return false;
      if(rec.state == GM_LVL_PENDING_PLACED)
         return false;
      return (rec.state == GM_LVL_WAITING || rec.state == GM_LVL_SL_FIRST || rec.state == GM_LVL_REACTIVATED);
     }
  };

#endif // GM_CLEVEL_STATE_MANAGER_MQH
//+------------------------------------------------------------------+
