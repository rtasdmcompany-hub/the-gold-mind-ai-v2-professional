//+------------------------------------------------------------------+
//|                                   CEpaPortfolioEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     OBSERVE-ONLY — Gold Mind magic/symbol closed deals          |
//+------------------------------------------------------------------+
#ifndef GM_CEPA_PORTFOLIO_ENGINE_MQH
#define GM_CEPA_PORTFOLIO_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmPortfolioAnalyticsResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmEpaPortfolioEngine
  {
private:
   CGmLogger *m_logger;
   long       m_magic;
   string     m_symbol;

   double     m_pnls[GM_EPA_EQUITY_MAX];
   datetime   m_times[GM_EPA_EQUITY_MAX];
   double     m_holds[GM_EPA_EQUITY_MAX];
   int        m_n;
   double     m_health;
   string     m_summary;

   bool IsOwn(const long magic, const string symbol) const
     {
      return (magic == m_magic && symbol == m_symbol);
     }

public:
                     CGmEpaPortfolioEngine(void)
                       : m_logger(NULL), m_magic(0), m_symbol(""), m_n(0),
                         m_health(0.0), m_summary("") {}

   void Init(CGmLogger *logger, const long magic, const string symbol)
     {
      m_logger = logger;
      m_magic = magic;
      m_symbol = symbol;
      m_n = 0;
      m_health = 0.0;
      m_summary = "Idle";
     }

   int Count(void) const { return m_n; }
   double Health(void) const { return m_health; }
   string Summary(void) const { return m_summary; }

   bool GetPnl(const int i, double &pnl, datetime &t, double &hold) const
     {
      if(i < 0 || i >= m_n) return false;
      pnl = m_pnls[i];
      t = m_times[i];
      hold = m_holds[i];
      return true;
     }

   void Collect(SGmPortfolioAnalyticsResult &out)
     {
      m_n = 0;
      out.daily_pnl = out.weekly_pnl = out.monthly_pnl = 0.0;
      out.quarterly_pnl = out.yearly_pnl = out.session_pnl = 0.0;

      const datetime now = TimeCurrent();
      const datetime from = now - (datetime)(GM_EPA_HIST_DAYS * 86400);
      if(!HistorySelect(from, now + 60))
        {
         m_health = 30.0;
         m_summary = "Portfolio history unavailable";
         return;
        }

      MqlDateTime nd;
      TimeToStruct(now, nd);
      const datetime week_ago = now - 7 * 86400;
      const datetime month_ago = now - 30 * 86400;
      const datetime quarter_ago = now - 90 * 86400;
      const datetime year_ago = now - 365 * 86400;

      const int deals = HistoryDealsTotal();
      for(int i = 0; i < deals; i++)
        {
         const ulong deal = HistoryDealGetTicket(i);
         if(deal == 0) continue;
         if(!IsOwn((long)HistoryDealGetInteger(deal, DEAL_MAGIC),
                   HistoryDealGetString(deal, DEAL_SYMBOL)))
            continue;
         const long entry = HistoryDealGetInteger(deal, DEAL_ENTRY);
         if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY)
            continue;

         const double pnl = HistoryDealGetDouble(deal, DEAL_PROFIT)
                            + HistoryDealGetDouble(deal, DEAL_SWAP)
                            + HistoryDealGetDouble(deal, DEAL_COMMISSION);
         const datetime ct = (datetime)HistoryDealGetInteger(deal, DEAL_TIME);

         // Holding time from matching IN deal
         double hold = 0.0;
         const ulong pid = (ulong)HistoryDealGetInteger(deal, DEAL_POSITION_ID);
         for(int j = 0; j < deals; j++)
           {
            const ulong d2 = HistoryDealGetTicket(j);
            if(d2 == 0) continue;
            if((ulong)HistoryDealGetInteger(d2, DEAL_POSITION_ID) != pid) continue;
            if(HistoryDealGetInteger(d2, DEAL_ENTRY) == DEAL_ENTRY_IN)
              {
               hold = (double)(ct - (datetime)HistoryDealGetInteger(d2, DEAL_TIME));
               break;
              }
           }

         if(m_n < GM_EPA_EQUITY_MAX)
           {
            m_pnls[m_n] = pnl;
            m_times[m_n] = ct;
            m_holds[m_n] = MathMax(0.0, hold);
            m_n++;
           }

         MqlDateTime ot;
         TimeToStruct(ct, ot);
         if(ot.year == nd.year && ot.mon == nd.mon && ot.day == nd.day)
            out.daily_pnl += pnl;
         if(ct >= week_ago) out.weekly_pnl += pnl;
         if(ct >= month_ago) out.monthly_pnl += pnl;
         if(ct >= quarter_ago) out.quarterly_pnl += pnl;
         if(ct >= year_ago) out.yearly_pnl += pnl;

         // Session bucket (close time)
         if(ot.hour >= 8 && ot.hour < 21)
            out.session_pnl += pnl;
        }

      out.trades_closed = m_n;

      // Growth vs starting capital proxy (AccountBalance)
      const double bal = AccountInfoDouble(ACCOUNT_BALANCE);
      const double eq = AccountInfoDouble(ACCOUNT_EQUITY);
      out.balance_growth_pct = 0.0;
      out.equity_growth_pct = 0.0;
      out.capital_growth_pct = 0.0;
      if(bal > 0.0)
        {
         // Approximate growth from yearly PnL / balance
         out.capital_growth_pct = 100.0 * out.yearly_pnl / bal;
         out.balance_growth_pct = out.capital_growth_pct;
         out.equity_growth_pct = 100.0 * (eq - bal) / bal + out.capital_growth_pct;
        }
      out.recovery_performance = (out.yearly_pnl >= 0.0) ? MathMin(100.0, 60.0 + out.monthly_pnl * 0.01)
                                                          : MathMax(0.0, 40.0 + out.monthly_pnl * 0.01);

      m_health = MathMin(100.0,
         45.0 + MathMin(25.0, (double)m_n * 0.5) +
         ((out.yearly_pnl >= 0.0) ? 15.0 : 0.0) +
         ((out.monthly_pnl >= 0.0) ? 10.0 : 0.0) +
         ((out.weekly_pnl >= 0.0) ? 5.0 : 0.0));

      m_summary = StringFormat(
         "Portfolio | Closed=%d D=%.2f W=%.2f M=%.2f Y=%.2f Health=%.0f",
         m_n, out.daily_pnl, out.weekly_pnl, out.monthly_pnl, out.yearly_pnl, m_health);

      if(m_logger != NULL)
         m_logger.Info("Portfolio Updated | " + m_summary, "EPA");
     }
  };

#endif // GM_CEPA_PORTFOLIO_ENGINE_MQH
//+------------------------------------------------------------------+
