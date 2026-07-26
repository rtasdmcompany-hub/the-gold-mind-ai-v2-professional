//+------------------------------------------------------------------+
//|                                             CTradeManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CTRADE_MANAGER_MQH
#define GM_CTRADE_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../Risk/CRiskEngine.mqh"
#include "../Risk/RiskConstants.mqh"
#include "../Logging/CLogger.mqh"
#include "../Core/CErrorManager.mqh"
#include "../Lifecycle/CLevelGate.mqh"
#include "../TradeManagement/CTradeMgmtEngine.mqh"
#include "../Session/CH4SessionEngine.mqh"
#include "CTradeOwnership.mqh"
#include "CTradeIdManager.mqh"
#include "CTradeRegistry.mqh"
#include "CTradeBase.mqh"

/// @file CTradeManager.mqh
/// @brief Detect pending→market activation; ensure SL/TP; Sprint 5+7 session audit.

class CGmTradeManager : public CGmTradeBase
  {
private:
   CGmErrorManager     *m_errors;
   CGmTradeOwnership   *m_ownership;
   CGmTradeIdManager   *m_trade_ids;
   CGmTradeRegistry    *m_registry;
   CGmRiskEngine       *m_risk;
   CGmLevelGate        *m_level_gate;
   CGmH4SessionEngine  *m_h4_session;
   CGmTradeMgmtEngine   m_trade_mgmt;
   string               m_symbol;
   long                 m_magic;
   datetime             m_h4_cycle_id;

   bool EnsureStops(const ulong position_ticket, double &sl_out, double &tp_out)
     {
      if(!PositionSelectByTicket(position_ticket))
         return false;

      const double entry = PositionGetDouble(POSITION_PRICE_OPEN);
      const long pos_type = PositionGetInteger(POSITION_TYPE);
      const ENUM_GM_LEVEL_SIDE side =
         (pos_type == POSITION_TYPE_BUY) ? GM_LEVEL_SIDE_BUY : GM_LEVEL_SIDE_SELL;

      double cur_sl = PositionGetDouble(POSITION_SL);
      double cur_tp = PositionGetDouble(POSITION_TP);
      sl_out = cur_sl;
      tp_out = cur_tp;

      bool need_sl = (cur_sl <= 0.0);
      bool need_tp = (cur_tp <= 0.0);
      if(!need_sl && !need_tp)
         return true;

      SGmRiskPlan plan;
      if(!m_risk.BuildPlan(entry, side, plan))
        {
         if(m_logger != NULL)
            m_logger.Error("Cannot build risk plan to protect position", "TradeManager");
         return false;
        }

      if(need_sl) sl_out = plan.sl;
      if(need_tp) tp_out = plan.tp;

      MqlTradeRequest request;
      MqlTradeResult  result;
      ZeroMemory(request);
      ZeroMemory(result);
      request.action = TRADE_ACTION_SLTP;
      request.position = position_ticket;
      request.symbol = m_symbol;
      request.sl = sl_out;
      request.tp = tp_out;

      ResetLastError();
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
            m_logger.Warning(StringFormat("SLTP attach retry %d/%d | ticket=%I64u ret=%u",
                                          attempt, GM_ORDER_RETRY_MAX, position_ticket, result.retcode),
                             "TradeManager");
         Sleep(GM_ORDER_RETRY_SLEEP_MS);
        }

      if(ok && m_logger != NULL)
         m_logger.Success(StringFormat("Position protected | ticket=%I64u SL=%.5f TP=%.5f",
                                       position_ticket, sl_out, tp_out),
                          "TradeManager");
      else if(!ok && m_errors != NULL)
         m_errors.Error("TradeManager",
                        StringFormat("Failed to attach SL/TP | ticket=%I64u", position_ticket),
                        (int)result.retcode);
      return ok;
     }

