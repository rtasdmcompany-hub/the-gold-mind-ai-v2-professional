//+------------------------------------------------------------------+
//|                                           CSecurityGuard.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CSECURITY_GUARD_MQH
#define GM_CSECURITY_GUARD_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ProductionConstants.mqh"
#include "CEnterpriseLogContext.mqh"
#include "../Session/CExecutionControl.mqh"
#include "../Trading/CTradeRegistry.mqh"
#include "../Trading/CTradeOwnership.mqh"
#include "../Core/TradingRules.mqh"

/// @file CSecurityGuard.mqh
/// @brief Security validation — duplicates, invalid tickets, race cooldown.

class CGmSecurityGuard
  {
private:
   CGmLogger               *m_logger;
   CGmEnterpriseLogContext *m_elog;
   CGmExecutionControl     *m_exec;
   CGmTradeRegistry        *m_registry;
   CGmTradeOwnership       *m_ownership;
   long                     m_magic;
   string                   m_symbol;
   bool                     m_enabled;
   ulong                    m_last_action_ms;
   string                   m_last_action_key;
   string                   m_last_reason;

   bool Fail(const string reason)
     {
      m_last_reason = reason;
      if(m_elog != NULL)
         m_elog.Emit(GM_LOG_WARNING, "Security", reason, 0, 0, 0, -1, "Reject action");
      else if(m_logger != NULL)
         m_logger.Warning("Security | " + reason, "Security");
      return false;
     }

public:
                     CGmSecurityGuard(void)
                       : m_logger(NULL), m_elog(NULL), m_exec(NULL), m_registry(NULL),
                         m_ownership(NULL), m_magic(0), m_symbol(""),
                         m_enabled(true), m_last_action_ms(0), m_last_action_key(""),
                         m_last_reason("")
     {
     }

                    ~CGmSecurityGuard(void)
     {
      m_logger = NULL;
      m_elog = NULL;
      m_exec = NULL;
      m_registry = NULL;
      m_ownership = NULL;
     }

   void Init(CGmLogger *logger,
             CGmEnterpriseLogContext *elog,
             CGmExecutionControl *exec,
             CGmTradeRegistry *registry,
             CGmTradeOwnership *ownership,
             const long magic,
             const string symbol,
             const bool enabled)
     {
      m_logger = logger;
      m_elog = elog;
      m_exec = exec;
      m_registry = registry;
      m_ownership = ownership;
      m_magic = magic;
      m_symbol = symbol;
      m_enabled = enabled;
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Security Guard ready | enabled=%s", enabled ? "Y" : "N"),
                       "Security");
     }

   string LastReason(void) const { return m_last_reason; }

   bool ValidateTicket(const ulong ticket)
     {
      if(!m_enabled)
         return true;
      if(ticket == 0)
         return Fail("Invalid Ticket Reference (0)");
      if(!PositionSelectByTicket(ticket) && !OrderSelect(ticket))
         return Fail(StringFormat("Invalid Ticket Reference | ticket=%I64u", ticket));
      return true;
     }

   bool ValidateMagic(void)
     {
      if(!m_enabled)
         return true;
      if(m_magic == 0 || m_magic == GM_MAGIC_MANUAL_TRADE)
         return Fail("Invalid / duplicate-risk Magic Number");
      if(m_ownership != NULL && !m_ownership.CanManageMagic(m_magic))
         return Fail("Magic ownership rejected");
      return true;
     }

   bool AntiRace(const string action_key)
     {
      if(!m_enabled)
         return true;
      const ulong now = GetTickCount();
      if(action_key == m_last_action_key &&
         (now - m_last_action_ms) < GM_PROD_ACTION_COOLDOWN_MS)
         return Fail(StringFormat("Race Condition guard | action=%s", action_key));
      m_last_action_key = action_key;
      m_last_action_ms = now;
      return true;
     }

   bool CanPlacePending(const string level_tag)
     {
      m_last_reason = "";
      if(!m_enabled)
         return true;
      if(!ValidateMagic())
         return false;
      if(!AntiRace("place:" + level_tag))
         return false;
      if(m_exec != NULL && !m_exec.CanPlacePending(level_tag))
        {
         m_last_reason = m_exec.LastReason();
         return false;
        }
      return true;
     }

   bool ValidateRegistryIntegrity(void)
     {
      if(!m_enabled || m_registry == NULL)
         return true;
      const int n = m_registry.Count();
      for(int i = 0; i < n; i++)
        {
         SGmTradeRecord a;
         if(!m_registry.GetAt(i, a) || !a.used)
            continue;
         if(a.trade_id == 0)
            return Fail("Corrupted Internal State | Trade ID 0");
         if(a.magic != m_magic)
            return Fail("Corrupted Internal State | foreign magic in registry");
         for(int j = i + 1; j < n; j++)
           {
            SGmTradeRecord b;
            if(!m_registry.GetAt(j, b) || !b.used)
               continue;
            if(a.trade_id == b.trade_id)
               return Fail(StringFormat("Duplicate Trade ID | %I64u", a.trade_id));
           }
        }
      return true;
     }

   bool HandleBrokerResponse(const uint retcode, const string context)
     {
      if(retcode == TRADE_RETCODE_DONE || retcode == TRADE_RETCODE_PLACED ||
         retcode == TRADE_RETCODE_DONE_PARTIAL)
         return true;
      if(m_elog != NULL)
         m_elog.Emit(GM_LOG_WARNING, "Security",
                     StringFormat("Unexpected Broker Response | %s ret=%u", context, retcode),
                     0, 0, 0, (int)retcode, "Retry/backoff via engine loops");
      return false;
     }
  };

#endif // GM_CSECURITY_GUARD_MQH
//+------------------------------------------------------------------+
