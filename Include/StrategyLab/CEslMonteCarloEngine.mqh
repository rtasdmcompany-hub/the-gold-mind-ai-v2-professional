//+------------------------------------------------------------------+
//|                                     CEslMonteCarloEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CESL_MONTE_CARLO_ENGINE_MQH
#define GM_CESL_MONTE_CARLO_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CEslBacktestEngine.mqh"
#include "../Logging/CLogger.mqh"

class CGmEslMonteCarloEngine
  {
private:
   CGmLogger *m_logger;
   int        m_runs;
   double     m_confidence;
   double     m_prob_profit;
   double     m_median_dd;
   double     m_capital_growth;
   string     m_summary;
   string     m_probability;

   uint NextRand(uint &state) const
     {
      state = state * 1103515245 + 12345;
      return (state / 65536) % 32768;
     }

public:
                     CGmEslMonteCarloEngine(void)
                       : m_logger(NULL), m_runs(0), m_confidence(0.0),
                         m_prob_profit(0.0), m_median_dd(0.0),
                         m_capital_growth(0.0), m_summary(""), m_probability("") {}

   void Init(CGmLogger *logger) { m_logger = logger; Reset(); }

   void Reset(void)
     {
      m_runs = 0;
      m_confidence = m_prob_profit = m_median_dd = m_capital_growth = 0.0;
      m_summary = "Idle";
      m_probability = "";
     }

   int Runs(void) const { return m_runs; }
   double Confidence(void) const { return m_confidence; }
   string Summary(void) const { return m_summary; }
   string ProbabilityReport(void) const { return m_probability; }

   void Run(CGmEslBacktestEngine *bt, const int max_runs)
     {
      Reset();
      if(bt == NULL || bt.TradeCount() < 2)
        {
         m_summary = "Monte Carlo skipped | need simulated trades";
         return;
        }

      const int n = bt.TradeCount();
      const int runs = MathMax(5, MathMin(max_runs, GM_ESL_MC_RUNS_FULL));
      double finals[];
      double dds[];
      ArrayResize(finals, runs);
      ArrayResize(dds, runs);

      uint seed = (uint)(TimeCurrent() ^ (ulong)n);
      int profit_runs = 0;

      for(int r = 0; r < runs; r++)
        {
         // Random trade sequence (shuffle indices)
         int idx[];
         ArrayResize(idx, n);
         for(int i = 0; i < n; i++) idx[i] = i;
         for(int i = n - 1; i > 0; i--)
           {
            const int j = (int)(NextRand(seed) % (i + 1));
            const int tmp = idx[i];
            idx[i] = idx[j];
            idx[j] = tmp;
           }

         double equity = 100.0;
         double peak = equity;
         double max_dd = 0.0;
         for(int k = 0; k < n; k++)
           {
            SGmEslSimTrade t;
            if(!bt.GetTrade(idx[k], t))
               continue;
            // Random ATR / volatility scaling ±30%
            const double vol = 0.7 + 0.6 * ((double)NextRand(seed) / 32768.0);
            equity += t.pnl_r * vol;
            if(equity > peak) peak = equity;
            const double dd = (peak > 0.0) ? (100.0 * (peak - equity) / peak) : 0.0;
            if(dd > max_dd) max_dd = dd;
           }
         finals[r] = equity;
         dds[r] = max_dd;
         if(equity > 100.0)
            profit_runs++;
        }

      m_runs = runs;
      m_prob_profit = 100.0 * (double)profit_runs / (double)runs;

      // Median DD
      ArraySort(dds);
      m_median_dd = dds[runs / 2];

      double sum_f = 0.0;
      for(int i = 0; i < runs; i++)
         sum_f += finals[i];
      m_capital_growth = (sum_f / (double)runs) - 100.0;

      m_confidence = MathMin(100.0,
         35.0 + m_prob_profit * 0.45 + MathMax(0.0, 20.0 - m_median_dd * 0.4));

      m_probability = StringFormat(
         "P(profit)=%.1f%% | MedianDD=%.1f%% | AvgGrowth=%.1fR | Runs=%d | Random trade/vol/ATR/DD/capital",
         m_prob_profit, m_median_dd, m_capital_growth, m_runs);
      m_summary = StringFormat("Monte Carlo OK | Confidence=%.0f | %s",
                               m_confidence, m_probability);

      if(m_logger != NULL)
         m_logger.Success("Monte Carlo Completed | " + m_summary, "ESL");
     }
  };

#endif // GM_CESL_MONTE_CARLO_ENGINE_MQH
//+------------------------------------------------------------------+
