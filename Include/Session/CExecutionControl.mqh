//+------------------------------------------------------------------+
//|                                       CExecutionControl.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CEXECUTION_CONTROL_MQH
#define GM_CEXECUTION_CONTROL_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CSessionAudit.mqh"
#include "../Trading/CTradeOwnership.mqh"
#include "../Trading/CTradeIdManager.mqh"
#include "../Trading/CTradeRegistry.mqh"
#include "../Core/TradingRules.mqh"

/// @file CExecutionControl.mqh
/// @brief Prevents duplicate pendings / markets / levels / trade IDs / sessions / magic.

class CGmExecutionControl
  {
private:
   CGmLogger           *m_logger;
   CGmSessionAudit     *m_audit;
   CGmTradeOwnership   *m_ownership;
   CGmTradeRegistry    *m_registry;
   long                 m_magic;
   string               m_symbol;
   ulong                m_active_session_id;
   string               m_last_reason;
   bool                 m_ready;

   bool Fail(const string reason)
     {
      m_last_reason = reason;
      if(m_logger != NULL)
         m_logger.Warning("ExecutionControl FAIL | " + reason, "ExecControl");
      if(m_audit != NULL)
         m_audit.Record(GM_AUDIT_ERROR, "ExecControl", reason, m_active_session_id);
      return false;
     }

public:
                     CGmExecutionControl(void)
                       : m_logger(NULL), m_audit(NULL), m_ownership(NULL), m_registry(NULL),
                         m_magic(0), m_symbol(""), m_active_session_id(0),
                         m_last_reason(""), m_ready(false)
     {
     }

                    ~CGmExecutionControl(void)
     {
      m_logger = NULL;
      m_audit = NULL;
      m_ownership = NULL;
      m_registry = NULL;
     }

   void Init(CGmLogger *logger,
             CGmSessionAudit *audit,
             CGmTradeOwnership *ownership,
             CGmTradeRegistry *registry,
             const long magic,
             const string symbol)
     {
      m_logger = logger;
      m_audit = audit;
      m_ownership = ownership;
      m_registry = registry;
      m_magic = magic;
      m_symbol = symbol;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Execution Control Engine ready", "ExecControl");
     }

   void SetActiveSessionId(const ulong sid) { m_active_session_id = sid; }
   string LastReason(void) const { return m_last_reason; }

   bool ValidateMagic(void)
     {
      if(m_magic == GM_MAGIC_MANUAL_TRADE || m_magic == 0)
         return Fail("Invalid / duplicate-risk Magic Number (manual/zero)");
      if(m_ownership != NULL && !m_ownership.CanManageMagic(m_magic))
         return Fail("Magic Number ownership rejected");
      return true;
     }

   bool ValidateNewSessionId(const ulong session_id)
     {
      if(session_id == 0)
         return Fail("Session ID invalid (0)");
      if(m_active_session_id != 0 && session_id == m_active_session_id)
         return Fail(StringFormat("Duplicate Session ID | SID=%I64u", session_id));
      return true;
     }

   bool ValidateTradeIdUnique(const ulong trade_id)
     {
      if(trade_id == 0)
         return Fail("Trade ID invalid (0)");
      if(m_registry != NULL)
        {
         SGmTradeRecord rec;
         if(m_registry.GetByTradeId(trade_id, rec))
            return Fail(StringFormat("Duplicate Trade ID | TID=%I64u", trade_id));
        }
      return true;
     }

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

   bool ValidateNoDuplicatePending(const string level_tag)
     {
      if(HasOwnPendingForTag(level_tag))
         return Fail(StringFormat("Duplicate Pending Order | tag=%s", level_tag));
      return true;
     }

   bool ValidateNoDuplicateMarket(const string level_tag)
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
            return Fail(StringFormat("Duplicate Market Order | tag=%s ticket=%I64u",
                                     level_tag, ticket));
        }
      return true;
     }

   /// @brief Full pre-placement execution validation.
   bool CanPlacePending(const string level_tag)
     {
      m_last_reason = "";
      if(!m_ready)
         return Fail("Execution Control not ready");
      if(!ValidateMagic()) return false;
      if(!ValidateNoDuplicatePending(level_tag)) return false;
      // Market duplicate for same tag: warn-level — allow pending if no market for reactivation paths
      // but block if BOTH pending and market would conflict on initial place.
      return true;
     }

   bool CanCreateSession(const ulong session_id)
     {
      m_last_reason = "";
      if(!ValidateMagic()) return false;
      if(!ValidateNewSessionId(session_id)) return false;
      return true;
     }
  };

#endif // GM_CEXECUTION_CONTROL_MQH
//+------------------------------------------------------------------+
