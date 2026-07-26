//+------------------------------------------------------------------+
//|                                      CPartialCloseEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CPARTIAL_CLOSE_ENGINE_MQH
#define GM_CPARTIAL_CLOSE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "TradeMgmtConstants.mqh"
#include "CPipTools.mqh"
#include "CTradeMgmtValidator.mqh"
#include "../Risk/RiskConstants.mqh"
#include "../Logging/CLogger.mqh"
#include "../Trading/SGmTradeRecord.mqh"

/// @file CPartialCloseEngine.mqh
/// @brief Close 80% once after BE; leave 20% runner.

class CGmPartialCloseEngine
  {
private:
   CGmLogger             *m_logger;
   CGmTradeMgmtValidator *m_validator;
   string                 m_symbol;
   ulong                  m_deviation;

   ENUM_ORDER_TYPE_FILLING DetectFilling(void) const
     {
      const int mode = (int)SymbolInfoInteger(m_symbol, SYMBOL_FILLING_MODE);
      if((mode & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
         return ORDER_FILLING_FOK;
      if((mode & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
         return ORDER_FILLING_IOC;
      return ORDER_FILLING_RETURN;
     }

public:
                     CGmPartialCloseEngine(void)
                       : m_logger(NULL), m_validator(NULL), m_symbol(""), m_deviation(20) {}
                    ~CGmPartialCloseEngine(void)
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
         m_logger.Info(StringFormat("Partial Close Engine ready | close=%.0f%% leave=%.0f%%",
                                    GM_PARTIAL_CLOSE_PERCENT, GM_RUNNER_PERCENT),
                       "PartialClose");
     }

   bool Apply(SGmTradeRecord &rec)
     {
      const ulong t0 = GetMicrosecondCount();
      if(m_validator == NULL || !m_validator.CanPartialClose(rec) || !m_validator.BrokerAllowsModify())
         return false;
      if(!PositionSelectByTicket(rec.ticket))
         return false;

      const double current_vol = PositionGetDouble(POSITION_VOLUME);
      if(rec.original_volume <= 0.0)
         rec.original_volume = current_vol;

      // Close 80% of original (leave 20% runner). Fall back to current if needed.
      double close_vol = rec.original_volume * (GM_PARTIAL_CLOSE_PERCENT / 100.0);
      close_vol = CGmPipTools::NormalizeVolume(m_symbol, close_vol);

      const double vmin = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
      if(close_vol < vmin)
        {
         if(m_logger != NULL)
            m_logger.Warning(StringFormat("Partial skip — close vol %.2f < min %.2f | ticket=%I64u",
                                          close_vol, vmin, rec.ticket),
                             "PartialClose");
         // Mark done to avoid infinite retries on tiny lots.
         rec.partial_done = true;
         rec.stage = GM_TRADE_STAGE_PARTIAL_DONE;
         return false;
        }

      if(close_vol >= current_vol)
        {
         // Keep at least min lot runner if possible.
         close_vol = CGmPipTools::NormalizeVolume(m_symbol, current_vol - vmin);
         if(close_vol < vmin)
           {
            rec.partial_done = true;
            rec.stage = GM_TRADE_STAGE_PARTIAL_DONE;
            if(m_logger != NULL)
               m_logger.Warning("Partial skip — cannot leave min runner", "PartialClose");
            return false;
           }
        }

      const long pos_type = PositionGetInteger(POSITION_TYPE);
      MqlTradeRequest request;
      MqlTradeResult  result;
      ZeroMemory(request);
      ZeroMemory(result);
      request.action    = TRADE_ACTION_DEAL;
      request.position  = rec.ticket;
      request.symbol    = m_symbol;
      request.volume    = close_vol;
      request.deviation = m_deviation;
      request.magic     = rec.magic;
      request.type_filling = DetectFilling();
      if(pos_type == POSITION_TYPE_BUY)
        {
         request.type  = ORDER_TYPE_SELL;
         request.price = SymbolInfoDouble(m_symbol, SYMBOL_BID);
        }
      else
        {
         request.type  = ORDER_TYPE_BUY;
         request.price = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
        }

      bool ok = false;
      for(int attempt = 1; attempt <= GM_ORDER_RETRY_MAX; attempt++)
        {
         ZeroMemory(result);
         if(OrderSend(request, result) &&
            (result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_DONE_PARTIAL))
           {
            ok = true;
            break;
           }
         if(m_logger != NULL)
            m_logger.Warning(StringFormat("Partial retry %d/%d | ticket=%I64u ret=%u",
                                          attempt, GM_ORDER_RETRY_MAX, rec.ticket, result.retcode),
                             "PartialClose");
         Sleep(GM_ORDER_RETRY_SLEEP_MS);
        }

      if(!ok)
        {
         if(m_logger != NULL)
            m_logger.Error(StringFormat("Partial Close FAILED | ticket=%I64u", rec.ticket),
                           "PartialClose");
         return false;
        }

      rec.partial_done = true;
      rec.stage = GM_TRADE_STAGE_PARTIAL_DONE;
      if(PositionSelectByTicket(rec.ticket))
         rec.volume = PositionGetDouble(POSITION_VOLUME);
      else
         rec.volume = MathMax(0.0, current_vol - close_vol);

      if(m_logger != NULL)
         m_logger.Success(StringFormat("80%% Partial Close | ticket=%I64u closed=%.2f remaining=%.2f | %I64u us",
                                       rec.ticket, close_vol, rec.volume,
                                       GetMicrosecondCount() - t0),
                          "PartialClose");
      return true;
     }
  };

#endif // GM_CPARTIAL_CLOSE_ENGINE_MQH
//+------------------------------------------------------------------+
