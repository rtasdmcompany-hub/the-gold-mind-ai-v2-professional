//+------------------------------------------------------------------+
//|                                     CEslRobustnessEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CESL_ROBUSTNESS_ENGINE_MQH
#define GM_CESL_ROBUSTNESS_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CEslBacktestEngine.mqh"
#include "SGmStrategyLabResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmEslRobustnessEngine
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
                     CGmEslRobustnessEngine(void) : m_logger(NULL) {}

   void Init(CGmLogger *logger) { m_logger = logger; }

   void Validate(CGmEslBacktestEngine *bt,
                 const double mc_confidence,
                 const double wfa_robustness,
                 SGmStrategyLabResult &out)
     {
      out.max_drawdown_pct = 0.0;
      out.recovery_factor = 0.0;
      out.profit_factor = 0.0;
      out.expected_return = 0.0;
      out.win_rate = out.loss_rate = out.expectancy = 0.0;
      out.risk_of_ruin = 50.0;
      out.consistency = 0.0;
      out.institutional_score = 0.0;
      out.robustness_score = 0.0;

      if(bt == NULL || bt.TradeCount() == 0)
        {
         out.validation_status = "HOLD — no simulation sample";
         return;
        }

      int wins = 0, losses = 0;
      double gp = 0.0, gl = 0.0, sum = 0.0;
      double equity = 0.0, peak = 0.0, max_dd = 0.0;
      int cur_w = 0, streaks = 0;

      SGmEslSimTrade t;
      for(int i = 0; i < bt.TradeCount(); i++)
        {
         if(!bt.GetTrade(i, t))
            continue;
         sum += t.pnl_r;
         equity += t.pnl_r;
         if(equity > peak) peak = equity;
         const double dd = (peak > 0.0) ? (100.0 * (peak - equity) / peak) : 0.0;
         if(dd > max_dd) max_dd = dd;

         if(t.win)
           {
            wins++;
            gp += MathMax(0.01, t.pnl_r);
            cur_w++;
           }
         else
           {
            losses++;
            gl += MathAbs(MathMin(-0.01, t.pnl_r));
            if(cur_w > 0) { streaks++; cur_w = 0; }
           }
        }

      const int n = wins + losses;
      out.win_rate = (n > 0) ? (100.0 * (double)wins / (double)n) : 0.0;
      out.loss_rate = (n > 0) ? (100.0 * (double)losses / (double)n) : 0.0;
      out.profit_factor = (gl > 0.0) ? (gp / gl) : ((gp > 0.0) ? 99.0 : 0.0);
      out.expectancy = (n > 0) ? (sum / (double)n) : 0.0;
      out.expected_return = sum;
      out.max_drawdown_pct = max_dd;
      out.recovery_factor = (max_dd > 0.0) ? (sum / (max_dd / 10.0)) : ((sum > 0.0) ? 10.0 : 0.0);
      out.consistency = Clamp100(100.0 - max_dd + out.win_rate * 0.2);
      // Risk of ruin heuristic
      out.risk_of_ruin = Clamp100(100.0 - out.win_rate + max_dd * 0.5);

      out.robustness_score = Clamp100(
         0.25 * out.consistency +
         0.20 * MathMin(100.0, out.profit_factor * 25.0) +
         0.20 * (100.0 - MathMin(100.0, max_dd)) +
         0.20 * mc_confidence +
         0.15 * wfa_robustness);

      out.institutional_score = Clamp100(
         0.35 * out.robustness_score +
         0.25 * MathMin(100.0, out.recovery_factor * 10.0) +
         0.20 * out.win_rate +
         0.20 * (100.0 - out.risk_of_ruin));

      out.validation_status = (out.institutional_score >= 70.0)
         ? "PASS — Institutional Validation"
         : ((out.institutional_score >= 55.0) ? "REVIEW" : "HOLD");

      if(m_logger != NULL)
         m_logger.Info(StringFormat("Validation Generated | Inst=%.0f Robust=%.0f Status=%s",
                                    out.institutional_score, out.robustness_score,
                                    out.validation_status), "ESL");
     }
  };

#endif // GM_CESL_ROBUSTNESS_ENGINE_MQH
//+------------------------------------------------------------------+
