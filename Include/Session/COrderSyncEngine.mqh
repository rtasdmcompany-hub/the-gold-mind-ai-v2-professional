//+------------------------------------------------------------------+
//|                                          COrderSyncEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CORDER_SYNC_ENGINE_MQH
#define GM_CORDER_SYNC_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CSessionAudit.mqh"
#include "CSessionPerformance.mqh"
#include "../Trading/CTradeRegistry.mqh"
#include "../Trading/CTradeOwnership.mqh"
#include "../Trading/SGmTradeRecord.mqh"

/// @file COrderSyncEngine.mqh
/// @brief Synchronize pending / market / closed orders with trade registry.

class CGmOrderSyncEngine
  {
private:
   CGmLogger           *m_logger;
   CGmSessionAudit     *m_audit;
   CGmSessionPerformance *m_perf;
   CGmTradeRegistry    *m_registry;
   CGmTradeOwnership   *m_ownership;
   long                 m_magic;
   string               m_symbol;
   datetime             m_session_h4;
   bool                 m_ready;

public:
                     CGmOrderSyncEngine(void)
                       : m_logger(NULL), m_audit(NULL), m_perf(NULL),
                         m_registry(NULL), m_ownership(NULL),
                         m_magic(0), m_symbol(""), m_session_h4(0), m_ready(false)
     {
     }

                    ~CGmOrderSyncEngine(void)
     {
      m_logger = NULL;
      m_audit = NULL;
      m_perf = NULL;
      m_registry = NULL;
      m_ownership = NULL;
     }

   void Init(CGmLogger *logger,
             CGmSessionAudit *audit,
             CGmSessionPerformance *perf,
             CGmTradeRegistry *registry,
             CGmTradeOwnership *ownership,
             const long magic,
             const string symbol)
     {
      m_logger = logger;
      m_audit = audit;
      m_perf = perf;
      m_registry = registry;
      m_ownership = ownership;
      m_magic = magic;
      m_symbol = symbol;
      m_ready = (registry != NULL && ownership != NULL);
      if(m_logger != NULL)
         m_logger.Info("Order Synchronization Engine ready", "OrderSync");
     }

   void SetSessionH4(const datetime h4) { m_session_h4 = h4; }

   int CountOwnPendings(void) const
     {
      return (m_ownership != NULL) ? m_ownership.CountOwnPendingOrders() : 0;
     }

   int CountOwnPositions(void) const
     {
      return (m_ownership != NULL) ? m_ownership.CountOwnPositions() : 0;
     }

   /// @brief Sync terminal orders/positions into registry; mark missing actives closed.
   void Synchronize(void)
     {
      if(!m_ready)
         return;
      const ulong t0 = GetMicrosecondCount();

      if(m_registry != NULL)
         m_registry.SyncFromTerminal();

      // Stamp session H4 onto active registry rows missing cycle id
      if(m_registry != NULL && m_session_h4 > 0)
        {
         const int n = m_registry.Count();
         for(int i = 0; i < n; i++)
           {
            SGmTradeRecord rec;
            if(!m_registry.GetAt(i, rec))
               continue;
            if(rec.status != GM_TRADE_STATUS_ACTIVE && rec.status != GM_TRADE_STATUS_PENDING)
               continue;
            if(rec.h4_cycle_id == 0)
              {
               rec.h4_cycle_id = m_session_h4;
               m_registry.Upsert(rec);
              }
           }
        }

      const ulong us = GetMicrosecondCount() - t0;
      if(m_perf != NULL)
         m_perf.RecordOrderProcess(us);

      if(m_audit != NULL)
         m_audit.Record(GM_AUDIT_SYNC, "OrderSync",
                        StringFormat("pendings=%d positions=%d | %I64u us",
                                     CountOwnPendings(), CountOwnPositions(), us),
                        (ulong)m_session_h4);
     }
  };

#endif // GM_CORDER_SYNC_ENGINE_MQH
//+------------------------------------------------------------------+
