//+------------------------------------------------------------------+
//|                                    CTradeMgmtValidator.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CTRADE_MGMT_VALIDATOR_MQH
#define GM_CTRADE_MGMT_VALIDATOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../Trading/SGmTradeRecord.mqh"
#include "../Logging/CLogger.mqh"

/// @file CTradeMgmtValidator.mqh
/// @brief Pre-action gates for BE / Partial / Trailing (no duplicates).

class CGmTradeMgmtValidator
  {
private:
   CGmLogger *m_logger;
   string     m_last_reason;

   bool Fail(const string reason)
     {
      m_last_reason = reason;
      if(m_logger != NULL)
         m_logger.Warning("TradeMgmt validation FAIL | " + reason, "TradeMgmtValidation");
      return false;
     }

public:
                     CGmTradeMgmtValidator(void) : m_logger(NULL), m_last_reason("") {}
                    ~CGmTradeMgmtValidator(void) { m_logger = NULL; }

   void Init(CGmLogger *logger) { m_logger = logger; }
   string LastReason(void) const { return m_last_reason; }

   bool TradeExists(const ulong ticket) const
     {
      return (ticket > 0 && PositionSelectByTicket(ticket));
     }

   bool CanBreakEven(const SGmTradeRecord &rec)
     {
      m_last_reason = "";
      if(!TradeExists(rec.ticket))
         return Fail("Trade does not exist");
      if(rec.be_done)
         return Fail("Break Even already activated");
      if(rec.status != GM_TRADE_STATUS_ACTIVE)
         return Fail("Trade not active");
      return true;
     }

   bool CanPartialClose(const SGmTradeRecord &rec)
     {
      m_last_reason = "";
      if(!TradeExists(rec.ticket))
         return Fail("Trade does not exist");
      if(!rec.be_done)
         return Fail("Partial requires Break Even first");
      if(rec.partial_done)
         return Fail("Partial Close already completed");
      return true;
     }

   bool CanTrail(const SGmTradeRecord &rec)
     {
      m_last_reason = "";
      if(!TradeExists(rec.ticket))
         return Fail("Trade does not exist");
      if(!rec.partial_done)
         return Fail("Trailing only after Partial Close");
      if(!rec.be_done)
         return Fail("Trailing requires Break Even");
      return true;
     }

   bool BrokerAllowsModify(void)
     {
      if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED))
         return Fail("Broker/terminal trading not allowed");
      return true;
     }
  };

#endif // GM_CTRADE_MGMT_VALIDATOR_MQH
//+------------------------------------------------------------------+
