//+------------------------------------------------------------------+
//|                                            CFailSafeEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CFAIL_SAFE_ENGINE_MQH
#define GM_CFAIL_SAFE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ProductionConstants.mqh"
#include "CEnterpriseLogContext.mqh"
#include "../Logging/CLogger.mqh"

/// @file CFailSafeEngine.mqh
/// @brief Fail-safe gates — disconnect, trading disabled, low margin/memory.

enum ENUM_GM_FAILSAFE_STATE
  {
   GM_FS_OK = 0,
   GM_FS_DEGRADED,
   GM_FS_BLOCK_NEW_ORDERS,
   GM_FS_HALTED
  };

class CGmFailSafeEngine
  {
private:
   CGmLogger               *m_logger;
   CGmEnterpriseLogContext *m_elog;
   ENUM_GM_FAILSAFE_STATE   m_state;
   string                   m_reason;
   datetime                 m_last_check;
   bool                     m_enabled;
   bool                     m_ready;

   void SetState(const ENUM_GM_FAILSAFE_STATE st, const string reason, const string recovery)
     {
      if(m_state == st && m_reason == reason)
         return;
      m_state = st;
      m_reason = reason;
      if(m_elog != NULL)
         m_elog.Emit((st == GM_FS_OK) ? GM_LOG_SUCCESS : GM_LOG_WARNING,
                     "FailSafe", reason, 0, 0, 0, 0, recovery);
      else if(m_logger != NULL)
         m_logger.Warning("FailSafe | " + reason + " | " + recovery, "FailSafe");
     }

public:
                     CGmFailSafeEngine(void)
                       : m_logger(NULL), m_elog(NULL), m_state(GM_FS_OK),
                         m_reason(""), m_last_check(0), m_enabled(true), m_ready(false)
     {
     }

                    ~CGmFailSafeEngine(void) { m_logger = NULL; m_elog = NULL; }

   void Init(CGmLogger *logger, CGmEnterpriseLogContext *elog, const bool enabled)
     {
      m_logger = logger;
      m_elog = elog;
      m_enabled = enabled;
      m_ready = true;
      m_state = GM_FS_OK;
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Fail Safe Engine ready | enabled=%s", enabled ? "Y" : "N"),
                       "FailSafe");
     }

   ENUM_GM_FAILSAFE_STATE State(void) const { return m_state; }
   string Reason(void) const { return m_reason; }
   bool IsOk(void) const { return (!m_enabled || m_state == GM_FS_OK || m_state == GM_FS_DEGRADED); }

   /// @brief New pending placement allowed?
   bool CanPlaceNewOrders(void) const
     {
      if(!m_enabled)
         return true;
      return (m_state == GM_FS_OK || m_state == GM_FS_DEGRADED);
     }

   void Process(void)
     {
      if(!m_ready || !m_enabled)
         return;
      if(TimeCurrent() == m_last_check)
         return;
      m_last_check = TimeCurrent();

      if(!TerminalInfoInteger(TERMINAL_CONNECTED))
        {
         SetState(GM_FS_BLOCK_NEW_ORDERS, "Broker Disconnect / Internet Failure",
                  "Wait for reconnect; keep open positions unmanaged for foreign; own mgmt resumes");
         return;
        }
      if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED))
        {
         SetState(GM_FS_BLOCK_NEW_ORDERS, "Trading Disabled (terminal/EA)",
                  "Re-enable AutoTrading; no new pendings until allowed");
         return;
        }
      if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) || !AccountInfoInteger(ACCOUNT_TRADE_EXPERT))
        {
         SetState(GM_FS_BLOCK_NEW_ORDERS, "Account trading / Expert disabled",
                  "Check account permissions with broker");
         return;
        }

      const double free = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      if(free < GM_PROD_LOW_MARGIN_WARN)
        {
         SetState(GM_FS_BLOCK_NEW_ORDERS,
                  StringFormat("Low Margin | free=%.2f", free),
                  "Block new orders; manage existing; free margin");
         return;
        }

      const ulong mem_mb = (ulong)TerminalInfoInteger(TERMINAL_MEMORY_AVAILABLE);
      // TERMINAL_MEMORY_AVAILABLE may be 0 on some builds — treat as unknown OK
      if(mem_mb > 0 && mem_mb < GM_PROD_LOW_MEMORY_MB)
        {
         SetState(GM_FS_DEGRADED,
                  StringFormat("Low Memory | avail=%I64u MB", mem_mb),
                  "Reduce logging; flush registries; avoid heavy IO");
         return;
        }

      // Server timeout / stale quotes
      // (symbol checked by caller when placing — here global connection OK)
      SetState(GM_FS_OK, "Fail-safe clear", "Resume normal operation");
     }

   void OnUnexpectedException(const string where, const int err)
     {
      SetState(GM_FS_DEGRADED,
               StringFormat("Unexpected Exception | %s err=%d", where, err),
               "Continue safely; skip current action; log for QA");
     }
  };

#endif // GM_CFAIL_SAFE_ENGINE_MQH
//+------------------------------------------------------------------+
