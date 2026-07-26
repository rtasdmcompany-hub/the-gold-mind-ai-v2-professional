//+------------------------------------------------------------------+
//|                                      CTrailingStopEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CTRAILING_STOP_ENGINE_MQH
#define GM_CTRAILING_STOP_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "TradeMgmtConstants.mqh"
#include "CPipTools.mqh"
#include "CTradeMgmtValidator.mqh"
#include "../Risk/RiskConstants.mqh"
#include "../Logging/CLogger.mqh"
#include "../Trading/SGmTradeRecord.mqh"

/// @file CTrailingStopEngine.mqh
/// @brief 30-pip trailing after BE+Partial — never move SL backwards.

class CGmTrailingStopEngine
  {
private:
   CGmLogger             *m_logger;
   CGmTradeMgmtValidator *m_validator;
   string                 m_symbol;

public:
                     CGmTrailingStopEngine(void)
                       : m_logger(NULL), m_validator(NULL), m_symbol("") {}
                    ~CGmTrailingStopEngine(void)
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
         m_logger.Info(StringFormat("Trailing Stop Engine ready | distance=%.0f pips",
                                    GM_TRAIL_DISTANCE_PIPS),
                       "Trailing");
     }

   /// @return true if SL was updated.
   bool Update(SGmTradeRecord &rec)
     {
      if(m_validator == NULL || !m_validator.CanTrail(rec) || !m_validator.BrokerAllowsModify())
         return false;
      if(!PositionSelectByTicket(rec.ticket))
         return false;

      const int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
      const double trail_dist = CGmPipTools::PipsToPrice(m_symbol, GM_TRAIL_DISTANCE_PIPS);
      if(trail_dist <= 0.0)
         return false;

      const long pos_type = PositionGetInteger(POSITION_TYPE);
      const double cur_sl = PositionGetDouble(POSITION_SL);
      const double tp = PositionGetDouble(POSITION_TP);
      double desired_sl = 0.0;

      if(pos_type == POSITION_TYPE_BUY)
        {
         const double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
         desired_sl = NormalizeDouble(bid - trail_dist, digits);
         // Never move backwards (down) and never below BE/entry floor.
         const double floor_sl = NormalizeDouble(rec.entry_price, digits);
         if(desired_sl < floor_sl)
            desired_sl = floor_sl;
         if(cur_sl > 0.0 && desired_sl <= cur_sl)
            return false; // would reduce locked profit
        }
      else
        {
         const double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
         desired_sl = NormalizeDouble(ask + trail_dist, digits);
         const double floor_sl = NormalizeDouble(rec.entry_price, digits);
         if(desired_sl > floor_sl)
            desired_sl = floor_sl;
         if(cur_sl > 0.0 && desired_sl >= cur_sl)
            return false;
        }

      // Stops level check
      const long stops_level = SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL);
      const double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      const double min_dist = (double)stops_level * point;
      if(pos_type == POSITION_TYPE_BUY)
        {
         const double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
         if(bid - desired_sl < min_dist)
            return false;
        }
      else
        {
         const double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
         if(desired_sl - ask < min_dist)
            return false;
        }

      MqlTradeRequest request;
      MqlTradeResult  result;
      ZeroMemory(request);
      ZeroMemory(result);
      request.action   = TRADE_ACTION_SLTP;
      request.position = rec.ticket;
      request.symbol   = m_symbol;
      request.sl       = desired_sl;
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
         Sleep(GM_ORDER_RETRY_SLEEP_MS);
        }

      if(!ok)
        {
         if(m_logger != NULL)
            m_logger.Warning(StringFormat("Trailing update failed | ticket=%I64u", rec.ticket),
                             "Trailing");
         return false;
        }

      if(!rec.trailing_active && m_logger != NULL)
         m_logger.Success(StringFormat("Trailing Activated | ticket=%I64u dist=%.0f pips",
                                       rec.ticket, GM_TRAIL_DISTANCE_PIPS),
                          "Trailing");

      rec.trailing_active = true;
      rec.stop_loss = desired_sl;
      rec.stage = GM_TRADE_STAGE_TRAILING;
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Trailing Updated | ticket=%I64u SL=%.5f",
                                    rec.ticket, desired_sl),
                       "Trailing");
      return true;
     }
  };

#endif // GM_CTRAILING_STOP_ENGINE_MQH
//+------------------------------------------------------------------+
