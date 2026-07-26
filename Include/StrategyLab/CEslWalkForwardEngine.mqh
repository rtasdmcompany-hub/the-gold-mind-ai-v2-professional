//+------------------------------------------------------------------+
//|                                    CEslWalkForwardEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CESL_WALK_FORWARD_ENGINE_MQH
#define GM_CESL_WALK_FORWARD_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CEslBacktestEngine.mqh"
#include "../Logging/CLogger.mqh"

class CGmEslWalkForwardEngine
  {
private:
   CGmLogger *m_logger;
   int        m_folds;
   double     m_efficiency;
   double     m_robustness;
   string     m_summary;

public:
                     CGmEslWalkForwardEngine(void)
                       : m_logger(NULL), m_folds(0), m_efficiency(0.0),
                         m_robustness(0.0), m_summary("") {}

   void Init(CGmLogger *logger) { m_logger = logger; Reset(); }

   void Reset(void)
     {
      m_folds = 0;
      m_efficiency = m_robustness = 0.0;
      m_summary = "Idle";
     }

   int Folds(void) const { return m_folds; }
   double Efficiency(void) const { return m_efficiency; }
   double Robustness(void) const { return m_robustness; }
   string Summary(void) const { return m_summary; }

   void Run(CGmEslBacktestEngine *bt)
     {
      Reset();
      if(bt == NULL || bt.TradeCount() < GM_ESL_WFA_FOLDS * 2)
        {
         m_summary = "Walk-Forward skipped | insufficient sample";
         return;
        }

      const int n = bt.TradeCount();
      const int folds = GM_ESL_WFA_FOLDS;
      const int fold_sz = n / folds;
      if(fold_sz < 2)
        {
         m_summary = "Walk-Forward skipped | fold too small";
         return;
        }

      double is_sum = 0.0, oos_sum = 0.0;
      int is_n = 0, oos_n = 0;
      double param_stab = 0.0;

      for(int f = 0; f < folds - 1; f++)
        {
         // In-sample: fold f ; Out-of-sample: fold f+1 (rolling)
         const int is0 = f * fold_sz;
         const int is1 = is0 + fold_sz;
         const int oos0 = is1;
         const int oos1 = MathMin(n, oos0 + fold_sz);

         double is_r = 0.0, oos_r = 0.0;
         int is_w = 0, oos_w = 0;
         for(int i = is0; i < is1; i++)
           {
            SGmEslSimTrade t;
            if(!bt.GetTrade(i, t)) continue;
            is_r += t.pnl_r;
            if(t.win) is_w++;
            is_n++;
           }
         for(int j = oos0; j < oos1; j++)
           {
            SGmEslSimTrade t;
            if(!bt.GetTrade(j, t)) continue;
            oos_r += t.pnl_r;
            if(t.win) oos_w++;
            oos_n++;
           }
         is_sum += is_r;
         oos_sum += oos_r;
         const double is_wr = (is1 > is0) ? ((double)is_w / (double)(is1 - is0)) : 0.0;
         const double oos_wr = (oos1 > oos0) ? ((double)oos_w / (double)(oos1 - oos0)) : 0.0;
         param_stab += 100.0 - MathAbs(is_wr - oos_wr) * 100.0;
        }

      m_folds = folds;
      // Walk-forward efficiency ≈ OOS / IS (clamped)
      if(MathAbs(is_sum) > 0.01)
         m_efficiency = MathMin(150.0, MathMax(0.0, 100.0 * (oos_sum / is_sum)));
      else
         m_efficiency = (oos_sum >= 0.0) ? 80.0 : 20.0;

      m_robustness = MathMin(100.0,
         0.5 * MathMin(100.0, m_efficiency) +
         0.5 * (param_stab / (double)MathMax(1, folds - 1)));

      m_summary = StringFormat(
         "WFA OK | Folds=%d | Efficiency=%.0f | Robustness=%.0f | IS/OOS rolling + param stability",
         m_folds, m_efficiency, m_robustness);

      if(m_logger != NULL)
         m_logger.Success("Walk-Forward Completed | " + m_summary, "ESL");
     }
  };

#endif // GM_CESL_WALK_FORWARD_ENGINE_MQH
//+------------------------------------------------------------------+
