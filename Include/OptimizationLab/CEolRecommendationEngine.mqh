//+------------------------------------------------------------------+
//|                                 CEolRecommendationEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEOL_RECOMMENDATION_ENGINE_MQH
#define GM_CEOL_RECOMMENDATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CEolStrategyCompare.mqh"
#include "CEolMultiDatasetValidation.mqh"
#include "../Logging/CLogger.mqh"

class CGmEolRecommendationEngine
  {
private:
   CGmLogger *m_logger;
   string     m_best;
   string     m_safest;
   string     m_lowest_dd;
   string     m_best_recovery;
   string     m_best_news;
   string     m_best_session;
   string     m_report;
   double     m_institutional;

public:
                     CGmEolRecommendationEngine(void)
                       : m_logger(NULL), m_best(""), m_safest(""), m_lowest_dd(""),
                         m_best_recovery(""), m_best_news(""), m_best_session(""),
                         m_report(""), m_institutional(0.0) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_best = m_safest = m_lowest_dd = "";
      m_best_recovery = m_best_news = m_best_session = "";
      m_report = "Idle";
      m_institutional = 0.0;
     }

   string Best(void) const { return m_best; }
   string Safest(void) const { return m_safest; }
   string LowestDd(void) const { return m_lowest_dd; }
   string BestRecovery(void) const { return m_best_recovery; }
   string BestNews(void) const { return m_best_news; }
   string BestSession(void) const { return m_best_session; }
   string Report(void) const { return m_report; }
   double Institutional(void) const { return m_institutional; }

   void Recommend(CGmEolStrategyCompare *cmp,
                  CGmEolMultiDatasetValidation *ds,
                  const double opt_score,
                  const double param_conf)
     {
      m_best = m_safest = m_lowest_dd = "—";
      m_best_recovery = m_best_news = m_best_session = "—";

      if(cmp != NULL && cmp.Count() > 0)
        {
         SGmEolProfileScore p;
         // Ranked list: index 0 = best overall
         if(cmp.GetAt(0, p)) m_best = p.name;

         double max_stab = -1.0;
         double max_perf = -1.0;
         for(int i = 0; i < cmp.Count(); i++)
           {
            if(!cmp.GetAt(i, p)) continue;
            if(p.stability > max_stab)
              {
               max_stab = p.stability;
               m_safest = p.name;
               m_lowest_dd = p.name; // stability proxy for lowest DD
              }
            if(StringFind(p.name, "Recovery") >= 0)
               m_best_recovery = p.name;
            if(p.performance > max_perf)
               max_perf = p.performance;
           }
         if(m_best_recovery == "—" && cmp.GetAt(0, p))
            m_best_recovery = p.name;
        }

      if(ds != NULL)
        {
         // Best news / session from dataset scores
         if(ds.ScoreAt((int)GM_EOL_DS_NEWS) >= ds.ScoreAt((int)GM_EOL_DS_LONDON))
            m_best_news = "Research filter: stand-aside + Strategy B";
         else
            m_best_news = "Session-aware Custom profile";

         if(ds.ScoreAt((int)GM_EOL_DS_LONDON) >= ds.ScoreAt((int)GM_EOL_DS_NEWYORK))
            m_best_session = "London Session emphasis";
         else
            m_best_session = "New York Session emphasis";
        }

      m_institutional = MathMin(100.0,
         0.35 * opt_score + 0.30 * param_conf +
         0.20 * ((cmp != NULL) ? cmp.ComparisonScore() : 0.0) +
         0.15 * ((ds != NULL) ? ds.Adaptability() : 0.0));

      m_report =
         "=== INSTITUTIONAL RECOMMENDATION REPORT ===\r\n"
         "POLICY: Recommendations require EXPLICIT user approval. Never auto-applied.\r\n"
         "Best Historical Configuration: " + m_best + "\r\n"
         "Safest / Highest Stability: " + m_safest + "\r\n"
         "Lowest Drawdown Proxy: " + m_lowest_dd + "\r\n"
         "Highest Recovery Score: " + m_best_recovery + "\r\n"
         "Best News Performance: " + m_best_news + "\r\n"
         "Best Session Performance: " + m_best_session + "\r\n"
         "Institutional Score=" + DoubleToString(m_institutional, 1) + "\r\n"
         "Gold Mind Core remains sole live execution authority.\r\n";

      if(m_logger != NULL)
         m_logger.Success("Recommendation Generated | Inst=" +
                          DoubleToString(m_institutional, 1), "EOL");
     }
  };

#endif // GM_CEOL_RECOMMENDATION_ENGINE_MQH
//+------------------------------------------------------------------+
