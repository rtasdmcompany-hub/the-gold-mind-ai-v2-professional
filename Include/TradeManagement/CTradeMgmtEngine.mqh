//+------------------------------------------------------------------+
//|                                         CTradeMgmtEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CTRADE_MGMT_ENGINE_MQH
#define GM_CTRADE_MGMT_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "TradeMgmtConstants.mqh"
#include "CPipTools.mqh"
#include "CProfitMonitor.mqh"
#include "CTradeMgmtValidator.mqh"
#include "CBreakEvenEngine.mqh"
#include "CPartialCloseEngine.mqh"
#include "CTrailingStopEngine.mqh"
#include "../Trading/CTradeRegistry.mqh"
#include "../Trading/CTradeOwnership.mqh"
#include "../Logging/CLogger.mqh"

/// @file CTradeMgmtEngine.mqh
/// @brief Orchestrates Profit Monitor → BE → Partial → Trailing with recovery.

class CGmTradeMgmtEngine
  {
private:
   CGmLogger               *m_logger;
   CGmTradeRegistry        *m_registry;
   CGmTradeOwnership       *m_ownership;
   CGmProfitMonitor         m_monitor;
   CGmTradeMgmtValidator    m_validator;
   CGmBreakEvenEngine       m_be;
   CGmPartialCloseEngine    m_partial;
   CGmTrailingStopEngine    m_trail;
   string                   m_symbol;
   long                     m_magic;
   bool                     m_ready;

   void SyncStageFromFlags(SGmTradeRecord &rec) const
     {
      if(rec.status == GM_TRADE_STATUS_CLOSED)
        {
         rec.stage = GM_TRADE_STAGE_CLOSED;
         return;
        }
      if(rec.trailing_active)
        {
         rec.stage = GM_TRADE_STAGE_TRAILING;
         return;
        }
      if(rec.partial_done)
        {
         rec.stage = GM_TRADE_STAGE_PARTIAL_DONE;
         return;
        }
      if(rec.be_done)
        {
         rec.stage = GM_TRADE_STAGE_BREAK_EVEN;
         return;
        }
      if(rec.profit_pips >= GM_BE_TRIGGER_PIPS)
        {
         rec.stage = GM_TRADE_STAGE_PROFIT_50;
         return;
        }
      if(rec.status == GM_TRADE_STATUS_ACTIVE)
         rec.stage = GM_TRADE_STAGE_RUNNING;
      else
         rec.stage = GM_TRADE_STAGE_OPENED;
     }

   void ProcessOne(SGmTradeRecord &rec)
     {
      if(rec.ticket == 0 || rec.status != GM_TRADE_STATUS_ACTIVE)
         return;
      if(!m_monitor.IsOwnPosition(rec.ticket))
        {
         if(!PositionSelectByTicket(rec.ticket))
           {
            rec.status = GM_TRADE_STATUS_CLOSED;
            rec.stage = GM_TRADE_STAGE_CLOSED;
            if(m_logger != NULL)
               m_logger.Info(StringFormat("Trade Closed (mgmt) | ticket=%I64u", rec.ticket),
                             "TradeMgmt");
            m_registry.Upsert(rec, true);
           }
         return;
        }

      bool dirty = false;
      bool structural = false;
      const double pips = m_monitor.CurrentProfitPips(rec.ticket);
      if(MathAbs(rec.profit_pips - pips) > 0.05)
        {
         rec.profit_pips = pips;
         dirty = true;
        }
      if(rec.original_volume <= 0.0 && PositionSelectByTicket(rec.ticket))
        {
         rec.original_volume = PositionGetDouble(POSITION_VOLUME);
         dirty = true;
         structural = true;
        }
      if(PositionSelectByTicket(rec.ticket))
        {
         const double vol = PositionGetDouble(POSITION_VOLUME);
         if(MathAbs(rec.volume - vol) > 1e-8)
           {
            rec.volume = vol;
            dirty = true;
            structural = true;
           }
        }

      if(m_logger != NULL)
         m_logger.Debug(StringFormat("Current Profit | ticket=%I64u pips=%.1f money=%.2f stage=%d",
                                     rec.ticket, rec.profit_pips,
                                     m_monitor.CurrentProfitMoney(rec.ticket),
                                     (int)rec.stage),
                        "TradeMgmt");

      if(!rec.be_done && rec.profit_pips >= GM_BE_TRIGGER_PIPS)
        {
         if(rec.stage != GM_TRADE_STAGE_PROFIT_50)
           {
            rec.stage = GM_TRADE_STAGE_PROFIT_50;
            dirty = true;
            structural = true;
           }
         if(m_be.Apply(rec))
           {
            m_registry.Upsert(rec, true);
            // Fall through to partial same tick
           }
         else
           {
            if(dirty)
               m_registry.Upsert(rec, structural);
            return;
           }
        }

      if(rec.be_done && !rec.partial_done)
        {
         if(m_partial.Apply(rec))
           {
            m_registry.Upsert(rec, true);
           }
         else
           {
            SyncStageFromFlags(rec);
            m_registry.Upsert(rec, true);
            return;
           }
        }

      if(rec.be_done && rec.partial_done)
        {
         if(m_trail.Update(rec))
            m_registry.Upsert(rec, true);
         else if(dirty)
           {
            SyncStageFromFlags(rec);
            m_registry.Upsert(rec, structural);
           }
        }
      else if(dirty)
        {
         SyncStageFromFlags(rec);
         m_registry.Upsert(rec, structural);
        }
     }

public:
                     CGmTradeMgmtEngine(void)
                       : m_logger(NULL), m_registry(NULL), m_ownership(NULL),
                         m_symbol(""), m_magic(0), m_ready(false) {}
                    ~CGmTradeMgmtEngine(void)
     {
      m_logger = NULL;
      m_registry = NULL;
      m_ownership = NULL;
      m_ready = false;
     }

   void Init(CGmLogger *logger,
             CGmTradeRegistry *registry,
             CGmTradeOwnership *ownership,
             const string symbol,
             const long magic)
     {
      m_logger = logger;
      m_registry = registry;
      m_ownership = ownership;
      m_symbol = symbol;
      m_magic = magic;

      m_validator.Init(logger);
      m_monitor.Init(logger, ownership, symbol, magic);
      m_be.Init(logger, GetPointer(m_validator), symbol);
      m_partial.Init(logger, GetPointer(m_validator), symbol);
      m_trail.Init(logger, GetPointer(m_validator), symbol);
      m_ready = (logger != NULL && registry != NULL && ownership != NULL);
      if(m_logger != NULL)
         m_logger.Info("Trade Management Engine ready | BE→Partial→Trail", "TradeMgmt");
     }

   /// @brief Recover management flags from registry after restart.
   void Recover(void)
     {
      if(!m_ready || m_registry == NULL)
         return;
      const int n = m_registry.Count();
      int recovered = 0;
      for(int i = 0; i < n; i++)
        {
         SGmTradeRecord rec;
         if(!m_registry.GetAt(i, rec))
            continue;
         if(rec.status != GM_TRADE_STATUS_ACTIVE)
            continue;
         if(!PositionSelectByTicket(rec.ticket))
           {
            rec.status = GM_TRADE_STATUS_CLOSED;
            rec.stage = GM_TRADE_STAGE_CLOSED;
            m_registry.Upsert(rec);
            continue;
           }
         // Ownership gate
         if(m_ownership != NULL && !m_ownership.CanManagePosition(rec.ticket, true))
            continue;
         if(rec.original_volume <= 0.0)
            rec.original_volume = PositionGetDouble(POSITION_VOLUME);
         SyncStageFromFlags(rec);
         m_registry.Upsert(rec);
         recovered++;
         if(m_logger != NULL)
            m_logger.Info(StringFormat("Recovery | ticket=%I64u BE=%s Partial=%s Trail=%s stage=%d vol=%.2f",
                                       rec.ticket,
                                       (rec.be_done ? "Y" : "N"),
                                       (rec.partial_done ? "Y" : "N"),
                                       (rec.trailing_active ? "Y" : "N"),
                                       (int)rec.stage,
                                       rec.volume),
                          "TradeMgmtRecovery");
        }
      if(m_logger != NULL)
         m_logger.Success(StringFormat("Trade Mgmt recovery complete | active=%d", recovered),
                          "TradeMgmtRecovery");
     }

   void Process(void)
     {
      if(!m_ready || m_registry == NULL)
         return;
      const int n = m_registry.Count();
      for(int i = 0; i < n; i++)
        {
         SGmTradeRecord rec;
         if(!m_registry.GetAt(i, rec))
            continue;
         ProcessOne(rec);
        }
     }
  };

#endif // GM_CTRADE_MGMT_ENGINE_MQH
//+------------------------------------------------------------------+
