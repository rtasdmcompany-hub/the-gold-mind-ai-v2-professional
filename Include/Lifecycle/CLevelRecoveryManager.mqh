//+------------------------------------------------------------------+
//|                                      CLevelRecoveryManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CLEVEL_RECOVERY_MANAGER_MQH
#define GM_CLEVEL_RECOVERY_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CLevelDatabase.mqh"
#include "CLevelStateManager.mqh"
#include "CLevelHistoryManager.mqh"
#include "../Trading/CTradeIdManager.mqh"
#include "../Calculation/SGmLevels.mqh"
#include "../Logging/CLogger.mqh"

/// @file CLevelRecoveryManager.mqh
/// @brief Restore level lifecycle state after EA / MT5 / PC / internet restart.

class CGmLevelRecoveryManager
  {
private:
   CGmLogger              *m_logger;
   CGmLevelDatabase       *m_db;
   CGmLevelStateManager   *m_state;
   CGmLevelHistoryManager *m_history;
   string                  m_symbol;
   long                    m_magic;

public:
                     CGmLevelRecoveryManager(void)
                       : m_logger(NULL), m_db(NULL), m_state(NULL),
                         m_history(NULL), m_symbol(""), m_magic(0) {}
                    ~CGmLevelRecoveryManager(void)
     {
      m_logger = NULL; m_db = NULL; m_state = NULL; m_history = NULL;
     }

   void Init(CGmLogger *logger,
             CGmLevelDatabase *db,
             CGmLevelStateManager *state,
             CGmLevelHistoryManager *history,
             const string symbol,
             const long magic)
     {
      m_logger = logger;
      m_db = db;
      m_state = state;
      m_history = history;
      m_symbol = symbol;
      m_magic = magic;
     }

   /// @brief Reconcile DB with live pendings/positions for current H4.
   /// @return true if current cycle already has recoverable infrastructure (skip duplicate place).
   bool Recover(const datetime current_h4)
     {
      if(m_db == NULL)
         return false;

      const ulong t0 = GetMicrosecondCount();
      int recovered_pending = 0;
      int recovered_running = 0;

      // Sync from live pendings
      for(int i = 0; i < OrdersTotal(); i++)
        {
         const ulong ticket = OrderGetTicket(i);
         if(ticket == 0 || !OrderSelect(ticket))
            continue;
         if((long)OrderGetInteger(ORDER_MAGIC) != m_magic)
            continue;
         if(OrderGetString(ORDER_SYMBOL) != m_symbol)
            continue;

         const string comment = OrderGetString(ORDER_COMMENT);
         const string tag_str = CGmTradeIdManager::ExtractLevelTag(comment);
         const ulong tid = CGmTradeIdManager::ExtractTradeId(comment);
         ENUM_GM_LEVEL_TAG tag = GM_TAG_BL1;
         bool found_tag = false;
         for(int t = 0; t < GM_LEVEL_COUNT; t++)
           {
            if(SGmLevels::TagToComment((ENUM_GM_LEVEL_TAG)t) == tag_str)
              {
               tag = (ENUM_GM_LEVEL_TAG)t;
               found_tag = true;
               break;
              }
           }
         if(!found_tag)
            continue;

         SGmLevelRecord rec;
         if(!m_db.GetByTag(tag, rec))
           {
            rec.Reset();
            rec.used = true;
            rec.level_id = m_db.AllocateLevelId();
            rec.magic = m_magic;
            rec.symbol = m_symbol;
            rec.tag = tag;
            rec.level_tag = tag_str;
            rec.direction = SGmLevels::TagToSide(tag);
            rec.h4_cycle_id = current_h4;
            rec.entry_price = OrderGetDouble(ORDER_PRICE_OPEN);
            rec.attempt = 1;
            rec.active_for_cycle = true;
           }

         rec.trade_id = tid;
         rec.order_ticket = ticket;
         rec.h4_cycle_id = current_h4;
         if(m_state != NULL)
            m_state.SetState(rec, GM_LVL_PENDING_PLACED, GM_LVL_EVT_RECOVERY,
                             StringFormat("Recovered pending order=%I64u", ticket));
         m_db.Upsert(rec);
         recovered_pending++;
        }

      // Sync from live positions
      for(int p = 0; p < PositionsTotal(); p++)
        {
         const ulong ticket = PositionGetTicket(p);
         if(ticket == 0 || !PositionSelectByTicket(ticket))
            continue;
         if((long)PositionGetInteger(POSITION_MAGIC) != m_magic)
            continue;
         if(PositionGetString(POSITION_SYMBOL) != m_symbol)
            continue;

         const string comment = PositionGetString(POSITION_COMMENT);
         const string tag_str = CGmTradeIdManager::ExtractLevelTag(comment);
         const ulong tid = CGmTradeIdManager::ExtractTradeId(comment);
         ENUM_GM_LEVEL_TAG tag = GM_TAG_BL1;
         bool found_tag = false;
         for(int t = 0; t < GM_LEVEL_COUNT; t++)
           {
            if(SGmLevels::TagToComment((ENUM_GM_LEVEL_TAG)t) == tag_str)
              {
               tag = (ENUM_GM_LEVEL_TAG)t;
               found_tag = true;
               break;
              }
           }
         if(!found_tag)
            continue;

         SGmLevelRecord rec;
         if(!m_db.GetByTag(tag, rec))
           {
            rec.Reset();
            rec.used = true;
            rec.level_id = m_db.AllocateLevelId();
            rec.magic = m_magic;
            rec.symbol = m_symbol;
            rec.tag = tag;
            rec.level_tag = tag_str;
            rec.direction = SGmLevels::TagToSide(tag);
            rec.h4_cycle_id = current_h4;
            rec.attempt = 1;
            rec.active_for_cycle = true;
           }

         rec.trade_id = tid;
         rec.position_ticket = ticket;
         rec.entry_price = PositionGetDouble(POSITION_PRICE_OPEN);
         rec.open_time = (datetime)PositionGetInteger(POSITION_TIME);
         rec.h4_cycle_id = current_h4;
         if(m_state != NULL)
            m_state.SetState(rec, GM_LVL_TRADE_RUNNING, GM_LVL_EVT_RECOVERY,
                             StringFormat("Recovered running trade pos=%I64u", ticket));
         m_db.Upsert(rec);
         recovered_running++;
        }

      if(m_logger != NULL)
         m_logger.Success(StringFormat("Level recovery | pendings=%d running=%d | %I64u us",
                                       recovered_pending, recovered_running,
                                       GetMicrosecondCount() - t0),
                          "LevelRecovery");

      return (recovered_pending > 0 || recovered_running > 0);
     }
  };

#endif // GM_CLEVEL_RECOVERY_MANAGER_MQH
//+------------------------------------------------------------------+
