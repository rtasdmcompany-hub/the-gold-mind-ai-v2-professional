//+------------------------------------------------------------------+
//|                                               CCycleEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CCYCLE_ENGINE_MQH
#define GM_CCYCLE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../Core/TradingRules.mqh"
#include "../Logging/CLogger.mqh"
#include "../Calculation/CLevelEngine.mqh"
#include "../Lifecycle/CLevelManager.mqh"
#include "../Session/CH4SessionEngine.mqh"
#include "CPendingOrderEngine.mqh"
#include "CTradeIdManager.mqh"
#include "CTradeOwnership.mqh"

/// @file CCycleEngine.mqh
/// @brief H4 cycle orchestrator — Sprint 7 session-aware startup + rollover.

class CGmCycleEngine
  {
private:
   CGmLogger             *m_logger;
   CGmLevelEngine        *m_levels;
   CGmPendingOrderEngine *m_pendings;
   CGmTradeOwnership     *m_ownership;
   CGmLevelManager       *m_level_mgr;
   CGmH4SessionEngine    *m_session;
   string                 m_symbol;
   long                   m_magic;
   string                 m_gv_cycle;
   datetime               m_active_h4_bar;
   bool                   m_initialized;
   bool                   m_cycle_armed;

   string BuildCycleGvName(void) const
     {
      string sym = m_symbol;
      StringReplace(sym, ".", "_");
      return StringFormat("GM_H4_%I64d_%s", m_magic, sym);
     }

   void PersistCycleBar(const datetime bar_time)
     {
      m_active_h4_bar = bar_time;
      if(StringLen(m_gv_cycle) > 0)
         GlobalVariableSet(m_gv_cycle, (double)bar_time);
     }

   datetime LoadPersistedCycleBar(void) const
     {
      if(StringLen(m_gv_cycle) == 0 || !GlobalVariableCheck(m_gv_cycle))
         return 0;
      return (datetime)GlobalVariableGet(m_gv_cycle);
     }

public:
                     CGmCycleEngine(void)
                       : m_logger(NULL),
                         m_levels(NULL),
                         m_pendings(NULL),
                         m_ownership(NULL),
                         m_level_mgr(NULL),
                         m_session(NULL),
                         m_symbol(""),
                         m_magic(0),
                         m_gv_cycle(""),
                         m_active_h4_bar(0),
                         m_initialized(false),
                         m_cycle_armed(false)
     {
     }

                    ~CGmCycleEngine(void)
     {
      m_logger = NULL;
      m_levels = NULL;
      m_pendings = NULL;
      m_ownership = NULL;
      m_level_mgr = NULL;
      m_session = NULL;
     }

   bool Init(CGmLogger *logger,
             CGmLevelEngine *levels,
             CGmPendingOrderEngine *pendings,
             CGmTradeOwnership *ownership,
             CGmLevelManager *level_mgr,
             const string symbol,
             const long magic)
     {
      m_logger = logger;
      m_levels = levels;
      m_pendings = pendings;
      m_ownership = ownership;
      m_level_mgr = level_mgr;
      m_symbol = symbol;
      m_magic = magic;
      m_gv_cycle = BuildCycleGvName();
      m_active_h4_bar = LoadPersistedCycleBar();
      m_initialized = (m_levels != NULL && m_pendings != NULL && m_ownership != NULL);

      if(m_logger != NULL)
         m_logger.Info(StringFormat("Cycle Engine ready | strategyTF=H4 | persisted_bar=%s",
                                    TimeToString(m_active_h4_bar, TIME_DATE | TIME_MINUTES)),
                       "CycleEngine");
      return m_initialized;
     }

   void SetSessionEngine(CGmH4SessionEngine *session) { m_session = session; }

   datetime ActiveH4Bar(void) const { return m_active_h4_bar; }
   bool IsArmed(void) const { return m_cycle_armed; }

   /// @brief Startup: recover inventory, generate levels from last CLOSED H4, place if needed.
   bool RunStartup(void)
     {
      if(!m_initialized)
         return false;

      const ulong t0 = GetMicrosecondCount();
      if(m_logger != NULL)
         m_logger.Info("STARTUP CYCLE — immediate activation (no wait for next H4)", "CycleEngine");

      m_levels.SetSymbol(m_symbol);
      if(!m_levels.Recalculate())
        {
         if(m_logger != NULL)
            m_logger.Error("Startup level generation failed", "CycleEngine");
         return false;
        }

      const SGmLevels snap = m_levels.GetLevelsCopy();
      const datetime closed_h4 = snap.h4_bar_time;
      const int own_pendings = m_ownership.CountOwnPendingOrders();
      const int own_positions = m_ownership.CountOwnPositions();

      if(m_logger != NULL)
         m_logger.Info(StringFormat("Recovery inventory | positions=%d pendings=%d | closed_H4=%s | persisted=%s",
                                    own_positions,
                                    own_pendings,
                                    TimeToString(closed_h4, TIME_DATE | TIME_MINUTES),
                                    TimeToString(m_active_h4_bar, TIME_DATE | TIME_MINUTES)),
                       "Recovery");

      // Same H4 cycle already armed with pendings → restore lifecycle, no duplicates.
      if(m_active_h4_bar == closed_h4 && own_pendings > 0)
        {
         if(m_level_mgr != NULL)
            m_level_mgr.Recover(closed_h4);
         if(m_session != NULL)
            m_session.Recover(closed_h4);
         m_cycle_armed = true;
         if(m_logger != NULL)
            m_logger.Success("Recovery: current H4 cycle pendings already present — no duplicate placement",
                             "Recovery");
         return true;
        }

      // Stale cycle pendings from a previous H4 → delete unused, then place fresh.
      if(own_pendings > 0 && m_active_h4_bar != closed_h4)
        {
         if(m_logger != NULL)
            m_logger.Warning("Stale cycle pendings detected — deleting unused own pendings before re-arm",
                             "Recovery");
         const int deleted = m_pendings.DeleteUnusedOwnPendings();
         if(m_session != NULL)
            m_session.OnSessionCleanup(deleted);
        }

      // Positions from previous cycles are NEVER touched.
      if(own_positions > 0 && m_logger != NULL)
         m_logger.Info(StringFormat("Active positions kept running | count=%d (no interference)", own_positions),
                       "CycleEngine");

      // Fresh H4 level lifecycle + session + placement
      if(m_level_mgr != NULL)
         m_level_mgr.BeginNewCycle(snap);
      if(m_session != NULL)
         m_session.BeginSession(snap);

      const int placed = m_pendings.PlaceAll(snap);
      if(m_session != NULL)
         m_session.OnOrdersPlaced(placed);
      PersistCycleBar(closed_h4);
      m_cycle_armed = true;

      const ulong elapsed_us = GetMicrosecondCount() - t0;
      if(m_logger != NULL)
         m_logger.Success(StringFormat("Startup cycle complete | placed=%d | H4=%s | %I64u us",
                                       placed,
                                       TimeToString(closed_h4, TIME_DATE | TIME_MINUTES),
                                       elapsed_us),
                          "CycleEngine");
      return true;
     }

   /// @brief New H4 candle closed — rollover unused pendings + new levels/orders.
   bool OnNewH4Closed(void)
     {
      if(!m_initialized)
         return false;

      const ulong t0 = GetMicrosecondCount();
      if(m_logger != NULL)
         m_logger.Info("NEW H4 CLOSED — rollover starting", "CycleEngine");

      // 1) Delete ONLY unused own pendings (positions untouched).
      const int deleted = m_pendings.DeleteUnusedOwnPendings();
      if(m_session != NULL)
         m_session.OnSessionCleanup(deleted);

      // 2) Generate new levels from newest CLOSED H4.
      if(!m_levels.Recalculate())
        {
         if(m_logger != NULL)
            m_logger.Error("H4 rollover level generation failed", "CycleEngine");
         return false;
        }

      const SGmLevels snap = m_levels.GetLevelsCopy();

      // Guard: if somehow same bar, skip duplicate.
      if(snap.h4_bar_time == m_active_h4_bar && m_ownership.CountOwnPendingOrders() > 0)
        {
         if(m_logger != NULL)
            m_logger.Warning("H4 rollover skipped — cycle bar unchanged with pendings present",
                             "CycleEngine");
         if(m_session != NULL)
            m_session.Recover(snap.h4_bar_time);
         return true;
        }

      // 3) Reset level lifecycle + session + place new pendings.
      if(m_level_mgr != NULL)
         m_level_mgr.BeginNewCycle(snap);
      if(m_session != NULL)
         m_session.BeginSession(snap);

      const int placed = m_pendings.PlaceAll(snap);
      if(m_session != NULL)
         m_session.OnOrdersPlaced(placed);
      PersistCycleBar(snap.h4_bar_time);
      m_cycle_armed = true;

      const ulong elapsed_us = GetMicrosecondCount() - t0;
      if(m_logger != NULL)
         m_logger.Success(StringFormat("H4 rollover complete | placed=%d | H4=%s | positions untouched | %I64u us",
                                       placed,
                                       TimeToString(snap.h4_bar_time, TIME_DATE | TIME_MINUTES),
                                       elapsed_us),
                          "CycleEngine");
      return true;
     }
  };

#endif // GM_CCYCLE_ENGINE_MQH
//+------------------------------------------------------------------+
