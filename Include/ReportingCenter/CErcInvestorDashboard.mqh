//+------------------------------------------------------------------+
//|                                    CErcInvestorDashboard.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CERC_INVESTOR_DASHBOARD_MQH
#define GM_CERC_INVESTOR_DASHBOARD_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmReportingCenterResult.mqh"
#include "../PortfolioAnalytics/SGmPortfolioAnalyticsResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmErcInvestorDashboard
  {
private:
   CGmLogger *m_logger;

   double Clamp100(const double v) const
     {
      if(v < 0.0) return 0.0;
      if(v > 100.0) return 100.0;
      return v;
     }

public:
                     CGmErcInvestorDashboard(void) : m_logger(NULL) {}

   void Init(CGmLogger *logger) { m_logger = logger; }

   void Build(const SGmPortfolioAnalyticsResult &epa, SGmReportingCenterResult &out)
     {
      out.portfolio_value = AccountInfoDouble(ACCOUNT_EQUITY);
      out.account_growth_pct = epa.capital_growth_pct;
      out.capital_growth_pct = epa.capital_growth_pct;
      out.net_profit = epa.yearly_pnl;
      out.profit_factor = epa.profit_factor;
      out.max_drawdown_pct = epa.max_drawdown_pct;
      out.recovery_factor = epa.recovery_factor;
      out.avg_monthly_return = epa.monthly_pnl;

      // Gross profit / loss proxies from PF and net
      if(epa.profit_factor > 0.0 && epa.yearly_pnl != 0.0)
        {
         // net = GP - GL; PF = GP/GL => GP = PF*GL; net = PF*GL - GL = GL*(PF-1)
         if(epa.yearly_pnl >= 0.0 && epa.profit_factor > 1.0)
           {
            out.gross_loss = epa.yearly_pnl / (epa.profit_factor - 1.0);
            out.gross_profit = out.gross_loss * epa.profit_factor;
           }
         else if(epa.yearly_pnl < 0.0)
           {
            out.gross_loss = MathAbs(epa.yearly_pnl) * 1.5;
            out.gross_profit = out.gross_loss * MathMax(0.1, epa.profit_factor);
           }
         else
           {
            out.gross_profit = MathMax(0.0, epa.yearly_pnl);
            out.gross_loss = 0.0;
           }
        }
      else
        {
         out.gross_profit = MathMax(0.0, epa.yearly_pnl);
         out.gross_loss = MathMax(0.0, -epa.yearly_pnl);
        }

      out.investor_rating = Clamp100(
         0.30 * epa.portfolio_health +
         0.25 * MathMin(100.0, epa.profit_factor * 25.0) +
         0.25 * (100.0 - MathMin(100.0, epa.max_drawdown_pct)) +
         0.20 * epa.risk_stability);

      out.investor_summary = StringFormat(
         "INVESTOR DASHBOARD | Value=%.2f Growth=%.1f%% Net=%.2f GP=%.2f GL=%.2f "
         "PF=%.2f MaxDD=%.1f%% RF=%.2f AvgM=%.2f Rating=%.0f",
         out.portfolio_value, out.account_growth_pct, out.net_profit,
         out.gross_profit, out.gross_loss, out.profit_factor,
         out.max_drawdown_pct, out.recovery_factor, out.avg_monthly_return,
         out.investor_rating);

      if(m_logger != NULL)
         m_logger.Info("Investor Dashboard Updated | Rating=" +
                       DoubleToString(out.investor_rating, 0), "ERC");
     }
  };

#endif // GM_CERC_INVESTOR_DASHBOARD_MQH
//+------------------------------------------------------------------+
