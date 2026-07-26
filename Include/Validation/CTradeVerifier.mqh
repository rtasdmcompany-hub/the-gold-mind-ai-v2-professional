//+------------------------------------------------------------------+
//|                                           CTradeVerifier.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CTRADE_VERIFIER_MQH
#define GM_CTRADE_VERIFIER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmValidationResult.mqh"
#include "CErrorClassifier.mqh"
#include "../Risk/RiskConstants.mqh"
#include "../TradeManagement/TradeMgmtConstants.mqh"
#include "../TradeManagement/CPipTools.mqh"
#include "../Trading/CTradeRegistry.mqh"
#include "../Trading/SGmTradeRecord.mqh"
#include "../Trading/CTradeOwnership.mqh"

/// @file CTradeVerifier.mqh
/// @brief Verifies open/closed trades against strategy rules (warn on mismatch).

class CGmTradeVerifier
  {
private:
   CGmLogger          *m_logger;
   CGmErrorClassifier *m_errors;
   CGmTradeRegistry   *m_registry;
   CGmTradeOwnership  *m_ownership;
   string              m_symbol;
   long                m_magic;
   int                 m_verified;
   int                 m_warnings;

   void Warn(const string msg)
     {
      m_warnings++;
      if(m_errors != NULL)
         m_errors.Add(GM_VAL_SEV_WARNING, "TradeVerify", msg,
                      "Compare trade fields to official SL/TP/BE/Partial/Trail rules.");
      if(m_logger != NULL)
         m_logger.Warning(msg, "TradeVerify");
     }

public:
                     CGmTradeVerifier(void)
                       : m_logger(NULL), m_errors(NULL), m_registry(NULL),
                         m_ownership(NULL), m_symbol(""), m_magic(0),
                         m_verified(0), m_warnings(0)
     {
     }

                    ~CGmTradeVerifier(void)
     {
      m_logger = NULL;
      m_errors = NULL;
      m_registry = NULL;
      m_ownership = NULL;
     }

   void Init(CGmLogger *logger,
             CGmErrorClassifier *errors,
             CGmTradeRegistry *registry,
             CGmTradeOwnership *ownership,
             const string symbol,
             const long magic)
     {
      m_logger = logger;
      m_errors = errors;
      m_registry = registry;
      m_ownership = ownership;
      m_symbol = symbol;
      m_magic = magic;
     }

   int VerifiedCount(void) const { return m_verified; }
   int WarningCount(void) const { return m_warnings; }

   bool VerifyOpenPosition(const ulong ticket)
     {
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         return false;
      if((long)PositionGetInteger(POSITION_MAGIC) != m_magic)
         return false;
      if(PositionGetString(POSITION_SYMBOL) != m_symbol)
         return false;

      m_verified++;
      const double open = PositionGetDouble(POSITION_PRICE_OPEN);
      const double sl = PositionGetDouble(POSITION_SL);
      const double tp = PositionGetDouble(POSITION_TP);
      const double vol = PositionGetDouble(POSITION_VOLUME);
      const long type = PositionGetInteger(POSITION_TYPE);
      const double pip = CGmPipTools::PipSize(m_symbol);
      const double expected_sl_dist = CGmPipTools::PipsToPrice(m_symbol, GM_FIXED_SL_PIPS);

      if(vol <= 0.0)
         Warn(StringFormat("ticket=%I64u invalid lot", ticket));
      if(sl <= 0.0)
         Warn(StringFormat("ticket=%I64u missing Stop Loss", ticket));
      else if(pip > 0.0)
        {
         const double sl_dist = MathAbs(open - sl);
         if(MathAbs(sl_dist - expected_sl_dist) > pip * GM_VAL_SL_PIP_TOLERANCE)
           {
            // May be BE or trailing — check registry flags
            SGmTradeRecord rec;
            bool be = false, trail = false;
            if(m_registry != NULL && m_registry.GetByTicket(ticket, rec))
              {
               be = rec.be_done;
               trail = rec.trailing_active;
              }
            if(!be && !trail)
               Warn(StringFormat("ticket=%I64u SL distance %.5f != 30-pip %.5f",
                                 ticket, sl_dist, expected_sl_dist));
           }
        }
      if(tp <= 0.0)
         Warn(StringFormat("ticket=%I64u missing Take Profit", ticket));

      // Direction sanity
      if(type == POSITION_TYPE_BUY && sl > 0.0 && sl > open && !PositionSelectByTicket(ticket))
         Warn(StringFormat("ticket=%I64u BUY SL above entry", ticket));
      if(type == POSITION_TYPE_SELL && sl > 0.0 && sl < open)
         Warn(StringFormat("ticket=%I64u SELL SL below entry", ticket));

      if(m_registry != NULL)
        {
         SGmTradeRecord rec;
         if(m_registry.GetByTicket(ticket, rec))
           {
            if(rec.be_done && sl > 0.0)
              {
               // BE should be near entry
               if(MathAbs(sl - open) > pip * 2.0 && !rec.trailing_active)
                  Warn(StringFormat("ticket=%I64u BE flag set but SL not near entry", ticket));
              }
            if(rec.partial_done && rec.original_volume > 0.0)
              {
               const double expected_runner = rec.original_volume * (GM_RUNNER_PERCENT / 100.0);
               // Allow broker step rounding
               if(vol > expected_runner * 1.5 + 1e-8)
                  Warn(StringFormat("ticket=%I64u partial done but volume %.2f high vs runner ~%.2f",
                                    ticket, vol, expected_runner));
              }
           }
        }
      return true;
     }

   int VerifyAllOpen(void)
     {
      m_verified = 0;
      m_warnings = 0;
      const int total = PositionsTotal();
      for(int i = 0; i < total; i++)
        {
         const ulong ticket = PositionGetTicket(i);
         VerifyOpenPosition(ticket);
        }
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Trade verification | checked=%d warnings=%d",
                                    m_verified, m_warnings),
                       "TradeVerify");
      return m_warnings;
     }
  };

#endif // GM_CTRADE_VERIFIER_MQH
//+------------------------------------------------------------------+
