//+------------------------------------------------------------------+
//|                                    CLevelValidationManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CLEVEL_VALIDATION_MANAGER_MQH
#define GM_CLEVEL_VALIDATION_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmLevelRecord.mqh"
#include "../Logging/CLogger.mqh"
#include "../Trading/CTradeIdManager.mqh"

/// @file CLevelValidationManager.mqh
/// @brief Pre-reactivation / placement validation gates.

class CGmLevelValidationManager
  {
private:
   CGmLogger *m_logger;
   string     m_symbol;
   long       m_magic;
   string     m_last_reason;

   bool Fail(const string reason)
     {
      m_last_reason = reason;
      if(m_logger != NULL)
         m_logger.Warning("Level validation FAIL | " + reason, "LevelValidation");
      return false;
     }

public:
                     CGmLevelValidationManager(void)
                       : m_logger(NULL), m_symbol(""), m_magic(0), m_last_reason("") {}
                    ~CGmLevelValidationManager(void) { m_logger = NULL; }

   void Init(CGmLogger *logger, const string symbol, const long magic)
     {
      m_logger = logger;
      m_symbol = symbol;
      m_magic = magic;
     }

   string LastReason(void) const { return m_last_reason; }

   bool HasOwnPendingForTag(const string level_tag) const
     {
      const int total = OrdersTotal();
      for(int i = 0; i < total; i++)
        {
         const ulong ticket = OrderGetTicket(i);
         if(ticket == 0 || !OrderSelect(ticket))
            continue;
         if((long)OrderGetInteger(ORDER_MAGIC) != m_magic)
            continue;
         if(OrderGetString(ORDER_SYMBOL) != m_symbol)
            continue;
         if(CGmTradeIdManager::ExtractLevelTag(OrderGetString(ORDER_COMMENT)) == level_tag)
            return true;
        }
      return false;
     }

   bool HasOwnRunningTradeForTag(const string level_tag) const
     {
      const int total = PositionsTotal();
      for(int i = 0; i < total; i++)
        {
         const ulong ticket = PositionGetTicket(i);
         if(ticket == 0 || !PositionSelectByTicket(ticket))
            continue;
         if((long)PositionGetInteger(POSITION_MAGIC) != m_magic)
            continue;
         if(PositionGetString(POSITION_SYMBOL) != m_symbol)
            continue;
         if(CGmTradeIdManager::ExtractLevelTag(PositionGetString(POSITION_COMMENT)) == level_tag)
            return true;
        }
      return false;
     }

   /// @brief Full gate before recreating a level after First SL.
   bool CanReactivate(const SGmLevelRecord &rec, const datetime current_h4)
     {
      m_last_reason = "";
      if(!rec.used)
         return Fail("Level record unused");
      if(rec.level_id == 0)
         return Fail("Invalid Level ID");
      if(rec.h4_cycle_id != current_h4)
         return Fail("Level not in current H4 cycle");
      if(rec.state != GM_LVL_SL_FIRST && rec.state != GM_LVL_REACTIVATED)
         return Fail(StringFormat("Invalid state for reactivation | %s",
                                  SGmLevelRecord::StateToString(rec.state)));
      if(rec.attempt >= GM_LEVEL_MAX_ATTEMPTS)
         return Fail("Attempt counter already at max");
      if(HasOwnPendingForTag(rec.level_tag))
         return Fail("Pending already exists for level");
      if(HasOwnRunningTradeForTag(rec.level_tag))
         return Fail("Trade already running for level");

      if(m_logger != NULL)
         m_logger.Info(StringFormat("Validation OK for reactivation | %s | LID=%I64u",
                                    rec.level_tag, rec.level_id),
                       "LevelValidation");
      return true;
     }

   bool CanPlaceInitial(const SGmLevelRecord &rec, const datetime current_h4)
     {
      m_last_reason = "";
      if(!rec.used)
         return Fail("Level unused");
      if(rec.h4_cycle_id != current_h4)
         return Fail("Wrong H4 cycle");
      if(rec.state != GM_LVL_WAITING)
         return Fail("Not WAITING");
      if(HasOwnPendingForTag(rec.level_tag))
         return Fail("Pending exists");
      if(HasOwnRunningTradeForTag(rec.level_tag))
         return Fail("Trade running");
      return true;
     }
  };

#endif // GM_CLEVEL_VALIDATION_MANAGER_MQH
//+------------------------------------------------------------------+