public:
                     CGmTradeManager(void)
                       : m_errors(NULL),
                         m_ownership(NULL),
                         m_trade_ids(NULL),
                         m_registry(NULL),
                         m_risk(NULL),
                         m_level_gate(NULL),
                         m_h4_session(NULL),
                         m_symbol(""),
                         m_magic(0),
                         m_h4_cycle_id(0)
     {
      m_module_name = "TradeManager";
     }

   virtual          ~CGmTradeManager(void)
     {
      m_errors = NULL;
      m_ownership = NULL;
      m_trade_ids = NULL;
      m_registry = NULL;
      m_risk = NULL;
      m_level_gate = NULL;
      m_h4_session = NULL;
     }

   bool InitFull(CGmLogger *logger,
                 CGmErrorManager *errors,
                 CGmTradeOwnership *ownership,
                 CGmTradeIdManager *trade_ids,
                 CGmTradeRegistry *registry,
                 CGmRiskEngine *risk,
                 CGmLevelGate *level_gate,
                 const string symbol,
                 const long magic)
     {
      m_logger = logger;
      m_errors = errors;
      m_ownership = ownership;
      m_trade_ids = trade_ids;
      m_registry = registry;
      m_risk = risk;
      m_level_gate = level_gate;
      m_symbol = symbol;
      m_magic = magic;
      m_trade_mgmt.Init(logger, registry, ownership, symbol, magic);
      m_status = GM_MODULE_READY;
      if(m_logger != NULL)
         m_logger.Info("Trade Manager ready | activation + close + BE/Partial/Trail",
                       m_module_name);
      return true;
     }

   void RecoverTradeManagement(void)
     {
      m_trade_mgmt.Recover();
     }

   void SetLevelGate(CGmLevelGate *gate) { m_level_gate = gate; }
   void SetH4Session(CGmH4SessionEngine *session) { m_h4_session = session; }
   void SetH4CycleId(const datetime cycle_id) { m_h4_cycle_id = cycle_id; }

   /// @brief Register a newly placed pending in the trade registry.
   bool RegisterPending(const ulong trade_id,
                        const ulong order_ticket,
                        const string level_tag,
                        const ENUM_GM_LEVEL_SIDE side,
                        const double entry,
                        const double sl,
                        const double tp,
                        const double lots,
                        const datetime h4_cycle)
     {
      SGmTradeRecord rec;
      rec.Reset();
      rec.used = true;
      rec.trade_id = trade_id;
      rec.order_ticket = order_ticket;
      rec.magic = m_magic;
      rec.symbol = m_symbol;
      rec.level_tag = level_tag;
      rec.direction = side;
      rec.h4_cycle_id = h4_cycle;
      rec.entry_price = entry;
      rec.stop_loss = sl;
      rec.take_profit = tp;
      rec.volume = lots;
      rec.status = GM_TRADE_STATUS_PENDING;
      rec.stage = GM_TRADE_STAGE_NEW;
      rec.lifecycle = GM_LIFE_OPEN;
      rec.trade_attempts = 1;
      return m_registry.Upsert(rec);
     }

   /// @brief Handle deal add — pending filled into market position.
   void OnDealAdd(const ulong deal_ticket)
     {
      if(deal_ticket == 0 || !HistoryDealSelect(deal_ticket))
         return;

      if((long)HistoryDealGetInteger(deal_ticket, DEAL_MAGIC) != m_magic)
         return;
      if(HistoryDealGetString(deal_ticket, DEAL_SYMBOL) != m_symbol)
         return;

      const long entry_flag = HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
      if(entry_flag != DEAL_ENTRY_IN)
         return;

      const ulong position_ticket = (ulong)HistoryDealGetInteger(deal_ticket, DEAL_POSITION_ID);
      if(position_ticket == 0)
         return;
      if(!m_ownership.CanManagePosition(position_ticket, true))
         return;

      if(!PositionSelectByTicket(position_ticket))
         return;

      const string comment = PositionGetString(POSITION_COMMENT);
      const ulong trade_id = CGmTradeIdManager::ExtractTradeId(comment);
      const string level_tag = CGmTradeIdManager::ExtractLevelTag(comment);
      const double entry = PositionGetDouble(POSITION_PRICE_OPEN);
      const datetime open_time = (datetime)PositionGetInteger(POSITION_TIME);
      const long pos_type = PositionGetInteger(POSITION_TYPE);
      const ENUM_GM_LEVEL_SIDE side =
         (pos_type == POSITION_TYPE_BUY) ? GM_LEVEL_SIDE_BUY : GM_LEVEL_SIDE_SELL;

      if(m_logger != NULL)
         m_logger.Success(StringFormat("TRADE OPEN | TID=%I64u ticket=%I64u tag=%s entry=%.5f Magic=%I64d H4=%s",
                                       trade_id, position_ticket, level_tag, entry, m_magic,
                                       TimeToString(m_h4_cycle_id, TIME_DATE | TIME_MINUTES)),
                          "TradeManager");

      double sl = 0.0, tp = 0.0;
      EnsureStops(position_ticket, sl, tp);

      const double vol = PositionSelectByTicket(position_ticket)
                         ? PositionGetDouble(POSITION_VOLUME) : 0.0;

      if(trade_id > 0 && m_registry != NULL)
        {
         SGmTradeRecord existing;
         if(m_registry.GetByTradeId(trade_id, existing))
           {
            m_registry.MarkActive(trade_id, position_ticket, entry, sl, tp, open_time);
           }
         else
           {
            SGmTradeRecord rec;
            rec.Reset();
            rec.used = true;
            rec.trade_id = trade_id;
            rec.ticket = position_ticket;
            rec.magic = m_magic;
            rec.symbol = m_symbol;
            rec.level_tag = level_tag;
            rec.direction = side;
            rec.h4_cycle_id = m_h4_cycle_id;
            rec.open_time = open_time;
            rec.entry_price = entry;
            rec.stop_loss = sl;
            rec.take_profit = tp;
            rec.volume = vol;
            rec.original_volume = vol;
            rec.status = GM_TRADE_STATUS_ACTIVE;
            rec.stage = GM_TRADE_STAGE_RUNNING;
            rec.lifecycle = GM_LIFE_OPEN;
            rec.trade_attempts = 1;
            m_registry.Upsert(rec);
           }
        }

      if(m_logger != NULL)
         m_logger.Info(StringFormat("Registered active trade | TID=%I64u SL=%.5f TP=%.5f",
                                    trade_id, sl, tp),
                       "TradeManager");

      if(m_level_gate != NULL)
         m_level_gate.NotifyActivated(level_tag, trade_id, position_ticket, entry);

      if(m_h4_session != NULL)
         m_h4_session.OnTradeOpened(trade_id, position_ticket);
     }

   void OnDealClose(const ulong deal_ticket)
     {
      if(deal_ticket == 0 || !HistoryDealSelect(deal_ticket))
         return;
      if((long)HistoryDealGetInteger(deal_ticket, DEAL_MAGIC) != m_magic)
         return;
      if(HistoryDealGetString(deal_ticket, DEAL_SYMBOL) != m_symbol)
         return;

      const long entry_flag = HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
      if(entry_flag != DEAL_ENTRY_OUT && entry_flag != DEAL_ENTRY_OUT_BY)
         return;

      const string comment = HistoryDealGetString(deal_ticket, DEAL_COMMENT);
      string level_tag = CGmTradeIdManager::ExtractLevelTag(comment);
      ulong trade_id = CGmTradeIdManager::ExtractTradeId(comment);

      // Broker may strip comment on exit — resolve via position id from registry.
      const ulong pos_id = (ulong)HistoryDealGetInteger(deal_ticket, DEAL_POSITION_ID);
      if((trade_id == 0 || StringLen(level_tag) == 0) && m_registry != NULL && pos_id > 0)
        {
         SGmTradeRecord rec;
         if(m_registry.GetByTicket(pos_id, rec))
           {
            if(trade_id == 0)
               trade_id = rec.trade_id;
            if(StringLen(level_tag) == 0)
               level_tag = rec.level_tag;
           }
        }

      // Partial close: position still open — do NOT fire lifecycle close.
      if(pos_id > 0 && PositionSelectByTicket(pos_id))
        {
         if(m_logger != NULL)
            m_logger.Info(StringFormat("Partial close deal (runner remains) | ticket=%I64u vol=%.2f",
                                       pos_id, PositionGetDouble(POSITION_VOLUME)),
                          "TradeManager");
         return;
        }

      const long reason = HistoryDealGetInteger(deal_ticket, DEAL_REASON);
      const bool is_tp = (reason == DEAL_REASON_TP);
      const bool is_sl = (reason == DEAL_REASON_SL);
      const double pnl = HistoryDealGetDouble(deal_ticket, DEAL_PROFIT)
                         + HistoryDealGetDouble(deal_ticket, DEAL_SWAP)
                         + HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION);

      if(m_logger != NULL)
         m_logger.Info(StringFormat("Trade Closed | tag=%s TID=%I64u TP=%s SL=%s pnl=%.2f reason=%d",
                                    level_tag, trade_id,
                                    is_tp ? "Y" : "N", is_sl ? "Y" : "N",
                                    pnl, (int)reason),
                       "TradeManager");

      if(m_registry != NULL && pos_id > 0)
        {
         SGmTradeRecord rec;
         if(m_registry.GetByTicket(pos_id, rec))
           {
            rec.status = GM_TRADE_STATUS_CLOSED;
            rec.stage = GM_TRADE_STAGE_CLOSED;
            rec.lifecycle = GM_LIFE_CLOSED;
            m_registry.Upsert(rec);
           }
        }

      if(m_level_gate != NULL && StringLen(level_tag) > 0)
         m_level_gate.NotifyClosed(level_tag, trade_id, is_tp, is_sl, pnl);

      if(m_h4_session != NULL)
         m_h4_session.OnTradeClosed(trade_id);
     }

   void OnTradeTransaction(const MqlTradeTransaction &trans,
                           const MqlTradeRequest &request,
                           const MqlTradeResult &result)
     {
      if(StringLen(request.symbol) < 0 && result.retcode == UINT_MAX)
         return;

      if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
        {
         OnDealAdd(trans.deal);
         OnDealClose(trans.deal);
        }
     }

   /// @brief Scan unprotected own positions (restart safety).
   void ProtectUncoveredPositions(void)
     {
      const int total = PositionsTotal();
      for(int i = 0; i < total; i++)
        {
         const ulong ticket = PositionGetTicket(i);
         if(ticket == 0 || !PositionSelectByTicket(ticket))
            continue;
         if((long)PositionGetInteger(POSITION_MAGIC) != m_magic)
            continue;
         if(PositionGetString(POSITION_SYMBOL) != m_symbol)
            continue;

         const double sl = PositionGetDouble(POSITION_SL);
         const double tp = PositionGetDouble(POSITION_TP);
         if(sl > 0.0 && tp > 0.0)
            continue;

         if(m_logger != NULL)
            m_logger.Warning(StringFormat("Unprotected position found | ticket=%I64u — attaching SL/TP",
                                          ticket),
                             "TradeManager");
         double out_sl = 0.0, out_tp = 0.0;
         EnsureStops(ticket, out_sl, out_tp);
        }
     }

   virtual bool Process(void)
     {
      if(m_registry != NULL)
         m_registry.SyncFromTerminal();
      m_trade_mgmt.Process();
      return true;
     }
  };

#endif // GM_CTRADE_MANAGER_MQH
//+------------------------------------------------------------------+
