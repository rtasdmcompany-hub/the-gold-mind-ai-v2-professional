//+------------------------------------------------------------------+
//|                                          CTradeJournal.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CTRADE_JOURNAL_MQH
#define GM_CTRADE_JOURNAL_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmTradeJournalRecord.mqh"
#include "JournalConstants.mqh"
#include "../Logging/CLogger.mqh"
#include "../TradeManagement/CPipTools.mqh"

/// @file CTradeJournal.mqh
/// @brief Live Trade Journal — records Gold Mind trades (READ-ONLY sync).

class CGmTradeJournal
  {
private:
   CGmLogger            *m_logger;
   SGmTradeJournalRecord m_items[GM_TRADE_JOURNAL_MAX];
   int                   m_count;
   long                  m_magic;
   string                m_symbol;

   int FindByTradeId(const ulong trade_id) const
     {
      for(int i = 0; i < m_count; i++)
        {
         if(m_items[i].used && m_items[i].trade_id == trade_id)
            return i;
        }
      return -1;
     }

   int Alloc(void)
     {
      if(m_count < GM_TRADE_JOURNAL_MAX)
        {
         const int idx = m_count++;
         m_items[idx].Reset();
         m_items[idx].used = true;
         return idx;
        }
      // drop oldest
      for(int i = 1; i < GM_TRADE_JOURNAL_MAX; i++)
         m_items[i - 1] = m_items[i];
      m_items[GM_TRADE_JOURNAL_MAX - 1].Reset();
      m_items[GM_TRADE_JOURNAL_MAX - 1].used = true;
      return GM_TRADE_JOURNAL_MAX - 1;
     }

public:
                     CGmTradeJournal(void)
                       : m_logger(NULL), m_count(0), m_magic(0), m_symbol("")
     {
     }

   void Init(CGmLogger *logger, const long magic, const string symbol)
     {
      m_logger = logger;
      m_magic = magic;
      m_symbol = symbol;
      m_count = 0;
     }

   int Count(void) const { return m_count; }

   bool GetAt(const int index, SGmTradeJournalRecord &out) const
     {
      if(index < 0 || index >= m_count || !m_items[index].used)
         return false;
      out = m_items[index];
      return true;
     }

   void Upsert(const SGmTradeJournalRecord &rec)
     {
      if(rec.trade_id == 0)
         return;
      int idx = FindByTradeId(rec.trade_id);
      if(idx < 0)
         idx = Alloc();
      m_items[idx] = rec;
      m_items[idx].used = true;
      if(m_logger != NULL)
         m_logger.Debug(StringFormat("Trade Recorded | TID=%I64u | %s | %.2f",
                                     rec.trade_id, rec.result, rec.profit_loss),
                        "TradeJournal");
     }

   /// @brief Sync closed deals + open positions for magic/symbol.
   void SyncFromTerminal(void)
     {
      // Open positions
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         const ulong ticket = PositionGetTicket(i);
         if(ticket == 0)
            continue;
         if(PositionGetInteger(POSITION_MAGIC) != m_magic)
            continue;
         if(StringLen(m_symbol) > 0 && PositionGetString(POSITION_SYMBOL) != m_symbol)
            continue;

         SGmTradeJournalRecord r;
         r.Reset();
         r.trade_id = ticket;
         r.magic = m_magic;
         r.symbol = PositionGetString(POSITION_SYMBOL);
         r.side = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? "BUY" : "SELL";
         r.lot_size = PositionGetDouble(POSITION_VOLUME);
         r.entry_price = PositionGetDouble(POSITION_PRICE_OPEN);
         r.stop_loss = PositionGetDouble(POSITION_SL);
         r.take_profit = PositionGetDouble(POSITION_TP);
         r.open_time = (datetime)PositionGetInteger(POSITION_TIME);
         r.close_time = 0;
         r.duration_sec = (double)(TimeCurrent() - r.open_time);
         r.profit_loss = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
         r.pips = CGmPipTools::ProfitPips(r.symbol, PositionGetInteger(POSITION_TYPE), r.entry_price);
         r.result = "OPEN";
         r.trade_stage = "RUNNING";
         r.attempt_number = 1;
         r.session_id = 0;
         r.is_open = true;
         r.is_recovery = false;
         Upsert(r);
        }

      // Closed deals (recent year)
      const datetime now = TimeCurrent();
      if(!HistorySelect(now - 365 * 86400, now + 60))
         return;
      const int deals = HistoryDealsTotal();
      for(int i = 0; i < deals; i++)
        {
         const ulong deal = HistoryDealGetTicket(i);
         if(deal == 0)
            continue;
         if(HistoryDealGetInteger(deal, DEAL_MAGIC) != m_magic)
            continue;
         if(StringLen(m_symbol) > 0 &&
            HistoryDealGetString(deal, DEAL_SYMBOL) != m_symbol)
            continue;
         if(HistoryDealGetInteger(deal, DEAL_ENTRY) != DEAL_ENTRY_OUT &&
            HistoryDealGetInteger(deal, DEAL_ENTRY) != DEAL_ENTRY_OUT_BY)
            continue;

         const ulong pos_id = (ulong)HistoryDealGetInteger(deal, DEAL_POSITION_ID);
         SGmTradeJournalRecord r;
         r.Reset();
         r.trade_id = (pos_id > 0) ? pos_id : deal;
         r.magic = m_magic;
         r.symbol = HistoryDealGetString(deal, DEAL_SYMBOL);
         const long dtype = HistoryDealGetInteger(deal, DEAL_TYPE);
         r.side = (dtype == DEAL_TYPE_SELL) ? "BUY" : "SELL"; // closing deal opposite
         r.lot_size = HistoryDealGetDouble(deal, DEAL_VOLUME);
         r.entry_price = HistoryDealGetDouble(deal, DEAL_PRICE);
         r.close_time = (datetime)HistoryDealGetInteger(deal, DEAL_TIME);
         r.open_time = r.close_time;
         r.profit_loss = HistoryDealGetDouble(deal, DEAL_PROFIT)
                         + HistoryDealGetDouble(deal, DEAL_SWAP)
                         + HistoryDealGetDouble(deal, DEAL_COMMISSION);
         r.pips = 0.0;
         r.result = (r.profit_loss >= 0.0) ? "WIN" : "LOSS";
         r.trade_stage = "CLOSED";
         r.attempt_number = 1;
         r.is_open = false;
         r.is_recovery = false;
         // find IN deal for open time / entry
         for(int j = 0; j < deals; j++)
           {
            const ulong d2 = HistoryDealGetTicket(j);
            if(d2 == 0)
               continue;
            if((ulong)HistoryDealGetInteger(d2, DEAL_POSITION_ID) != pos_id)
               continue;
            if(HistoryDealGetInteger(d2, DEAL_ENTRY) == DEAL_ENTRY_IN)
              {
               r.open_time = (datetime)HistoryDealGetInteger(d2, DEAL_TIME);
               r.entry_price = HistoryDealGetDouble(d2, DEAL_PRICE);
               break;
              }
           }
         if(r.close_time > r.open_time)
            r.duration_sec = (double)(r.close_time - r.open_time);
         Upsert(r);
        }

      if(m_logger != NULL)
         m_logger.Debug(StringFormat("Journal Updated | trades=%d", m_count), "TradeJournal");
     }
  };

#endif // GM_CTRADE_JOURNAL_MQH
//+------------------------------------------------------------------+
