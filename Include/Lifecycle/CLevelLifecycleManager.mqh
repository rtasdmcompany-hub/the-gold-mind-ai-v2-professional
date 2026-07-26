//+------------------------------------------------------------------+
//|                                    CLevelLifecycleManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CLEVEL_LIFECYCLE_MANAGER_MQH
#define GM_CLEVEL_LIFECYCLE_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CLevelDatabase.mqh"
#include "CLevelStateManager.mqh"
#include "CLevelValidationManager.mqh"
#include "../Calculation/SGmLevels.mqh"
#include "../Calculation/LevelConstants.mqh"
#include "../Logging/CLogger.mqh"

/// @file CLevelLifecycleManager.mqh
/// @brief First-SL / Second-SL / TP lifecycle transitions.

class CGmLevelLifecycleManager
  {
private:
   CGmLogger                 *m_logger;
   CGmLevelDatabase          *m_db;
   CGmLevelStateManager      *m_state;
   CGmLevelValidationManager *m_validation;
   datetime                   m_h4_cycle;

public:
                     CGmLevelLifecycleManager(void)
                       : m_logger(NULL), m_db(NULL), m_state(NULL),
                         m_validation(NULL), m_h4_cycle(0) {}
                    ~CGmLevelLifecycleManager(void)
     {
      m_logger = NULL; m_db = NULL; m_state = NULL; m_validation = NULL;
     }

   void Init(CGmLogger *logger,
             CGmLevelDatabase *db,
             CGmLevelStateManager *state,
             CGmLevelValidationManager *validation)
     {
      m_logger = logger;
      m_db = db;
      m_state = state;
      m_validation = validation;
     }

   void SetH4Cycle(const datetime cycle) { m_h4_cycle = cycle; }
   datetime H4Cycle(void) const { return m_h4_cycle; }

   bool CreateCycleLevels(const SGmLevels &levels, const long magic, const string symbol)
     {
      if(m_db == NULL || m_state == NULL || !levels.valid)
         return false;

      m_h4_cycle = levels.h4_bar_time;
      m_db.ExpireAll();
      m_db.ClearSlots();

      for(int t = 0; t < GM_LEVEL_COUNT; t++)
        {
         const ENUM_GM_LEVEL_TAG tag = (ENUM_GM_LEVEL_TAG)t;
         SGmLevelRecord rec;
         rec.Reset();
         rec.used = true;
         rec.level_id = m_db.AllocateLevelId();
         rec.magic = magic;
         rec.symbol = symbol;
         rec.tag = tag;
         rec.level_tag = SGmLevels::TagToComment(tag);
         rec.direction = SGmLevels::TagToSide(tag);
         rec.h4_cycle_id = levels.h4_bar_time;
         rec.entry_price = levels.PriceByTag(tag);
         rec.attempt = 0;
         rec.state = GM_LVL_WAITING;
         rec.active_for_cycle = true;
         m_state.SetState(rec, GM_LVL_WAITING, GM_LVL_EVT_CREATED,
                          StringFormat("Level created @ %.5f", rec.entry_price));
         m_db.Upsert(rec);
         if(m_logger != NULL)
            m_logger.Success(StringFormat("Level Created | %s | LID=%I64u | entry=%.5f",
                                          rec.level_tag, rec.level_id, rec.entry_price),
                             "Lifecycle");
        }
      return true;
     }

   void OnPendingPlaced(const ENUM_GM_LEVEL_TAG tag,
                        const ulong trade_id,
                        const ulong order_ticket,
                        const int attempt)
     {
      SGmLevelRecord rec;
      if(m_db == NULL || !m_db.GetByTag(tag, rec))
         return;
      rec.trade_id = trade_id;
      rec.order_ticket = order_ticket;
      rec.attempt = attempt;
      rec.open_time = TimeCurrent();
      const ENUM_GM_LEVEL_STATE st =
         (attempt >= 2) ? GM_LVL_REACTIVATED : GM_LVL_PENDING_PLACED;
      m_state.SetState(rec, st,
                       (attempt >= 2) ? GM_LVL_EVT_REACTIVATED : GM_LVL_EVT_PENDING_PLACED,
                       StringFormat("Pending placed | TID=%I64u order=%I64u attempt=%d",
                                    trade_id, order_ticket, attempt));
      m_db.Upsert(rec);
     }

   void OnTradeActivated(const ENUM_GM_LEVEL_TAG tag,
                         const ulong trade_id,
                         const ulong position_ticket,
                         const double entry)
     {
      SGmLevelRecord rec;
      if(m_db == NULL)
         return;
      if(!m_db.GetByTag(tag, rec) && !m_db.GetByTradeId(trade_id, rec))
         return;

      rec.trade_id = trade_id;
      rec.position_ticket = position_ticket;
      rec.entry_price = entry;
      rec.order_ticket = 0;
      m_state.SetState(rec, GM_LVL_TRADE_ACTIVATED, GM_LVL_EVT_ACTIVATED,
                       StringFormat("Trade activated | pos=%I64u", position_ticket));
      m_state.SetState(rec, GM_LVL_TRADE_RUNNING, GM_LVL_EVT_RUNNING, "Trade running");
      m_db.Upsert(rec);
      if(m_logger != NULL)
         m_logger.Success(StringFormat("Trade Activated | %s | LID=%I64u | TID=%I64u",
                                       rec.level_tag, rec.level_id, trade_id),
                          "Lifecycle");
     }

   /// @return 1 if First-SL reactivation should be executed by LevelManager.
   int OnTradeClosed(const ENUM_GM_LEVEL_TAG tag,
                     const ulong trade_id,
                     const bool is_tp,
                     const bool is_sl,
                     const double pnl)
     {
      const ulong t0 = GetMicrosecondCount();
      SGmLevelRecord rec;
      if(m_db == NULL || (!m_db.GetByTag(tag, rec) && !m_db.GetByTradeId(trade_id, rec)))
         return 0;

      rec.close_time = TimeCurrent();
      rec.position_ticket = 0;
      if(pnl >= 0.0) { rec.profit = pnl; rec.loss = 0.0; }
      else { rec.loss = -pnl; rec.profit = 0.0; }

      if(is_tp)
        {
         m_state.SetState(rec, GM_LVL_TP_HIT, GM_LVL_EVT_TP, "Take Profit — SUCCESSFUL");
         m_state.SetState(rec, GM_LVL_COMPLETED, GM_LVL_EVT_COMPLETED,
                          "Deactivated for current H4");
         m_db.Upsert(rec);
         if(m_logger != NULL)
            m_logger.Success(StringFormat("Take Profit | %s | LID=%I64u | %I64u us",
                                          rec.level_tag, rec.level_id,
                                          GetMicrosecondCount() - t0),
                             "Lifecycle");
         return 0;
        }

      if(!is_sl)
        {
         m_state.SetState(rec, GM_LVL_COMPLETED, GM_LVL_EVT_COMPLETED,
                          "Closed without SL/TP — deactivated");
         m_db.Upsert(rec);
         return 0;
        }

      if(rec.attempt <= 1)
        {
         m_state.SetState(rec, GM_LVL_SL_FIRST, GM_LVL_EVT_SL_FIRST,
                          "FIRST SL COMPLETED");
         m_db.Upsert(rec);
         if(m_logger != NULL)
            m_logger.Warning(StringFormat("First Stop Loss | %s | LID=%I64u",
                                          rec.level_tag, rec.level_id),
                             "Lifecycle");
         return 1;
        }

      m_state.SetState(rec, GM_LVL_SL_SECOND, GM_LVL_EVT_SL_SECOND, "Second Stop Loss");
      m_state.SetState(rec, GM_LVL_FAILED, GM_LVL_EVT_FAILED,
                       "FAILED — never activate again this H4");
      m_db.Upsert(rec);
      if(m_logger != NULL)
         m_logger.Error(StringFormat("Second Stop Loss | %s | LID=%I64u | FAILED",
                                     rec.level_tag, rec.level_id),
                        "Lifecycle");
      return 0;
     }

   bool PrepareReactivation(SGmLevelRecord &rec)
     {
      if(m_validation == NULL || !m_validation.CanReactivate(rec, m_h4_cycle))
         return false;
      rec.attempt = 2;
      m_state.SetState(rec, GM_LVL_REACTIVATED, GM_LVL_EVT_REACTIVATED,
                       "Attempt=2 — same original level");
      m_db.Upsert(rec);
      return true;
     }

   bool ShouldSkipPlacement(const ENUM_GM_LEVEL_TAG tag) const
     {
      SGmLevelRecord rec;
      if(m_db == NULL || !m_db.GetByTag(tag, rec))
         return false;
      return (!rec.active_for_cycle ||
              rec.state == GM_LVL_COMPLETED ||
              rec.state == GM_LVL_FAILED ||
              rec.state == GM_LVL_EXPIRED ||
              rec.state == GM_LVL_TP_HIT ||
              rec.state == GM_LVL_PENDING_PLACED ||
              rec.state == GM_LVL_TRADE_RUNNING ||
              rec.state == GM_LVL_TRADE_ACTIVATED);
     }

   int DesiredAttempt(const ENUM_GM_LEVEL_TAG tag) const
     {
      SGmLevelRecord rec;
      if(m_db == NULL || !m_db.GetByTag(tag, rec))
         return 1;
      if(rec.state == GM_LVL_SL_FIRST || rec.state == GM_LVL_REACTIVATED)
         return 2;
      if(rec.attempt < 1)
         return 1;
      return rec.attempt;
     }

   double LockedEntryPrice(const ENUM_GM_LEVEL_TAG tag, const double fallback) const
     {
      SGmLevelRecord rec;
      if(m_db != NULL && m_db.GetByTag(tag, rec) && rec.entry_price > 0.0)
         return rec.entry_price;
      return fallback;
     }

   bool GetRecord(const ENUM_GM_LEVEL_TAG tag, SGmLevelRecord &out) const
     {
      return (m_db != NULL && m_db.GetByTag(tag, out));
     }
  };

#endif // GM_CLEVEL_LIFECYCLE_MANAGER_MQH
//+------------------------------------------------------------------+
