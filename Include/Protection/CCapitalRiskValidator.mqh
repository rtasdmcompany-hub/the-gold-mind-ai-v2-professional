//+------------------------------------------------------------------+
//|                                     CCapitalRiskValidator.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CCAPITAL_RISK_VALIDATOR_MQH
#define GM_CCAPITAL_RISK_VALIDATOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CEventLogger.mqh"
#include "CAccountMonitor.mqh"
#include "CBrokerSafetyEngine.mqh"
#include "../Risk/CRiskEngine.mqh"

/// @file CCapitalRiskValidator.mqh
/// @brief Pre-pending risk validation — block new orders on failure.

class CGmCapitalRiskValidator
  {
private:
   CGmEventLogger        *m_events;
   CGmAccountMonitor     *m_account;
   CGmBrokerSafetyEngine *m_broker_safety;
   CGmRiskEngine         *m_risk;
   bool                   m_enabled;
   string                 m_last_reason;

   bool Fail(const string reason)
     {
      m_last_reason = reason;
      if(m_events != NULL)
         m_events.Validation("RiskValidation", reason, GM_LOG_WARNING);
      return false;
     }

public:
                     CGmCapitalRiskValidator(void)
                       : m_events(NULL),
                         m_account(NULL),
                         m_broker_safety(NULL),
                         m_risk(NULL),
                         m_enabled(true),
                         m_last_reason("")
     {
     }

                    ~CGmCapitalRiskValidator(void)
     {
      m_events = NULL;
      m_account = NULL;
      m_broker_safety = NULL;
      m_risk = NULL;
     }

   void Init(CGmEventLogger *events,
             CGmAccountMonitor *account,
             CGmBrokerSafetyEngine *broker_safety,
             CGmRiskEngine *risk,
             const bool enabled)
     {
      m_events = events;
      m_account = account;
      m_broker_safety = broker_safety;
      m_risk = risk;
      m_enabled = enabled;
      if(m_events != NULL)
         m_events.Risk("RiskValidation",
                       StringFormat("Ready | capitalProtection=%s", enabled ? "ON" : "OFF"));
     }

   void SetEnabled(const bool enabled) { m_enabled = enabled; }
   string LastReason(void) const { return m_last_reason; }

   bool ValidateConnection(void)
     {
      if(!TerminalInfoInteger(TERMINAL_CONNECTED))
         return Fail("Broker connection inactive");
      return true;
     }

   bool ValidateAccountWritable(void)
     {
      if(AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_CONTEST)
         return Fail("Account is contest/read-restricted");
      if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
         return Fail("Account not trade-allowed (read-only)");
      if(!AccountInfoInteger(ACCOUNT_TRADE_EXPERT))
         return Fail("Expert Advisors disabled on account");
      return true;
     }

   bool ValidateTradingAllowed(void)
     {
      if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
         return Fail("Terminal trading disabled");
      if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
         return Fail("EA trading permission disabled");
      return true;
     }

   bool ValidateMarketOpen(const string symbol)
     {
      const long mode = SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE);
      if(mode == SYMBOL_TRADE_MODE_DISABLED)
         return Fail("Market closed / symbol trading disabled");
      const datetime tick_time = (datetime)SymbolInfoInteger(symbol, SYMBOL_TIME);
      if(tick_time <= 0 || TimeCurrent() - tick_time > 600)
         return Fail("Market likely closed (stale quotes)");
      return true;
     }

   bool ValidateFreeMargin(void)
     {
      if(m_account == NULL)
         return Fail("Account monitor unavailable");
      m_account.Refresh();
      const SGmAccountSnapshot snap = m_account.Copy();
      if(!snap.valid)
         return Fail("Account snapshot invalid");
      if(snap.free_margin <= 0.0)
         return Fail(StringFormat("No free margin | free=%.2f", snap.free_margin));
      return true;
     }

   bool ValidateRiskEngine(void)
     {
      if(m_risk == NULL)
         return Fail("Risk engine unavailable");
      if(!m_risk.ValidateTrade())
         return Fail("Risk calculation / trading gate failed");
      return true;
     }

   /// @brief Full gate before placing ANY new pending order.
   bool CanPlaceNewPending(const string symbol)
     {
      m_last_reason = "";
      if(!m_enabled)
         return true; // protection disabled — allow (still use broker validator downstream)

      if(!ValidateConnection()) return false;
      if(!ValidateTradingAllowed()) return false;
      if(!ValidateAccountWritable()) return false;
      if(!ValidateMarketOpen(symbol)) return false;
      if(!ValidateFreeMargin()) return false;
      if(m_broker_safety != NULL && !m_broker_safety.ValidateSpecs())
        {
         m_last_reason = m_broker_safety.LastReason();
         return false;
        }
      if(!ValidateRiskEngine()) return false;

      if(m_events != NULL && m_events.Detailed())
         m_events.Validation("RiskValidation", "Pre-pending validation OK", GM_LOG_DEBUG);
      return true;
     }
  };

#endif // GM_CCAPITAL_RISK_VALIDATOR_MQH
//+------------------------------------------------------------------+
