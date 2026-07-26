//+------------------------------------------------------------------+
//|                               CMacCapitalAllocationAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CMAC_CAPITAL_ALLOCATION_ANALYZER_MQH
#define GM_CMAC_CAPITAL_ALLOCATION_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMultiAccountCenterResult.mqh"
#include "../PortfolioAnalytics/SGmPortfolioAnalyticsResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmMacCapitalAllocationAnalyzer
  {
private:
   CGmLogger *m_logger;
   double     m_alloc_score;
   double     m_balance_score;

   double Clamp100(const double v) const
     {
      if(v < 0.0) return 0.0;
      if(v > 100.0) return 100.0;
      return v;
     }

public:
                     CGmMacCapitalAllocationAnalyzer(void)
                       : m_logger(NULL), m_alloc_score(0.0), m_balance_score(0.0) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_alloc_score = m_balance_score = 0.0;
     }

   void Analyze(const bool licensed,
                const SGmPortfolioAnalyticsResult &epa,
                SGmMultiAccountCenterResult &out)
     {
      if(!licensed)
        {
         out.total_capital = out.used_margin = out.free_margin = 0.0;
         out.equity = out.balance = 0.0;
         out.daily_growth_pct = out.monthly_growth_pct = 0.0;
         out.capital_allocation_score = out.portfolio_balance_score = 0.0;
         out.capital_report = "Capital analytics suppressed — account unlicensed\r\n";
         return;
        }

      out.balance = AccountInfoDouble(ACCOUNT_BALANCE);
      out.equity = AccountInfoDouble(ACCOUNT_EQUITY);
      out.used_margin = AccountInfoDouble(ACCOUNT_MARGIN);
      out.free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      out.total_capital = out.equity;
      out.daily_growth_pct = epa.capital_growth_pct * 0.05;
      out.monthly_growth_pct = epa.capital_growth_pct;

      const double margin_level = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
      double alloc = 55.0;
      alloc += MathMin(15.0, epa.capital_efficiency * 0.15);
      alloc += MathMin(10.0, epa.portfolio_health * 0.1);
      if(out.free_margin > 0.0 && out.equity > 0.0)
         alloc += MathMin(15.0, (out.free_margin / out.equity) * 20.0);
      m_alloc_score = Clamp100(alloc);

      double bal = 50.0;
      bal += MathMin(20.0, (100.0 - MathMin(100.0, epa.max_drawdown_pct)) * 0.2);
      bal += MathMin(15.0, epa.risk_stability * 0.15);
      bal += (margin_level <= 0.0 || margin_level > 200.0 ? 10.0 : 4.0);
      m_balance_score = Clamp100(bal);

      out.capital_allocation_score = m_alloc_score;
      out.portfolio_balance_score = m_balance_score;
      out.capital_report = StringFormat(
         "=== CAPITAL ALLOCATION ===\r\n"
         "Total=%.2f Equity=%.2f Balance=%.2f UsedMargin=%.2f Free=%.2f\r\n"
         "DailyGrowth=%.2f%% MonthlyGrowth=%.2f%% | AllocScore=%.0f BalanceScore=%.0f\r\n"
         "Distribution/RiskDistribution=Catalog | MONITORING ONLY\r\n",
         out.total_capital, out.equity, out.balance, out.used_margin, out.free_margin,
         out.daily_growth_pct, out.monthly_growth_pct, m_alloc_score, m_balance_score);

      if(m_logger != NULL)
         m_logger.Info(StringFormat("Capital Analysis Completed | Alloc=%.0f Balance=%.0f",
                                    m_alloc_score, m_balance_score), "MAC");
     }
  };

#endif // GM_CMAC_CAPITAL_ALLOCATION_ANALYZER_MQH
//+------------------------------------------------------------------+
