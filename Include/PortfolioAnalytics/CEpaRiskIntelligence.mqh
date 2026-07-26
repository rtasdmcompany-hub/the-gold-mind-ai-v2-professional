//+------------------------------------------------------------------+
//|                                        CEpaRiskIntelligence.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEPA_RISK_INTELLIGENCE_MQH
#define GM_CEPA_RISK_INTELLIGENCE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CEpaPortfolioEngine.mqh"
#include "../Logging/CLogger.mqh"

class CGmEpaRiskIntelligence
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
                     CGmEpaRiskIntelligence(void) : m_logger(NULL) {}

   void Init(CGmLogger *logger) { m_logger = logger; }

   void Calculate(CGmEpaPortfolioEngine *port, SGmPortfolioAnalyticsResult &out)
     {
      out.max_drawdown_pct = 0.0;
      out.relative_drawdown_pct = 0.0;
      out.absolute_drawdown = 0.0;
      out.daily_risk = out.weekly_risk = out.monthly_risk = 0.0;
      out.value_at_risk = 0.0;
      out.recovery_factor = 0.0;
      out.risk_reward_avg = 0.0;
      out.risk_stability = 50.0;

      if(port == NULL || port.Count() == 0)
        {
         out.risk_report = "Risk | no closed GM trades";
         return;
        }

      double equity = 0.0, peak = 0.0, max_dd = 0.0, abs_dd = 0.0;
      double sum_win = 0.0, sum_loss = 0.0;
      int wins = 0, losses = 0;
      double losses_arr[GM_EPA_EQUITY_MAX];
      int ln = 0;

      for(int i = 0; i < port.Count(); i++)
        {
         double pnl = 0.0, hold = 0.0;
         datetime t = 0;
         if(!port.GetPnl(i, pnl, t, hold)) continue;
         equity += pnl;
         if(equity > peak) peak = equity;
         const double dd = (peak > 0.0) ? (100.0 * (peak - equity) / peak) : 0.0;
         if(dd > max_dd) max_dd = dd;
         const double trough = peak - equity;
         if(trough > abs_dd) abs_dd = trough;

         if(pnl >= 0.0) { wins++; sum_win += pnl; }
         else
           {
            losses++;
            sum_loss += MathAbs(pnl);
            if(ln < GM_EPA_EQUITY_MAX)
               losses_arr[ln++] = MathAbs(pnl);
           }
        }

      out.max_drawdown_pct = max_dd;
      out.relative_drawdown_pct = max_dd;
      out.absolute_drawdown = abs_dd;
      out.daily_risk = MathAbs(out.daily_pnl);
      out.weekly_risk = MathAbs(out.weekly_pnl) * 0.35;
      out.monthly_risk = MathAbs(out.monthly_pnl) * 0.25;

      // Simple VaR proxy: 95th percentile of loss magnitudes
      if(ln > 0)
        {
         // selection sort partial
         for(int a = 0; a < ln - 1; a++)
            for(int b = a + 1; b < ln; b++)
               if(losses_arr[b] < losses_arr[a])
                 {
                  const double tmp = losses_arr[a];
                  losses_arr[a] = losses_arr[b];
                  losses_arr[b] = tmp;
                 }
         const int idx = MathMin(ln - 1, (int)(ln * 0.95));
         out.value_at_risk = losses_arr[idx];
        }

      out.recovery_factor = (max_dd > 0.0) ? (equity / (max_dd / 10.0 + 0.01)) : ((equity > 0.0) ? 10.0 : 0.0);
      const double avg_w = (wins > 0) ? (sum_win / (double)wins) : 0.0;
      const double avg_l = (losses > 0) ? (sum_loss / (double)losses) : 0.0;
      out.risk_reward_avg = (avg_l > 0.0) ? (avg_w / avg_l) : ((avg_w > 0.0) ? 99.0 : 0.0);

      out.risk_stability = Clamp100(
         100.0 - max_dd * 0.8 + MathMin(20.0, out.risk_reward_avg * 5.0));

      out.risk_report = StringFormat(
         "Risk | MaxDD=%.1f%% AbsDD=%.2f VaR=%.2f RF=%.2f RR=%.2f Stab=%.0f",
         out.max_drawdown_pct, out.absolute_drawdown, out.value_at_risk,
         out.recovery_factor, out.risk_reward_avg, out.risk_stability);

      if(m_logger != NULL)
         m_logger.Info("Risk Calculated | " + out.risk_report, "EPA");
     }
  };

#endif // GM_CEPA_RISK_INTELLIGENCE_MQH
//+------------------------------------------------------------------+
