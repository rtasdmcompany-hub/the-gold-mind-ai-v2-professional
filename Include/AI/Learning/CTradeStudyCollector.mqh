//+------------------------------------------------------------------+
//|                                       CTradeStudyCollector.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CTRADE_STUDY_COLLECTOR_MQH
#define GM_CTRADE_STUDY_COLLECTOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "LearningAIConstants.mqh"

struct SGmTradeStudyStats
  {
   int wins;
   int losses;
   int total;
   int sl_like;
   int be_proxy;
   int recovery_proxy;
   int second_proxy;
   int h4_buckets;

   void Reset(void)
     {
      wins = losses = total = 0;
      sl_like = be_proxy = recovery_proxy = second_proxy = 0;
      h4_buckets = 0;
     }
  };

/// @brief Read-only study of deal history for Gold Mind magic/symbol.
class CGmTradeStudyCollector
  {
public:
   bool Collect(const string symbol, const long magic, SGmTradeStudyStats &st)
     {
      st.Reset();
      const datetime to = TimeCurrent();
      const datetime from = to - GM_LEARN_LOOKBACK_DAYS * 86400;
      if(!HistorySelect(from, to + 60))
         return false;

      const double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      const double pip = (point > 0.0) ? point * 10.0 : 0.0;

      datetime last_loss_day = 0;
      bool last_was_loss = false;
      datetime h4_marks[];
      ArrayResize(h4_marks, 0);

      const int deals = HistoryDealsTotal();
      for(int i = 0; i < deals; i++)
        {
         const ulong deal = HistoryDealGetTicket(i);
         if(deal == 0)
            continue;
         if(HistoryDealGetInteger(deal, DEAL_MAGIC) != magic)
            continue;
         if(HistoryDealGetString(deal, DEAL_SYMBOL) != symbol)
            continue;
         const long entry = HistoryDealGetInteger(deal, DEAL_ENTRY);
         if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY)
            continue;

         const double profit = HistoryDealGetDouble(deal, DEAL_PROFIT)
                               + HistoryDealGetDouble(deal, DEAL_SWAP)
                               + HistoryDealGetDouble(deal, DEAL_COMMISSION);
         const datetime t = (datetime)HistoryDealGetInteger(deal, DEAL_TIME);
         st.total++;
         if(profit >= 0.0)
           {
            st.wins++;
            if(last_was_loss)
               st.second_proxy++;
            if(last_loss_day > 0 && (t / 86400) == (last_loss_day / 86400))
               st.recovery_proxy++;
            if(profit > 0.0 && profit < 15.0)
               st.be_proxy++;
            last_was_loss = false;
           }
         else
           {
            st.losses++;
            last_was_loss = true;
            last_loss_day = t;
            if(pip > 0.0 && MathAbs(profit) >= 20.0 && MathAbs(profit) <= 80.0)
               st.sl_like++;
           }

         const datetime h4 = t - (t % (4 * 3600));
         bool seen = false;
         for(int k = 0; k < ArraySize(h4_marks); k++)
           {
            if(h4_marks[k] == h4)
              {
               seen = true;
               break;
              }
           }
         if(!seen)
           {
            const int n = ArraySize(h4_marks);
            ArrayResize(h4_marks, n + 1);
            h4_marks[n] = h4;
           }
        }
      st.h4_buckets = ArraySize(h4_marks);
      return true;
     }
  };

#endif // GM_CTRADE_STUDY_COLLECTOR_MQH
//+------------------------------------------------------------------+
