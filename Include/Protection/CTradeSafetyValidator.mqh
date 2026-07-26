//+------------------------------------------------------------------+
//|                                     CTradeSafetyValidator.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CTRADE_SAFETY_VALIDATOR_MQH
#define GM_CTRADE_SAFETY_VALIDATOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CEventLogger.mqh"
#include "../Trading/CTradeOwnership.mqh"
#include "../Trading/CTradeRegistry.mqh"
#include "../Trading/SGmTradeRecord.mqh"

/// @file CTradeSafetyValidator.mqh
/// @brief Pre-operation trade safety gates (ownership, ID, duplicate, broker).

class CGmTradeSafetyValidator
  {
private:
   CGmEventLogger      *m_events;
   CGmTradeOwnership   *m_ownership;
   CGmTradeRegistry    *m_registry;
   long                 m_magic;
   string               m_last_reason;

   bool Fail(const string reason)
     {
      m_last_reason = reason;
      if(m_events != NULL)
         m_events.Validation("TradeSafety", reason, GM_LOG_WARNING);
      return false;
     }

public:
                     CGmTradeSafetyValidator(void)
                       : m_events(NULL),
                         m_ownership(NULL),
                         m_registry(NULL),
                         m_magic(0),
                         m_last_reason("")
     {
     }

                    ~CGmTradeSafetyValidator(void)
     {
      m_events = NULL;
      m_ownership = NULL;
      m_registry = NULL;
     }

   void Init(CGmEventLogger *events,
             CGmTradeOwnership *ownership,
             CGmTradeRegistry *registry,
             const long magic)
     {
      m_events = events;
      m_ownership = ownership;
      m_registry = registry;
      m_magic = magic;
      if(m_events != NULL)
         m_events.Trade("TradeSafety", "Trade Safety Validator ready");
     }

   string LastReason(void) const { return m_last_reason; }

   bool TradeExists(const ulong ticket)
     {
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         return Fail("Trade does not exist");
      return true;
     }

   bool MagicValid(const ulong ticket)
     {
      if(!PositionSelectByTicket(ticket))
         return Fail("Cannot read trade magic");
      const long magic = (long)PositionGetInteger(POSITION_MAGIC);
      if(magic != m_magic)
         return Fail(StringFormat("Magic mismatch | got=%I64d expect=%I64d", magic, m_magic));
      if(m_ownership != NULL && !m_ownership.CanManagePosition(ticket, true))
         return Fail("Trade does not belong to Gold Mind AI");
      return true;
     }

   bool TradeIdValid(const ulong trade_id)
     {
      if(trade_id == 0)
         return Fail("Trade ID invalid (0)");
      if(m_registry != NULL)
        {
         SGmTradeRecord rec;
         if(!m_registry.GetByTradeId(trade_id, rec))
            return Fail(StringFormat("Trade ID not in registry | TID=%I64u", trade_id));
        }
      return true;
     }

   bool NotAlreadyClosed(const ulong ticket)
     {
      if(m_registry != NULL)
        {
         SGmTradeRecord rec;
         if(m_registry.GetByTicket(ticket, rec))
           {
            if(rec.status == GM_TRADE_STATUS_CLOSED || rec.status == GM_TRADE_STATUS_CANCELLED)
               return Fail("Trade already closed in registry");
           }
        }
      if(!PositionSelectByTicket(ticket))
         return Fail("Trade already closed on terminal");
      return true;
     }

   bool BrokerAllowsModification(void)
     {
      if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED))
         return Fail("Broker/terminal does not accept modification");
      if(!TerminalInfoInteger(TERMINAL_CONNECTED))
         return Fail("No broker connection for modification");
      return true;
     }

   /// @brief Full pre-modify / pre-manage safety suite.
   bool CanManageTrade(const ulong ticket, const ulong trade_id = 0)
     {
      m_last_reason = "";
      if(!TradeExists(ticket)) return false;
      if(!MagicValid(ticket)) return false;
      if(trade_id > 0 && !TradeIdValid(trade_id)) return false;
      if(!NotAlreadyClosed(ticket)) return false;
      if(!BrokerAllowsModification()) return false;
      return true;
     }
  };

#endif // GM_CTRADE_SAFETY_VALIDATOR_MQH
//+------------------------------------------------------------------+
