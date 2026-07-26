//+------------------------------------------------------------------+
//|                                              CRecoveryBase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CRECOVERY_BASE_MQH
#define GM_CRECOVERY_BASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../Core/EnumsCore.mqh"
#include "../Core/TradingRules.mqh"
#include "../Logging/CLogger.mqh"
#include "../Trading/CTradeOwnership.mqh"

/// @file CRecoveryBase.mqh
/// @brief Recovery Engine base — safe state restore after restart / reconnect.
/// @details Responsibilities (future):
///          - Detect existing Gold Mind trades via Magic Number
///          - Restore internal cycle state
///          - Prevent duplicate pending orders / positions
///          - Never touch foreign or manual trades
///          Sprint 1: framework scan hooks only.

//+------------------------------------------------------------------+
//| SGmRecoverySnapshot                                              |
//+------------------------------------------------------------------+
struct SGmRecoverySnapshot
  {
   int      own_positions;
   int      own_pendings;
   bool     state_restored;
   bool     duplicates_blocked;
   datetime scanned_at;
  };

//+------------------------------------------------------------------+
//| CGmRecoveryBase                                                  |
//+------------------------------------------------------------------+
class CGmRecoveryBase
  {
protected:
   CGmLogger            *m_logger;
   CGmTradeOwnership    *m_ownership;
   ENUM_GM_MODULE_STATUS m_status;
   string                m_module_name;
   SGmRecoverySnapshot   m_last_snapshot;

public:
                     CGmRecoveryBase(void)
                       : m_logger(NULL),
                         m_ownership(NULL),
                         m_status(GM_MODULE_DISABLED),
                         m_module_name("RecoveryEngine")
     {
      ZeroMemory(m_last_snapshot);
     }

   virtual          ~CGmRecoveryBase(void)
     {
      m_logger = NULL;
      m_ownership = NULL;
     }

   virtual bool Init(CGmLogger *logger, CGmTradeOwnership *ownership)
     {
      m_logger = logger;
      m_ownership = ownership;
      m_status = GM_MODULE_IDLE;
      ZeroMemory(m_last_snapshot);

      if(m_logger != NULL)
         m_logger.Info("Recovery Engine base ready | safe_recovery | no_duplicate_pendings | no_duplicate_positions",
                       m_module_name);
      return true;
     }

   virtual void Shutdown(void) { m_status = GM_MODULE_DISABLED; }

   ENUM_GM_MODULE_STATUS Status(void) const { return m_status; }
   SGmRecoverySnapshot LastSnapshot(void) const { return m_last_snapshot; }
   string ModuleName(void) const { return m_module_name; }

   /// @brief Framework recovery scan — counts own tickets; no order mutations.
   /// @return true when scan completes (full restore logic in later sprint).
   virtual bool RecoverState(void)
     {
      ZeroMemory(m_last_snapshot);
      m_last_snapshot.scanned_at = TimeCurrent();
      m_last_snapshot.duplicates_blocked = (GM_POLICY_NO_DUPLICATE_PENDINGS == 1);

      if(m_ownership == NULL || !m_ownership.IsInitialized())
        {
         if(m_logger != NULL)
            m_logger.Warning("Recovery skipped — ownership gate not ready", m_module_name);
         return false;
        }

      m_last_snapshot.own_positions = m_ownership.CountOwnPositions();
      m_last_snapshot.own_pendings  = m_ownership.CountOwnPendingOrders();
      m_last_snapshot.state_restored = true; // inventory observed; cycle restore later

      if(m_logger != NULL)
         m_logger.Info(StringFormat("Recovery scan | own_positions=%d | own_pendings=%d | no_duplicate_policy=ON",
                                    m_last_snapshot.own_positions,
                                    m_last_snapshot.own_pendings),
                       m_module_name);

      m_status = GM_MODULE_READY;
      return true;
     }

   /// @brief Future: decide if a new pending may be placed without duplication.
   virtual bool MayPlacePending(void) const
     {
      // Sprint 1: conservative — block until Orders sprint implements fingerprinting.
      return false;
     }
  };

#endif // GM_CRECOVERY_BASE_MQH
//+------------------------------------------------------------------+
