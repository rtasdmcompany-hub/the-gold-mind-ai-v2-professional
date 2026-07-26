//+------------------------------------------------------------------+
//|                                CHistoricalSimilarityEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CHISTORICAL_SIMILARITY_ENGINE_MQH
#define GM_CHISTORICAL_SIMILARITY_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmDecisionSupportResult.mqh"

struct SGmDecHistoryFinger
  {
   datetime t;
   double   trend;
   double   atr;
   double   vol;
   double   spread;
   double   news;
   double   structure;
   double   conf;
   double   success_proxy;
   bool     used;

   void Reset(void)
     {
      t = 0;
      trend = atr = vol = spread = news = structure = conf = 50.0;
      success_proxy = 50.0;
      used = false;
     }
  };

class CGmHistoricalSimilarityEngine
  {
private:
   SGmDecHistoryFinger m_hist[GM_DEC_SIM_MAX];
   int                 m_n;

   double Dist(const SGmDecHistoryFinger &a, const SGmDecHistoryFinger &b) const
     {
      const double d =
         MathAbs(a.trend - b.trend) * 0.18 +
         MathAbs(a.atr - b.atr) * 0.12 +
         MathAbs(a.vol - b.vol) * 0.15 +
         MathAbs(a.spread - b.spread) * 0.10 +
         MathAbs(a.news - b.news) * 0.12 +
         MathAbs(a.structure - b.structure) * 0.13 +
         MathAbs(a.conf - b.conf) * 0.20;
      return d;
     }

public:
                     CGmHistoricalSimilarityEngine(void) : m_n(0) {}

   void Remember(const SGmDecHistoryFinger &f)
     {
      if(m_n < GM_DEC_SIM_MAX)
        {
         m_hist[m_n++] = f;
         m_hist[m_n - 1].used = true;
        }
      else
        {
         for(int i = 1; i < GM_DEC_SIM_MAX; i++)
            m_hist[i - 1] = m_hist[i];
         m_hist[GM_DEC_SIM_MAX - 1] = f;
         m_hist[GM_DEC_SIM_MAX - 1].used = true;
        }
     }

   void Search(const SGmDecHistoryFinger &cur, SGmDecisionSupportResult &r)
     {
      r.match_count = 0;
      r.historical_similarity = 0.0;
      r.historical_success_rate = 50.0;

      if(m_n <= 0)
        {
         r.historical_similarity = 0.0;
         return;
        }

      // Rank all by similarity
      double sims[GM_DEC_SIM_MAX];
      int idx[GM_DEC_SIM_MAX];
      int usable = 0;
      for(int i = 0; i < m_n; i++)
        {
         if(!m_hist[i].used)
            continue;
         // skip exact same timestamp
         if(m_hist[i].t == cur.t)
            continue;
         const double dist = Dist(cur, m_hist[i]);
         sims[usable] = GmDecClamp(100.0 - dist);
         idx[usable] = i;
         usable++;
        }

      for(int a = 0; a < usable - 1; a++)
         for(int b = a + 1; b < usable; b++)
            if(sims[b] > sims[a])
              {
               const double ts = sims[a]; sims[a] = sims[b]; sims[b] = ts;
               const int ti = idx[a]; idx[a] = idx[b]; idx[b] = ti;
              }

      const int top = MathMin(5, usable);
      double sim_sum = 0.0;
      double succ_sum = 0.0;
      for(int i = 0; i < top; i++)
        {
         r.top_matches[i].Reset();
         r.top_matches[i].stamped_at = m_hist[idx[i]].t;
         r.top_matches[i].similarity_pct = sims[i];
         r.top_matches[i].confidence = m_hist[idx[i]].conf;
         r.top_matches[i].success_proxy = m_hist[idx[i]].success_proxy;
         r.top_matches[i].label = StringFormat("Sim %.0f%% | conf=%.0f",
                                               sims[i], m_hist[idx[i]].conf);
         r.top_matches[i].valid = true;
         sim_sum += sims[i];
         succ_sum += m_hist[idx[i]].success_proxy;
         r.match_count++;
        }

      if(top > 0)
        {
         r.historical_similarity = sim_sum / (double)top;
         r.historical_success_rate = succ_sum / (double)top;
        }
     }
  };

#endif // GM_CHISTORICAL_SIMILARITY_ENGINE_MQH
//+------------------------------------------------------------------+
