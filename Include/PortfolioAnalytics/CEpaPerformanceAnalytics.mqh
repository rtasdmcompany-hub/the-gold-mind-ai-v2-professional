//+------------------------------------------------------------------+
//|                               CEpaPerformanceAnalytics.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEPA_PERFORMANCE_ANALYTICS_MQH
#define GM_CEPA_PERFORMANCE_ANALYTICS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CEpaPortfolioEngine.mqh"
#include "../Logging/CLogger.mqh"

class CGmEpaPerformanceAnalytics
  {
private:
   CGmLogger *m_logger;

   double Clamp(const double v, const double lo, const double hi) const
     {
      if(v < lo) return lo;
      if(v > hi) return hi;
      return v;
     }

public:
                     CGmEpaPerformanceAnalytics(void) : m_logger(NULL) {}

   void Init(CGmLogger *logger) { m_logger = logger; }

   void Calculate(CGmEpaPortfolioEngine *port, SGmPortfolioAnalyticsResult &out)
     {
      out.profit_factor = out.sharpe_ratio = out.sortino_ratio = 0.0;
      out.calmar_ratio = out.recovery_ratio = out.expectancy = 0.0;
      out.avg_holding_sec = out.trade_frequency = out.win_rate = 0.0;
      out.winning_streak = out.losing_streak = out.max_consec_losses = 0;
      out.performance_grade = GM_EPA_GRADE_F;

      if(port == NULL || port.Count() == 0)
        {
         out.performance_report = "Performance | no sample";
         return;
        }

      int wins = 0, losses = 0;
      double gp = 0.0, gl = 0.0, sum = 0.0, sum_sq = 0.0, sum_neg_sq = 0.0;
      double hold_sum = 0.0;
      int cur_w = 0, cur_l = 0, max_w = 0, max_l = 0;
      datetime first_t = 0, last_t = 0;

      for(int i = 0; i < port.Count(); i++)
        {
         double pnl = 0.0, hold = 0.0;
         datetime t = 0;
         if(!port.GetPnl(i, pnl, t, hold)) continue;
         sum += pnl;
         sum_sq += pnl * pnl;
         hold_sum += hold;
         if(first_t == 0 || t < first_t) first_t = t;
         if(t > last_t) last_t = t;

         if(pnl >= 0.0)
           {
            wins++;
            gp += pnl;
            cur_w++; cur_l = 0;
            if(cur_w > max_w) max_w = cur_w;
           }
         else
           {
            losses++;
            gl += MathAbs(pnl);
            sum_neg_sq += pnl * pnl;
            cur_l++; cur_w = 0;
            if(cur_l > max_l) max_l = cur_l;
           }
        }

      const int n = wins + losses;
      out.win_rate = (n > 0) ? (100.0 * (double)wins / (double)n) : 0.0;
      out.profit_factor = (gl > 0.0) ? (gp / gl) : ((gp > 0.0) ? 99.0 : 0.0);
      out.expectancy = (n > 0) ? (sum / (double)n) : 0.0;
      out.avg_holding_sec = (n > 0) ? (hold_sum / (double)n) : 0.0;
      out.winning_streak = max_w;
      out.losing_streak = max_l;
      out.max_consec_losses = max_l;

      const double days = (last_t > first_t) ? MathMax(1.0, (double)(last_t - first_t) / 86400.0) : 1.0;
      out.trade_frequency = (double)n / days;

      const double mean = out.expectancy;
      const double var = (n > 1) ? ((sum_sq - (sum * sum / (double)n)) / (double)(n - 1)) : 0.0;
      const double std = MathSqrt(MathMax(0.0, var));
      out.sharpe_ratio = (std > 0.0) ? (mean / std) : ((mean > 0.0) ? 3.0 : 0.0);

      const double downside = (losses > 0) ? MathSqrt(sum_neg_sq / (double)losses) : 0.0;
      out.sortino_ratio = (downside > 0.0) ? (mean / downside) : ((mean > 0.0) ? 3.0 : 0.0);

      out.calmar_ratio = (out.max_drawdown_pct > 0.0)
         ? (out.capital_growth_pct / out.max_drawdown_pct)
         : ((out.capital_growth_pct > 0.0) ? 5.0 : 0.0);
      out.recovery_ratio = out.recovery_factor;

      const double score = Clamp(
         0.25 * MathMin(100.0, out.profit_factor * 25.0) +
         0.20 * out.win_rate +
         0.20 * Clamp(50.0 + out.sharpe_ratio * 15.0, 0.0, 100.0) +
         0.15 * Clamp(50.0 + out.sortino_ratio * 12.0, 0.0, 100.0) +
         0.20 * (100.0 - MathMin(100.0, out.max_drawdown_pct)),
         0.0, 100.0);

      out.performance_grade = GmEpaGradeFromScore(score);
      out.performance_report = StringFormat(
         "Performance | PF=%.2f Sharpe=%.2f Sortino=%.2f Calmar=%.2f Exp=%.2f WR=%.1f%% Grade=%s",
         out.profit_factor, out.sharpe_ratio, out.sortino_ratio, out.calmar_ratio,
         out.expectancy, out.win_rate, GmEpaGradeName(out.performance_grade));

      if(m_logger != NULL)
         m_logger.Info("Performance Report Generated | " + out.performance_report, "EPA");
     }
  };

#endif // GM_CEPA_PERFORMANCE_ANALYTICS_MQH
//+------------------------------------------------------------------+
