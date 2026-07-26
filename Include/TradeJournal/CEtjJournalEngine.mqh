//+------------------------------------------------------------------+
//|                                         CEtjJournalEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     OBSERVE-ONLY — Gold Mind magic/symbol trades only           |
//+------------------------------------------------------------------+
#ifndef GM_CETJ_JOURNAL_ENGINE_MQH
#define GM_CETJ_JOURNAL_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmEtjTradeRecord.mqh"
#include "../Logging/CLogger.mqh"
#include "../Calculation/LevelConstants.mqh"

class CGmEtjJournalEngine
  {
private:
   CGmLogger         *m_logger;
   SGmEtjTradeRecord  m_trades[GM_ETJ_MAX_TRADES];
   int                m_count;
   long               m_magic;
   string             m_symbol;
   int                m_recorded_new;

   ulong ParseTid(const string comment) const
     {
      const int pos = StringFind(comment, GM_TRADE_ID_MARKER);
      if(pos < 0)
         return 0;
      return (ulong)StringToInteger(StringSubstr(comment, pos + StringLen(GM_TRADE_ID_MARKER)));
     }

   int FindByTicket(const ulong ticket) const
     {
      for(int i = 0; i < m_count; i++)
         if(m_trades[i].used && m_trades[i].ticket == ticket)
            return i;
      return -1;
     }

   int FindByPositionId(const ulong pid) const
     {
      for(int i = 0; i < m_count; i++)
         if(m_trades[i].used && m_trades[i].position_id == pid && pid != 0)
            return i;
      return -1;
     }

   int Alloc(void)
     {
      if(m_count < GM_ETJ_MAX_TRADES)
        {
         const int idx = m_count++;
         m_trades[idx].Reset();
         m_trades[idx].used = true;
         return idx;
        }
      for(int i = 1; i < GM_ETJ_MAX_TRADES; i++)
         m_trades[i - 1] = m_trades[i];
      m_trades[GM_ETJ_MAX_TRADES - 1].Reset();
      m_trades[GM_ETJ_MAX_TRADES - 1].used = true;
      return GM_ETJ_MAX_TRADES - 1;
     }

   bool IsOwn(const long magic, const string symbol) const
     {
      return (magic == m_magic && symbol == m_symbol);
     }

   double PointSize(void) const
     {
      const double p = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      return (p > 0.0) ? p : 0.01;
     }

public:
                     CGmEtjJournalEngine(void)
                       : m_logger(NULL), m_count(0), m_magic(0), m_symbol(""), m_recorded_new(0) {}

   void Init(CGmLogger *logger, const long magic, const string symbol)
     {
      m_logger = logger;
      m_magic = magic;
      m_symbol = symbol;
      m_count = 0;
      m_recorded_new = 0;
     }

   int Count(void) const { return m_count; }
   int NewRecorded(void) const { return m_recorded_new; }

   bool GetAt(const int index, SGmEtjTradeRecord &out) const
     {
      if(index < 0 || index >= m_count || !m_trades[index].used)
         return false;
      out = m_trades[index];
      return true;
     }

   int CountOpen(void) const
     {
      int n = 0;
      for(int i = 0; i < m_count; i++)
         if(m_trades[i].used && m_trades[i].status == GM_ETJ_ST_OPEN)
            n++;
      return n;
     }

   int CountToday(void) const
     {
      MqlDateTime now;
      TimeToStruct(TimeCurrent(), now);
      int n = 0;
      for(int i = 0; i < m_count; i++)
        {
         if(!m_trades[i].used) continue;
         MqlDateTime ot;
         TimeToStruct(m_trades[i].open_time, ot);
         if(ot.year == now.year && ot.mon == now.mon && ot.day == now.day)
            n++;
        }
      return n;
     }

   /// @brief Sync open positions + closed deals for this magic/symbol only.
   void SyncFromTerminal(void)
     {
      m_recorded_new = 0;

      // Open positions (Gold Mind only)
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         const ulong ticket = PositionGetTicket(i);
         if(ticket == 0 || !PositionSelectByTicket(ticket))
            continue;
         if(!IsOwn((long)PositionGetInteger(POSITION_MAGIC),
                   PositionGetString(POSITION_SYMBOL)))
            continue;

         const ulong pid = (ulong)PositionGetInteger(POSITION_IDENTIFIER);
         int idx = FindByPositionId(pid);
         if(idx < 0)
            idx = FindByTicket(ticket);
         const bool is_new = (idx < 0);
         if(is_new)
            idx = Alloc();

         SGmEtjTradeRecord r = m_trades[idx];
         r.used = true;
         r.ticket = ticket;
         r.position_id = pid;
         r.magic = m_magic;
         r.symbol = m_symbol;
         r.side = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                  ? GM_ETJ_SIDE_BUY : GM_ETJ_SIDE_SELL;
         r.status = GM_ETJ_ST_OPEN;
         r.open_time = (datetime)PositionGetInteger(POSITION_TIME);
         r.h4_candle_time = r.open_time - (r.open_time % (4 * PeriodSeconds(PERIOD_H1)));
         r.entry_price = PositionGetDouble(POSITION_PRICE_OPEN);
         r.stop_loss = PositionGetDouble(POSITION_SL);
         r.take_profit = PositionGetDouble(POSITION_TP);
         r.lot_size = PositionGetDouble(POSITION_VOLUME);
         r.profit_loss = PositionGetDouble(POSITION_PROFIT)
                         + PositionGetDouble(POSITION_SWAP);
         r.swap = PositionGetDouble(POSITION_SWAP);
         r.commission = 0.0;
         r.spread = (double)SymbolInfoInteger(m_symbol, SYMBOL_SPREAD) * PointSize();
         r.duration_sec = (int)(TimeCurrent() - r.open_time);
         r.market_session = GmEtjSessionName(r.open_time);
         r.level_tag = PositionGetString(POSITION_COMMENT);
         const ulong tid = ParseTid(r.level_tag);
         if(tid > 0)
            r.trade_id = tid;
         else if(r.trade_id == 0)
            r.trade_id = pid;

         // Infer lifecycle flags from comment / SL proximity (observe-only heuristics)
         if(r.break_even == false && r.stop_loss > 0.0)
           {
            const double be_tol = 5.0 * PointSize();
            if(MathAbs(r.stop_loss - r.entry_price) <= be_tol)
               r.break_even = true;
           }

         m_trades[idx] = r;
         if(is_new)
           {
            m_recorded_new++;
            if(m_logger != NULL)
               m_logger.Info(StringFormat("Trade Recorded | TID=%I64u | %s | open",
                                          r.trade_id, GmEtjSideName(r.side)), "ETJ");
           }
        }

      // Closed deals (history window)
      const datetime from = TimeCurrent() - (datetime)(GM_ETJ_HIST_DAYS * 86400);
      if(!HistorySelect(from, TimeCurrent()))
         return;

      for(int d = HistoryDealsTotal() - 1; d >= 0; d--)
        {
         const ulong deal = HistoryDealGetTicket(d);
         if(deal == 0)
            continue;
         if(!IsOwn((long)HistoryDealGetInteger(deal, DEAL_MAGIC),
                   HistoryDealGetString(deal, DEAL_SYMBOL)))
            continue;
         const long entry = HistoryDealGetInteger(deal, DEAL_ENTRY);
         if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY)
            continue;

         const ulong pid = (ulong)HistoryDealGetInteger(deal, DEAL_POSITION_ID);
         int idx = FindByPositionId(pid);
         const bool is_new = (idx < 0);
         if(is_new)
            idx = Alloc();

         SGmEtjTradeRecord r = m_trades[idx];
         r.used = true;
         r.position_id = pid;
         r.magic = m_magic;
         r.symbol = m_symbol;
         r.status = GM_ETJ_ST_CLOSED;
         r.close_time = (datetime)HistoryDealGetInteger(deal, DEAL_TIME);
         r.exit_price = HistoryDealGetDouble(deal, DEAL_PRICE);
         r.profit_loss = HistoryDealGetDouble(deal, DEAL_PROFIT)
                         + HistoryDealGetDouble(deal, DEAL_SWAP)
                         + HistoryDealGetDouble(deal, DEAL_COMMISSION);
         r.swap = HistoryDealGetDouble(deal, DEAL_SWAP);
         r.commission = HistoryDealGetDouble(deal, DEAL_COMMISSION);
         r.lot_size = HistoryDealGetDouble(deal, DEAL_VOLUME);
         const long dtype = HistoryDealGetInteger(deal, DEAL_TYPE);
         r.side = (dtype == DEAL_TYPE_SELL) ? GM_ETJ_SIDE_BUY : GM_ETJ_SIDE_SELL;
         // Resolve open from IN deal
         const int deals = HistoryDealsTotal();
         for(int j = 0; j < deals; j++)
           {
            const ulong d2 = HistoryDealGetTicket(j);
            if(d2 == 0)
               continue;
            if((ulong)HistoryDealGetInteger(d2, DEAL_POSITION_ID) != pid)
               continue;
            if(HistoryDealGetInteger(d2, DEAL_ENTRY) == DEAL_ENTRY_IN)
              {
               r.open_time = (datetime)HistoryDealGetInteger(d2, DEAL_TIME);
               r.entry_price = HistoryDealGetDouble(d2, DEAL_PRICE);
               const ulong tid2 = ParseTid(HistoryDealGetString(d2, DEAL_COMMENT));
               if(tid2 > 0)
                  r.trade_id = tid2;
               break;
              }
           }
         if(r.open_time == 0)
            r.open_time = r.close_time;
         if(r.entry_price <= 0.0)
            r.entry_price = r.exit_price;
         r.duration_sec = (int)MathMax(0, r.close_time - r.open_time);
         r.h4_candle_time = r.open_time - (r.open_time % (4 * PeriodSeconds(PERIOD_H1)));
         r.market_session = GmEtjSessionName(r.open_time);
         if(r.trade_id == 0)
            r.trade_id = pid;
         r.spread = (double)SymbolInfoInteger(m_symbol, SYMBOL_SPREAD) * PointSize();

         m_trades[idx] = r;
         if(is_new)
           {
            m_recorded_new++;
            if(m_logger != NULL)
               m_logger.Info(StringFormat("Trade Recorded | TID=%I64u | closed | P/L=%.2f",
                                          r.trade_id, r.profit_loss), "ETJ");
           }
        }
     }
  };

#endif // GM_CETJ_JOURNAL_ENGINE_MQH
//+------------------------------------------------------------------+
