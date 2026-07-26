//+------------------------------------------------------------------+
//|                               CCapitalAllocationAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CCAPITAL_ALLOCATION_ANALYZER_MQH
#define GM_CCAPITAL_ALLOCATION_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmPortfolioIntelligenceResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../../Analytics/SGmAnalyticsSnapshot.mqh"

class CGmCapitalAllocationAnalyzer
  {
public:
   void Analyze(const SGmAssistantResult &sup,
                const SGmAnalyticsSnapshot &a,
                SGmPortfolioIntelligenceResult &r)
     {
      r.balance = (a.balance > 0.0) ? a.balance : AccountInfoDouble(ACCOUNT_BALANCE);
      r.equity = (a.equity > 0.0) ? a.equity : AccountInfoDouble(ACCOUNT_EQUITY);
      r.free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      r.used_margin = AccountInfoDouble(ACCOUNT_MARGIN);
      r.floating_pl = a.floating_profit - MathAbs(a.floating_loss);
      if(r.floating_pl == 0.0)
         r.floating_pl = AccountInfoDouble(ACCOUNT_PROFIT);

      const double margin_level_base = MathMax(1.0, r.equity);
      r.capital_usage_pct = GmPiClamp(
                               (r.used_margin > 0.0)
                               ? (r.used_margin / margin_level_base * 100.0)
                               : (sup.valid ? sup.margin_usage_pct : 0.0));

      r.daily_growth = (r.balance > 0.0)
                       ? ((a.today_profit - MathAbs(a.today_loss)) / r.balance * 100.0)
                       : 0.0;
      r.weekly_growth = (r.balance > 0.0)
                        ? ((a.week_profit - MathAbs(a.week_loss)) / r.balance * 100.0)
                        : 0.0;
      r.monthly_growth = (r.balance > 0.0)
                         ? ((a.month_profit - MathAbs(a.month_loss)) / r.balance * 100.0)
                         : 0.0;

      r.capital_efficiency_score = GmPiClamp(
                                      0.30 * (100.0 - MathMin(80.0, r.capital_usage_pct)) +
                                      0.25 * (50.0 + MathMax(-30.0, MathMin(30.0, r.daily_growth * 8.0))) +
                                      0.25 * (r.free_margin > 0.0
                                              ? MathMin(100.0, r.free_margin / MathMax(1.0, r.equity) * 100.0)
                                              : 40.0) +
                                      0.20 * (a.overall_win_rate > 0.0 ? a.overall_win_rate : 50.0));

      const double growth_abs = MathAbs(r.daily_growth) + MathAbs(r.weekly_growth) * 0.5;
      r.growth_stability_score = GmPiClamp(
                                    70.0 - growth_abs * 3.0 +
                                    (r.weekly_growth >= 0.0 ? 10.0 : -5.0) +
                                    (r.monthly_growth >= 0.0 ? 8.0 : -4.0));

      r.capital_report = StringFormat(
                            "Capital Allocation Analyzer:\r\nEff=%.0f GrowthStab=%.0f Usage=%.0f%%\r\nBal=%.2f Eq=%.2f Free=%.2f Used=%.2f Float=%.2f\r\nDay=%.2f%% Week=%.2f%% Month=%.2f%%\r\n%s\r\n",
                            r.capital_efficiency_score, r.growth_stability_score, r.capital_usage_pct,
                            r.balance, r.equity, r.free_margin, r.used_margin, r.floating_pl,
                            r.daily_growth, r.weekly_growth, r.monthly_growth,
                            GM_PI_ANALYSIS_ONLY);
     }
  };

#endif // GM_CCAPITAL_ALLOCATION_ANALYZER_MQH
//+------------------------------------------------------------------+
