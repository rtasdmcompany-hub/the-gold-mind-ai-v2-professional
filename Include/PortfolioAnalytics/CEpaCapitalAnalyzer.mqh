//+------------------------------------------------------------------+
//|                                  CEpaCapitalAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEPA_CAPITAL_ANALYZER_MQH
#define GM_CEPA_CAPITAL_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmPortfolioAnalyticsResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmEpaCapitalAnalyzer
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
                     CGmEpaCapitalAnalyzer(void) : m_logger(NULL) {}

   void Init(CGmLogger *logger) { m_logger = logger; }

   void Analyze(SGmPortfolioAnalyticsResult &out)
     {
      const double bal = AccountInfoDouble(ACCOUNT_BALANCE);
      const double eq = AccountInfoDouble(ACCOUNT_EQUITY);
      const double profit = AccountInfoDouble(ACCOUNT_PROFIT);

      // Compounding / retention proxies from period PnL
      const double retention = (out.yearly_pnl >= 0.0)
         ? Clamp100(70.0 + MathMin(25.0, out.yearly_pnl / MathMax(1.0, bal) * 100.0))
         : Clamp100(40.0 + out.yearly_pnl / MathMax(1.0, bal) * 50.0);

      const double reinvest = Clamp100(60.0 + out.monthly_pnl / MathMax(1.0, bal) * 80.0);
      const double withdraw_impact = Clamp100(100.0 - MathAbs(profit) / MathMax(1.0, bal) * 50.0);

      out.capital_efficiency = Clamp100(
         0.35 * retention +
         0.25 * reinvest +
         0.20 * (50.0 + out.capital_growth_pct * 0.5) +
         0.20 * withdraw_impact);

      out.capital_report = StringFormat(
         "Capital | Bal=%.2f Eq=%.2f Growth=%.1f%% Eff=%.0f Retention=%.0f Reinvest=%.0f",
         bal, eq, out.capital_growth_pct, out.capital_efficiency, retention, reinvest);

      if(m_logger != NULL)
         m_logger.Info("Capital Analysis Completed | " + out.capital_report, "EPA");
     }
  };

#endif // GM_CEPA_CAPITAL_ANALYZER_MQH
//+------------------------------------------------------------------+
