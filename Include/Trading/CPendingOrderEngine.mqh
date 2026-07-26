//+------------------------------------------------------------------+
//|                                       CPendingOrderEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CPENDING_ORDER_ENGINE_MQH
#define GM_CPENDING_ORDER_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../Core/Defines.mqh"
#include "../Core/CErrorManager.mqh"
#include "../Calculation/SGmLevels.mqh"
#include "../Logging/CLogger.mqh"
#include "../Risk/CRiskEngine.mqh"
#include "../Risk/RiskConstants.mqh"
#include "../Lifecycle/CLevelGate.mqh"
#include "../Protection/CCapitalProtectionEngine.mqh"
#include "../Session/CExecutionControl.mqh"
#include "../Production/CProductionHardening.mqh"
#include "CTradeOwnership.mqh"
#include "CTradeIdManager.mqh"
#include "CTradeManager.mqh"

/// @file CPendingOrderEngine.mqh
/// @brief Places / deletes Gold Mind pendings with risk + capital + RC-1 gates.

class CGmPendingOrderEngine
  {
private:
   CGmLogger                   *m_logger;
   CGmErrorManager             *m_errors;
   CGmTradeOwnership           *m_ownership;
   CGmTradeIdManager           *m_trade_ids;
   CGmRiskEngine               *m_risk;
   CGmTradeManager             *m_trade_mgr;
   CGmLevelGate                *m_level_gate;
   CGmCapitalProtectionEngine  *m_protection;
   CGmExecutionControl         *m_exec;
   CGmProductionHardening      *m_production;
   string                       m_symbol;
   long                         m_magic;
   datetime                     m_h4_cycle;
   ulong                        m_deviation;
   bool                         m_initialized;

   ENUM_ORDER_TYPE_FILLING DetectFilling(void) const
     {
      const int mode = (int)SymbolInfoInteger(m_symbol, SYMBOL_FILLING_MODE);
      if((mode & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
         return ORDER_FILLING_FOK;
      if((mode & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
         return ORDER_FILLING_IOC;
      return ORDER_FILLING_RETURN;
     }

   bool IsStopsDistanceOk(const double price, const ENUM_ORDER_TYPE type) const
     {
      const long stops_level = SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL);
      const double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      if(point <= 0.0)
         return false;
      const double min_dist = (double)stops_level * point;
      const double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      const double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      if(type == ORDER_TYPE_BUY_LIMIT || type == ORDER_TYPE_BUY_STOP)
         return (MathAbs(ask - price) >= min_dist);
      if(type == ORDER_TYPE_SELL_LIMIT || type == ORDER_TYPE_SELL_STOP)
         return (MathAbs(bid - price) >= min_dist);
      return false;
     }

   ENUM_ORDER_TYPE ResolveBuyType(const double entry) const
     {
      return (SymbolInfoDouble(m_symbol, SYMBOL_ASK) > entry)
             ? ORDER_TYPE_BUY_LIMIT : ORDER_TYPE_BUY_STOP;
     }

   ENUM_ORDER_TYPE ResolveSellType(const double entry) const
     {
      return (SymbolInfoDouble(m_symbol, SYMBOL_BID) < entry)
             ? ORDER_TYPE_SELL_LIMIT : ORDER_TYPE_SELL_STOP;
     }

   bool HasOwnPendingForTag(const string level_tag) const
     {
      const int total = OrdersTotal();
      for(int i = 0; i < total; i++)
        {
         const ulong ticket = OrderGetTicket(i);
         if(ticket == 0 || !OrderSelect(ticket))
            continue;
         if((long)OrderGetInteger(ORDER_MAGIC) != m_magic)
            continue;
         if(OrderGetString(ORDER_SYMBOL) != m_symbol)
            continue;
         if(CGmTradeIdManager::ExtractLevelTag(OrderGetString(ORDER_COMMENT)) == level_tag)
            return true;
        }
      return false;
     }

   bool IsRetriable(const uint retcode) const
     {
      return (retcode == TRADE_RETCODE_REQUOTE ||
              retcode == TRADE_RETCODE_TIMEOUT ||
              retcode == TRADE_RETCODE_CONNECTION ||
              retcode == TRADE_RETCODE_PRICE_OFF ||
              retcode == TRADE_RETCODE_TOO_MANY_REQUESTS ||
              retcode == TRADE_RETCODE_PRICE_CHANGED);
     }

   bool SendPending(const ENUM_ORDER_TYPE type,
                    const double price,
                    const double lots,
                    const double sl,
                    const double tp,
                    const string comment,
                    const ulong trade_id,
                    ulong &order_ticket_out)
     {
      order_ticket_out = 0;
      if(!m_ownership.CanManageMagic(m_magic))
         return false;

      if(m_protection != NULL && !m_protection.CanPlaceNewOrders())
        {
         if(m_logger != NULL)
            m_logger.Warning(StringFormat("Skip pending — capital risk gate | %s | %s",
                                          comment, m_protection.LastRiskReason()),
                             "PendingEngine");
         return false;
        }

      const string level_tag = CGmTradeIdManager::ExtractLevelTag(comment);
      if(m_production != NULL && !m_production.CanPlacePending(level_tag))
        {
         if(m_logger != NULL)
            m_logger.Warning(StringFormat("Skip pending — fail-safe/security | %s | %s",
                                          comment, m_production.BlockReason()),
                             "PendingEngine");
         return false;
        }
      if(m_exec != NULL && !m_exec.CanPlacePending(level_tag))
        {
         if(m_logger != NULL)
            m_logger.Warning(StringFormat("Skip pending — execution control | %s | %s",
                                          comment, m_exec.LastReason()),
                             "PendingEngine");
         return false;
        }

      if(!IsStopsDistanceOk(price, type))
        {
         if(m_logger != NULL)
            m_logger.Warning(StringFormat("Skip %s — entry stops distance | TID=%I64u",
                                          comment, trade_id),
                             "PendingEngine");
         return false;
        }

      if(m_risk != NULL && !m_risk.Broker().ValidatePending(type, lots, price, sl, tp))
         return false;

      const int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
      const double norm_price = NormalizeDouble(price, digits);
      const double norm_sl = NormalizeDouble(sl, digits);
      const double norm_tp = NormalizeDouble(tp, digits);

      MqlTradeRequest request;
      MqlTradeResult  result;

      for(int attempt = 1; attempt <= GM_ORDER_RETRY_MAX; attempt++)
        {
         ZeroMemory(request);
         ZeroMemory(result);
         request.action       = TRADE_ACTION_PENDING;
         request.symbol       = m_symbol;
         request.volume       = lots;
         request.type         = type;
         request.price        = norm_price;
         request.sl           = norm_sl;
         request.tp           = norm_tp;
         request.deviation    = m_deviation;
         request.magic        = m_magic;
         request.comment      = comment;
         request.type_time    = ORDER_TIME_GTC;
         request.type_filling = DetectFilling();

         ResetLastError();
         const bool sent = OrderSend(request, result);
         if(sent && (result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED))
           {
            order_ticket_out = result.order;
            if(m_logger != NULL)
               m_logger.Success(StringFormat("Pending placed | %s | %s | price=%.5f lots=%.2f SL=%.5f TP=%.5f Magic=%I64d TID=%I64u order=%I64u",
                                             comment, EnumToString(type), norm_price, lots,
                                             norm_sl, norm_tp, m_magic, trade_id, result.order),
                                "PendingEngine");
            return true;
           }

         if(m_logger != NULL)
            m_logger.Warning(StringFormat("OrderSend attempt %d/%d failed | %s ret=%u err=%d",
                                          attempt, GM_ORDER_RETRY_MAX, comment,
                                          result.retcode, GetLastError()),
                             "PendingEngine");

         if(!IsRetriable(result.retcode) && result.retcode != 0)
            break;
         Sleep(GM_ORDER_RETRY_SLEEP_MS);
        }

      if(m_errors != NULL)
         m_errors.Error("PendingEngine",
                        StringFormat("OrderSend exhausted retries | %s", comment));
      return false;
     }

   bool PlaceOne(const ENUM_GM_LEVEL_TAG tag, const SGmLevels &levels)
     {
      if(m_level_gate != NULL && m_level_gate.ShouldSkipPlacement(tag))
        {
         if(m_logger != NULL)
            m_logger.Info(StringFormat("Skip placement | lifecycle blocks %s",
                                       SGmLevels::TagToComment(tag)),
                          "PendingEngine");
         return false;
        }

      const string level_tag = SGmLevels::TagToComment(tag);
      if(HasOwnPendingForTag(level_tag))
        {
         if(m_logger != NULL)
            m_logger.Info(StringFormat("Skip duplicate pending | tag=%s", level_tag),
                          "PendingEngine");
         return false;
        }

      double entry = levels.PriceByTag(tag);
      if(m_level_gate != NULL)
         entry = m_level_gate.LockedEntry(tag, entry);
      if(entry <= 0.0)
         return false;

      const ENUM_GM_LEVEL_SIDE side = SGmLevels::TagToSide(tag);
      SGmRiskPlan plan;
      if(m_risk == NULL || !m_risk.BuildPlan(entry, side, plan) || !plan.valid)
        {
         if(m_logger != NULL)
            m_logger.Error(StringFormat("Risk plan failed | tag=%s", level_tag), "PendingEngine");
         return false;
        }

      ENUM_ORDER_TYPE type = (side == GM_LEVEL_SIDE_BUY)
                             ? ResolveBuyType(entry) : ResolveSellType(entry);

      const ulong tid = m_trade_ids.Allocate();
      if(tid == 0)
         return false;

      const int attempt = (m_level_gate != NULL) ? m_level_gate.DesiredAttempt(tag) : 1;
      const string comment = m_trade_ids.BuildComment(level_tag, tid);
      ulong order_ticket = 0;
      if(!SendPending(type, entry, plan.lots, plan.sl, plan.tp, comment, tid, order_ticket))
         return false;

      if(m_trade_mgr != NULL)
         m_trade_mgr.RegisterPending(tid, order_ticket, level_tag, side,
                                     entry, plan.sl, plan.tp, plan.lots, m_h4_cycle);
      if(m_level_gate != NULL)
         m_level_gate.NotifyPendingPlaced(tag, tid, order_ticket, attempt);
      return true;
     }

public:
   /// @brief Reactivate exact original level price (First SL path).
   bool PlaceExact(const ENUM_GM_LEVEL_TAG tag, const double exact_entry, const int attempt)
     {
      const string level_tag = SGmLevels::TagToComment(tag);
      if(HasOwnPendingForTag(level_tag))
        {
         if(m_logger != NULL)
            m_logger.Warning(StringFormat("Reactivation blocked — pending exists | %s", level_tag),
                             "PendingEngine");
         return false;
        }

      if(exact_entry <= 0.0)
         return false;

      const ENUM_GM_LEVEL_SIDE side = SGmLevels::TagToSide(tag);
      SGmRiskPlan plan;
      if(m_risk == NULL || !m_risk.BuildPlan(exact_entry, side, plan) || !plan.valid)
         return false;

      ENUM_ORDER_TYPE type = (side == GM_LEVEL_SIDE_BUY)
                             ? ResolveBuyType(exact_entry) : ResolveSellType(exact_entry);

      const ulong tid = m_trade_ids.Allocate();
      if(tid == 0)
         return false;

      const string comment = m_trade_ids.BuildComment(level_tag, tid);
      ulong order_ticket = 0;
      if(!SendPending(type, exact_entry, plan.lots, plan.sl, plan.tp, comment, tid, order_ticket))
         return false;

      if(m_trade_mgr != NULL)
         m_trade_mgr.RegisterPending(tid, order_ticket, level_tag, side,
                                     exact_entry, plan.sl, plan.tp, plan.lots, m_h4_cycle);
      if(m_level_gate != NULL)
         m_level_gate.NotifyPendingPlaced(tag, tid, order_ticket, attempt);

      if(m_logger != NULL)
         m_logger.Success(StringFormat("Level Reactivated | %s @ %.5f | attempt=%d | TID=%I64u",
                                       level_tag, exact_entry, attempt, tid),
                          "PendingEngine");
      return true;
     }

                     CGmPendingOrderEngine(void)
                       : m_logger(NULL),
                         m_errors(NULL),
                         m_ownership(NULL),
                         m_trade_ids(NULL),
                         m_risk(NULL),
                         m_trade_mgr(NULL),
                         m_level_gate(NULL),
                         m_protection(NULL),
                         m_exec(NULL),
                         m_production(NULL),
                         m_symbol(""),
                         m_magic(0),
                         m_h4_cycle(0),
                         m_deviation(20),
                         m_initialized(false)
     {
     }

                    ~CGmPendingOrderEngine(void)
     {
      m_logger = NULL;
      m_errors = NULL;
      m_ownership = NULL;
      m_trade_ids = NULL;
      m_risk = NULL;
      m_trade_mgr = NULL;
      m_level_gate = NULL;
      m_protection = NULL;
      m_exec = NULL;
      m_production = NULL;
     }

   bool Init(CGmLogger *logger,
             CGmErrorManager *errors,
             CGmTradeOwnership *ownership,
             CGmTradeIdManager *trade_ids,
             CGmRiskEngine *risk,
             CGmTradeManager *trade_mgr,
             CGmLevelGate *level_gate,
             const string symbol,
             const long magic)
     {
      m_logger = logger;
      m_errors = errors;
      m_ownership = ownership;
      m_trade_ids = trade_ids;
      m_risk = risk;
      m_trade_mgr = trade_mgr;
      m_level_gate = level_gate;
      m_symbol = symbol;
      m_magic = magic;
      m_initialized = (m_ownership != NULL && m_trade_ids != NULL && m_risk != NULL);

      if(m_initialized && m_logger != NULL)
         m_logger.Info(StringFormat("Pending Order Engine ready | Magic=%I64d | lifecycle gate=%s",
                                    m_magic, (m_level_gate != NULL) ? "ON" : "OFF"),
                       "PendingEngine");
      return m_initialized;
     }

   void SetLevelGate(CGmLevelGate *gate) { m_level_gate = gate; }
   void SetProtection(CGmCapitalProtectionEngine *protection) { m_protection = protection; }
   void SetExecutionControl(CGmExecutionControl *exec) { m_exec = exec; }
   void SetProduction(CGmProductionHardening *production) { m_production = production; }

   void SetH4Cycle(const datetime cycle) { m_h4_cycle = cycle; }

   int PlaceAll(const SGmLevels &levels)
     {
      if(!m_initialized || !levels.valid)
         return 0;

      m_h4_cycle = levels.h4_bar_time;
      if(m_trade_mgr != NULL)
         m_trade_mgr.SetH4CycleId(m_h4_cycle);

      const ulong t0 = GetMicrosecondCount();
      int placed = 0;
      if(m_logger != NULL)
         m_logger.Info("Placing 3 Buy + 3 Sell pending orders (risk-managed)...", "PendingEngine");

      if(PlaceOne(GM_TAG_BL1, levels)) placed++;
      if(PlaceOne(GM_TAG_BL2, levels)) placed++;
      if(PlaceOne(GM_TAG_BL3, levels)) placed++;
      if(PlaceOne(GM_TAG_SL1, levels)) placed++;
      if(PlaceOne(GM_TAG_SL2, levels)) placed++;
      if(PlaceOne(GM_TAG_SL3, levels)) placed++;

      if(m_logger != NULL)
         m_logger.Success(StringFormat("Pending placement complete | placed=%d | %I64u us",
                                       placed, GetMicrosecondCount() - t0),
                          "PendingEngine");
      return placed;
     }

   int DeleteUnusedOwnPendings(void)
     {
      if(!m_initialized)
         return 0;

      int deleted = 0;
      for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
         const ulong ticket = OrderGetTicket(i);
         if(ticket == 0 || !OrderSelect(ticket))
            continue;
         if((long)OrderGetInteger(ORDER_MAGIC) != m_magic)
            continue;
         if(OrderGetString(ORDER_SYMBOL) != m_symbol)
            continue;
         if(!m_ownership.CanManageOrder(ticket, true))
            continue;

         const string comment = OrderGetString(ORDER_COMMENT);
         MqlTradeRequest request;
         MqlTradeResult  result;
         ZeroMemory(request);
         ZeroMemory(result);
         request.action = TRADE_ACTION_REMOVE;
         request.order  = ticket;

         bool removed = false;
         for(int attempt = 1; attempt <= GM_ORDER_RETRY_MAX; attempt++)
           {
            ZeroMemory(result);
            if(OrderSend(request, result) &&
               (result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED))
              {
               removed = true;
               break;
              }
            Sleep(GM_ORDER_RETRY_SLEEP_MS);
           }

         if(!removed)
           {
            if(m_logger != NULL)
               m_logger.Warning(StringFormat("Failed to delete pending ticket=%I64u", ticket),
                                "PendingEngine");
            continue;
           }

         deleted++;
         if(m_logger != NULL)
            m_logger.Info(StringFormat("Deleted unused pending | ticket=%I64u | %s",
                                       ticket, comment),
                          "PendingEngine");
        }

      if(m_logger != NULL)
         m_logger.Info(StringFormat("Unused pending cleanup | deleted=%d (positions untouched)", deleted),
                       "PendingEngine");
      return deleted;
     }
  };

#endif // GM_CPENDING_ORDER_ENGINE_MQH
//+------------------------------------------------------------------+
