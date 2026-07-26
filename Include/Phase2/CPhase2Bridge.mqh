//+------------------------------------------------------------------+
//|                                            CPhase2Bridge.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CPHASE2_BRIDGE_MQH
#define GM_CPHASE2_BRIDGE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "IPhase2Interfaces.mqh"
#include "../Core/ArchitectureFreeze.mqh"
#include "../Logging/CLogger.mqh"
#include "../Trading/CTradeOwnership.mqh"
#include "../Trading/CTradeRegistry.mqh"
#include "../Lifecycle/CLevelManager.mqh"
#include "../Session/CH4SessionEngine.mqh"
#include "../Protection/CCapitalProtectionEngine.mqh"
#include "../Protection/SGmAccountSnapshot.mqh"
#include "../Protection/SGmDrawdownState.mqh"
#include "../Calculation/CLevelEngine.mqh"

/// @file CPhase2Bridge.mqh
/// @brief Read-only Core API surface for Phase 2 AI / Analytics / Dashboard.
/// @details Never mutates strategy math. Never manages foreign Magics.

class CGmPhase2Bridge
  {
private:
   CGmLogger                  *m_logger;
   CGmTradeOwnership          *m_ownership;
   CGmTradeRegistry           *m_registry;
   CGmLevelManager            *m_levels;
   CGmH4SessionEngine         *m_session;
   CGmCapitalProtectionEngine *m_protection;
   CGmLevelEngine             *m_calc;
   long                        m_magic;
   string                      m_symbol;
   bool                        m_ready;

public:
                     CGmPhase2Bridge(void)
                       : m_logger(NULL), m_ownership(NULL), m_registry(NULL),
                         m_levels(NULL), m_session(NULL), m_protection(NULL),
                         m_calc(NULL), m_magic(0), m_symbol(""), m_ready(false)
     {
     }

                    ~CGmPhase2Bridge(void)
     {
      m_logger = NULL;
      m_ownership = NULL;
      m_registry = NULL;
      m_levels = NULL;
      m_session = NULL;
      m_protection = NULL;
      m_calc = NULL;
     }

   bool Init(CGmLogger *logger,
             CGmTradeOwnership *ownership,
             CGmTradeRegistry *registry,
             CGmLevelManager *levels,
             CGmH4SessionEngine *session,
             CGmCapitalProtectionEngine *protection,
             CGmLevelEngine *calc,
             const string symbol,
             const long magic)
     {
      m_logger = logger;
      m_ownership = ownership;
      m_registry = registry;
      m_levels = levels;
      m_session = session;
      m_protection = protection;
      m_calc = calc;
      m_symbol = symbol;
      m_magic = magic;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Phase 2 Bridge ready | read-only Core APIs | " + GmArchitectureFreezeBanner(),
                       "Phase2Bridge");
      return true;
     }

   //--- Identity (ownership gate)
   long Magic(void) const { return m_magic; }
   string Symbol(void) const { return m_symbol; }
   bool IsOwnPosition(const ulong ticket) const
     {
      return (m_ownership != NULL && m_ownership.CanManagePosition(ticket, true));
     }

   //--- Session / levels / registry (read-only snapshots)
   ulong SessionId(void) const
     {
      return (m_session != NULL) ? m_session.CurrentSessionId() : 0;
     }

   datetime H4Cycle(void) const
     {
      return (m_levels != NULL) ? m_levels.H4Cycle() : 0;
     }

   int RegistryCount(void) const
     {
      return (m_registry != NULL) ? m_registry.Count() : 0;
     }

   int OwnPositions(void) const
     {
      return (m_ownership != NULL) ? m_ownership.CountOwnPositions() : 0;
     }

   int OwnPendings(void) const
     {
      return (m_ownership != NULL) ? m_ownership.CountOwnPendingOrders() : 0;
     }

   bool GetTrade(const ulong trade_id, SGmTradeRecord &out) const
     {
      return (m_registry != NULL && m_registry.GetByTradeId(trade_id, out));
     }

   bool GetRegistryAt(const int index, SGmTradeRecord &out) const
     {
      return (m_registry != NULL && m_registry.GetAt(index, out));
     }

   bool ProtectionReady(void) const
     {
      return (m_protection != NULL && m_protection.IsReady());
     }

   /// @brief Read-only account snapshot from Capital Protection monitor.
   bool ReadAccount(SGmAccountSnapshot &out) const
     {
      out.Reset();
      if(m_protection == NULL || m_protection.Account() == NULL)
         return false;
      out = m_protection.Account().Copy();
      return out.valid;
     }

   /// @brief Read-only drawdown state from Capital Protection.
   bool ReadDrawdown(SGmDrawdownState &out) const
     {
      out.Reset();
      if(m_protection == NULL || m_protection.Drawdown() == NULL)
         return false;
      out = m_protection.Drawdown().State();
      return out.valid;
     }

   /// @brief Recalculate levels for AI observation — does not place orders.
   bool PeekLevels(SGmLevels &out)
     {
      out.Reset();
      if(m_calc == NULL)
         return false;
      m_calc.SetSymbol(m_symbol);
      if(!m_calc.Recalculate())
         return false;
      out = m_calc.GetLevelsCopy();
      return out.valid;
     }

   bool CoreFrozen(void) const { return (GM_CORE_ARCHITECTURE_FROZEN == 1); }
  };

#endif // GM_CPHASE2_BRIDGE_MQH
//+------------------------------------------------------------------+
