//+------------------------------------------------------------------+
//|                                         CBreakEvenEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CBREAK_EVEN_ENGINE_MQH
#define GM_CBREAK_EVEN_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "TradeMgmtConstants.mqh"
#include "CPipTools.mqh"
#include "CTradeMgmtValidator.mqh"
#include "../Risk/RiskConstants.mqh"
#include "../Logging/CLogger.mqh"
#include "../Trading/SGmTradeRecord.mqh"

/// @file CBreakEvenEngine.mqh
/// @brief Move SL to entry once at +50 pips — never more than once.

class CGmBreakEvenEngine
  {
private:
   CGmLogger             *m_logger;
   CGmTradeMgmtValidator *m_validator;
   string                 m_symbol;

public:
                     CGmBreakEvenEngine(void)
                       : m_logger(NULL), m_validator(NULL), m_symbol("") {}
                    ~CGmBreakEvenEngine(void)
     {
      m_logger = NULL;
      m_validator = NULL;
     }

   void Init(CGmLogger *logger, CGmTradeMgmtValidator *validator, const string symbol)
     {
      m_logger = logger;
      m_validator = validator;
      m_symbol = symbol;
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Break Even Engine ready | trigger=+%.0f pips",
                                    GM_BE_TRIGGER_PIPS),
                       "BreakEven");
     }

   /// @return true if BE applied this call.
   bool Apply(SGmTradeRecord &rec)
     {
      const ulong t0 = GetMicrosecondCount();
      if(m_validator == NULL || !m_validator.CanBreakEven(rec) || !m_validator.BrokerAllowsModify())
         return false;
      if(!PositionSelectByTicket(rec.ticket))
         return false;

      const int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
      const double open = PositionGetDouble(POSITION_PRICE_OPEN);
      const double tp = PositionGetDouble(POSITION_TP);
      const double be_sl = NormalizeDouble(open, digits);

      MqlTradeRequest request;
      MqlTradeResult  result;
      ZeroMemory(request);
      ZeroMemory(result);
      request.action   = TRADE_ACTION_SLTP;
      request.position = rec.ticket;
      request.symbol   = m_symbol;
      request.sl       = be_sl;
      request.tp       = tp;

      bool ok = false;
      for(int attempt = 1; attempt <= GM_ORDER_RETRY_MAX; attempt++)
        {
         ZeroMemory(result);
         if(OrderSend(request, result) &&
            (result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED))
           {
            ok = true;
            break;
           }
         if(m_logger != NULL)
            m_logger.Warning(StringFormat("BE modify retry %d/%d | ticket=%I64u ret=%u",
                                          attempt, GM_ORDER_RETRY_MAX, rec.ticket, result.retcode),
                             "BreakEven");
         Sleep(GM_ORDER_RETRY_SLEEP_MS);
        }

      if(!ok)
        {
         if(m_logger != NULL)
            m_logger.Error(StringFormat("Break Even FAILED | ticket=%I64u", rec.ticket), "BreakEven");
         return false;
        }

      rec.be_done = true;
      rec.stop_loss = be_sl;
      rec.stage = GM_TRADE_STAGE_BREAK_EVEN;
      if(m_logger != NULL)
         m_logger.Success(StringFormat("Break Even Activated | ticket=%I64u SL→%.5f | +%.1f pips | %I64u us",
                                       rec.ticket, be_sl, rec.profit_pips,
                                       GetMicrosecondCount() - t0),
                          "BreakEven");
      return true;
     }
  };

#endif // GM_CBREAK_EVEN_ENGINE_MQH
//+------------------------------------------------------------------+
