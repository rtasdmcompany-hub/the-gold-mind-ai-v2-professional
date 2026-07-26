//+------------------------------------------------------------------+
//|                                     CEolStrategyCompare.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEOL_STRATEGY_COMPARE_MQH
#define GM_CEOL_STRATEGY_COMPARE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmOptimizationLabResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmEolStrategyCompare
  {
private:
   CGmLogger           *m_logger;
   SGmEolProfileScore   m_profiles[GM_EOL_PROFILES];
   int                  m_n;
   double               m_comparison_score;
   string               m_summary;
   string               m_ranking;

   void Rank(void)
     {
      for(int i = 0; i < m_n; i++)
         m_profiles[i].rank_score =
            0.45 * m_profiles[i].performance + 0.55 * m_profiles[i].stability;

      // Simple bubble for ranking display
      for(int a = 0; a < m_n - 1; a++)
         for(int b = a + 1; b < m_n; b++)
            if(m_profiles[b].rank_score > m_profiles[a].rank_score)
              {
               SGmEolProfileScore tmp = m_profiles[a];
               m_profiles[a] = m_profiles[b];
               m_profiles[b] = tmp;
              }

      m_ranking = "Rank|Profile|Perf|Stab|Score\r\n";
      double sum = 0.0;
      for(int i = 0; i < m_n; i++)
        {
         m_ranking += StringFormat("%d|%s|%.1f|%.1f|%.1f\r\n",
                                   i + 1, m_profiles[i].name,
                                   m_profiles[i].performance,
                                   m_profiles[i].stability,
                                   m_profiles[i].rank_score);
         sum += m_profiles[i].rank_score;
        }
      m_comparison_score = (m_n > 0) ? (sum / (double)m_n) : 0.0;
     }

public:
                     CGmEolStrategyCompare(void)
                       : m_logger(NULL), m_n(0), m_comparison_score(0.0),
                         m_summary(""), m_ranking("") {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_n = 0;
      m_comparison_score = 0.0;
      m_summary = "Idle";
      m_ranking = "";
     }

   int Count(void) const { return m_n; }
   double ComparisonScore(void) const { return m_comparison_score; }
   string Summary(void) const { return m_summary; }
   string Ranking(void) const { return m_ranking; }

   bool GetAt(const int i, SGmEolProfileScore &out) const
     {
      if(i < 0 || i >= m_n) return false;
      out = m_profiles[i];
      return true;
     }

   void Compare(const double lab_health, const double lab_robust, const double lab_inst)
     {
      if(m_logger != NULL)
         m_logger.Info("Comparison Started", "EOL");

      m_n = GM_EOL_PROFILES;
      // Strategy A = Baseline Gold Mind (frozen reference)
      m_profiles[0].Reset();
      m_profiles[0].used = true;
      m_profiles[0].name = "Strategy A (Baseline GM)";
      m_profiles[0].performance = MathMin(100.0, 55.0 + lab_health * 0.35);
      m_profiles[0].stability = MathMin(100.0, 60.0 + lab_robust * 0.30);

      // Strategy B = Conservative (tighter risk emphasis)
      m_profiles[1].Reset();
      m_profiles[1].used = true;
      m_profiles[1].name = "Strategy B (Conservative)";
      m_profiles[1].performance = MathMin(100.0, 48.0 + lab_health * 0.28);
      m_profiles[1].stability = MathMin(100.0, 70.0 + lab_robust * 0.25);

      // Strategy C = Aggressive recovery emphasis
      m_profiles[2].Reset();
      m_profiles[2].used = true;
      m_profiles[2].name = "Strategy C (Recovery+)";
      m_profiles[2].performance = MathMin(100.0, 58.0 + lab_inst * 0.30);
      m_profiles[2].stability = MathMin(100.0, 50.0 + lab_robust * 0.28);

      // Custom = Session-filtered
      m_profiles[3].Reset();
      m_profiles[3].used = true;
      m_profiles[3].name = "Custom (Session Filter)";
      m_profiles[3].performance = MathMin(100.0, 52.0 + lab_health * 0.32);
      m_profiles[3].stability = MathMin(100.0, 62.0 + lab_robust * 0.28);

      // Historical version proxy
      m_profiles[4].Reset();
      m_profiles[4].used = true;
      m_profiles[4].name = "Historical v2.0 Ref";
      m_profiles[4].performance = MathMin(100.0, 50.0 + lab_inst * 0.35);
      m_profiles[4].stability = MathMin(100.0, 58.0 + lab_robust * 0.32);

      Rank();
      m_summary = StringFormat(
         "Compared %d profiles | Top=%s (%.1f) | ComparisonScore=%.1f",
         m_n, m_profiles[0].name, m_profiles[0].rank_score, m_comparison_score);

      if(m_logger != NULL)
         m_logger.Success("Comparison Completed | " + m_summary, "EOL");
     }
  };

#endif // GM_CEOL_STRATEGY_COMPARE_MQH
//+------------------------------------------------------------------+
