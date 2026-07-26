//+------------------------------------------------------------------+
//|                                               CLevelManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CLEVEL_MANAGER_MQH
#define GM_CLEVEL_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CLevelGate.mqh"
#include "CLevelDatabase.mqh"
#include "CLevelHistoryManager.mqh"
#include "CLevelStateManager.mqh"
#include "CLevelValidationManager.mqh"
#include "CLevelLifecycleManager.mqh"
#include "CLevelRecoveryManager.mqh"
#include "../Calculation/SGmLevels.mqh"
#include "../Calculation/LevelConstants.mqh"
#include "../Logging/CLogger.mqh"
#include "../Core/CFileManager.mqh"

class CGmPendingOrderEngine;

/// @file CLevelManager.mqh
/// @brief Facade implementing CGmLevelGate for pending/trade engines.

class CGmLevelManager : public CGmLevelGate
  {
private:
   CGmLogger                 *m_logger;
   CGmLevelDatabase           m_db;
   CGmLevelHistoryManager     m_history;
   CGmLevelStateManager       m_state;
   CGmLevelValidationManager  m_validation;
   CGmLevelLifecycleManager   m_lifecycle;
   CGmLevelRecoveryManager    m_recovery;
   CGmPendingOrderEngine     *m_pendings;
   string                     m_symbol;
   long                       m_magic;
   datetime                   m_h4_cycle;
   bool                       m_initialized;

   ENUM_GM_LEVEL_TAG TagFromString(const string level_tag) const
     {
      for(int t = 0; t < GM_LEVEL_COUNT; t++)
        {
         if(SGmLevels::TagToComment((ENUM_GM_LEVEL_TAG)t) == level_tag)
            return (ENUM_GM_LEVEL_TAG)t;
        }
      return GM_TAG_BL1;
     }

public:
                     CGmLevelManager(void)
                       : m_logger(NULL),
                         m_pendings(NULL),
                         m_symbol(""),
                         m_magic(0),
                         m_h4_cycle(0),
                         m_initialized(false)
     {
     }

                    ~CGmLevelManager(void)
     {
      Shutdown();
      m_logger = NULL;
      m_pendings = NULL;
     }

   bool Init(CGmLogger *logger,
             CGmFileManager *files,
             const string symbol,
             const long magic)
     {
      m_logger = logger;
      m_symbol = symbol;
      m_magic = magic;
      if(!m_db.Init(logger, files, magic, symbol))
         return false;
      m_history.Init(logger);
      m_state.Init(logger, GetPointer(m_history));
      m_validation.Init(logger, symbol, magic);
      m_lifecycle.Init(logger, GetPointer(m_db), GetPointer(m_state), GetPointer(m_validation));
      m_recovery.Init(logger, GetPointer(m_db), GetPointer(m_state), GetPointer(m_history),
                      symbol, magic);
      m_initialized = true;
      if(m_logger != NULL)
         m_logger.Success("Level Manager online | Lifecycle Engine armed", "LevelManager");
      return true;
     }

   void BindPendingEngine(CGmPendingOrderEngine *pendings) { m_pendings = pendings; }
   void Shutdown(void) { if(m_initialized) m_db.Shutdown(); m_initialized = false; }

   datetime H4Cycle(void) const { return m_h4_cycle; }
   CGmLevelLifecycleManager *Lifecycle(void) { return GetPointer(m_lifecycle); }

   /// @brief READ-ONLY peek for Journal / Dashboard (never mutates lifecycle).
   bool PeekLevel(const ENUM_GM_LEVEL_TAG tag, SGmLevelRecord &out) const
     {
      return m_db.GetByTag(tag, out);
     }

   /// @brief Session engine helper — count level outcomes for current DB.
   void CountLevelStats(int &active_out, int &completed_out, int &failed_out) const
     {
      active_out = 0;
      completed_out = 0;
      failed_out = 0;
      for(int t = 0; t < GM_LEVEL_COUNT; t++)
        {
         SGmLevelRecord rec;
         if(!m_db.GetByTag((ENUM_GM_LEVEL_TAG)t, rec))
            continue;
         if(rec.state == GM_LVL_COMPLETED)
            completed_out++;
         else if(rec.state == GM_LVL_FAILED || rec.state == GM_LVL_EXPIRED)
            failed_out++;
         else if(rec.active_for_cycle ||
                 rec.state == GM_LVL_PENDING_PLACED ||
                 rec.state == GM_LVL_TRADE_ACTIVATED ||
                 rec.state == GM_LVL_TRADE_RUNNING ||
                 rec.state == GM_LVL_REACTIVATED ||
                 rec.state == GM_LVL_WAITING)
            active_out++;
        }
     }

   bool BeginNewCycle(const SGmLevels &levels)
     {
      if(!m_initialized)
         return false;
      m_h4_cycle = levels.h4_bar_time;
      m_lifecycle.SetH4Cycle(m_h4_cycle);
      return m_lifecycle.CreateCycleLevels(levels, m_magic, m_symbol);
     }

   bool Recover(const datetime current_h4)
     {
      m_h4_cycle = current_h4;
      m_lifecycle.SetH4Cycle(current_h4);
      return m_recovery.Recover(current_h4);
     }

   //--- CGmLevelGate
   virtual bool ShouldSkipPlacement(const ENUM_GM_LEVEL_TAG tag) const
     {
      return m_lifecycle.ShouldSkipPlacement(tag);
     }

   virtual int DesiredAttempt(const ENUM_GM_LEVEL_TAG tag) const
     {
      return m_lifecycle.DesiredAttempt(tag);
     }

   virtual double LockedEntry(const ENUM_GM_LEVEL_TAG tag, const double fallback) const
     {
      return m_lifecycle.LockedEntryPrice(tag, fallback);
     }

   virtual void NotifyPendingPlaced(const ENUM_GM_LEVEL_TAG tag,
                                    const ulong trade_id,
                                    const ulong order_ticket,
                                    const int attempt)
     {
      m_lifecycle.OnPendingPlaced(tag, trade_id, order_ticket, attempt);
     }

   virtual void NotifyActivated(const string level_tag,
                                const ulong trade_id,
                                const ulong position_ticket,
                                const double entry)
     {
      m_lifecycle.OnTradeActivated(TagFromString(level_tag), trade_id, position_ticket, entry);
     }

   virtual void NotifyClosed(const string level_tag,
                             const ulong trade_id,
                             const bool is_tp,
                             const bool is_sl,
                             const double pnl);
  };

#endif // GM_CLEVEL_MANAGER_MQH
//+------------------------------------------------------------------+
