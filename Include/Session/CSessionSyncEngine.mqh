//+------------------------------------------------------------------+
//|                                        CSessionSyncEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CSESSION_SYNC_ENGINE_MQH
#define GM_CSESSION_SYNC_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmSessionRecord.mqh"
#include "CSessionAudit.mqh"
#include "CSessionPerformance.mqh"
#include "COrderSyncEngine.mqh"
#include "../Lifecycle/CLevelManager.mqh"
#include "../Lifecycle/SGmLevelRecord.mqh"
#include "../Trading/CTradeRegistry.mqh"

/// @file CSessionSyncEngine.mqh
/// @brief Keep session counters aligned with levels / trades / pendings.

class CGmSessionSyncEngine
  {
private:
   CGmLogger             *m_logger;
   CGmSessionAudit       *m_audit;
   CGmSessionPerformance *m_perf;
   CGmLevelManager       *m_levels;
   CGmTradeRegistry      *m_registry;
   CGmOrderSyncEngine    *m_orders;
   bool                   m_ready;

public:
                     CGmSessionSyncEngine(void)
                       : m_logger(NULL), m_audit(NULL), m_perf(NULL),
                         m_levels(NULL), m_registry(NULL), m_orders(NULL), m_ready(false)
     {
     }

                    ~CGmSessionSyncEngine(void)
     {
      m_logger = NULL;
      m_audit = NULL;
      m_perf = NULL;
      m_levels = NULL;
      m_registry = NULL;
      m_orders = NULL;
     }

   void Init(CGmLogger *logger,
             CGmSessionAudit *audit,
             CGmSessionPerformance *perf,
             CGmLevelManager *levels,
             CGmTradeRegistry *registry,
             CGmOrderSyncEngine *orders)
     {
      m_logger = logger;
      m_audit = audit;
      m_perf = perf;
      m_levels = levels;
      m_registry = registry;
      m_orders = orders;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Session Synchronization Engine ready", "SessionSync");
     }

   void RefreshSessionStats(SGmSessionRecord &session)
     {
      if(!m_ready || !session.used)
         return;

      const ulong t0 = GetMicrosecondCount();

      if(m_orders != NULL)
        {
         m_orders.SetSessionH4(session.h4_bar_time);
         m_orders.Synchronize();
         session.pending_orders = m_orders.CountOwnPendings();
         session.active_trades = m_orders.CountOwnPositions();
        }

      int active = 0, completed = 0, failed = 0;
      if(m_levels != NULL)
         m_levels.CountLevelStats(active, completed, failed);
      session.active_levels = active;
      session.completed_levels = completed;
      session.failed_levels = failed;

      // Ensure registry rows belong to this session when possible
      if(m_registry != NULL && session.h4_bar_time > 0)
        {
         const int n = m_registry.Count();
         for(int i = 0; i < n; i++)
           {
            SGmTradeRecord rec;
            if(!m_registry.GetAt(i, rec))
               continue;
            if(rec.status == GM_TRADE_STATUS_PENDING && rec.h4_cycle_id == 0)
              {
               rec.h4_cycle_id = session.h4_bar_time;
               m_registry.Upsert(rec);
              }
           }
        }

      const ulong us = GetMicrosecondCount() - t0;
      if(m_perf != NULL)
         m_perf.RecordDbSync(us);

      if(m_audit != NULL)
         m_audit.Record(GM_AUDIT_SYNC, "SessionSync",
                        StringFormat("activeLvl=%d done=%d fail=%d pend=%d trades=%d",
                                     session.active_levels, session.completed_levels,
                                     session.failed_levels, session.pending_orders,
                                     session.active_trades),
                        session.session_id);
     }
  };

#endif // GM_CSESSION_SYNC_ENGINE_MQH
//+------------------------------------------------------------------+
