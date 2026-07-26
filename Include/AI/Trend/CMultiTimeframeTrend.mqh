//+------------------------------------------------------------------+
//|                                      CMultiTimeframeTrend.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CMULTI_TIMEFRAME_TREND_MQH
#define GM_CMULTI_TIMEFRAME_TREND_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmTrendAnalysisResult.mqh"

class CGmMultiTimeframeTrend
  {
public:
   void Compare(SGmTrendAnalysisResult &r)
     {
      int bull = 0, bear = 0, flat = 0;
      Count(r.h4.direction, bull, bear, flat);
      Count(r.d1.direction, bull, bear, flat);
      Count(r.w1.direction, bull, bear, flat);
      Count(r.mn1.direction, bull, bear, flat);

      const int decisive = bull + bear;
      r.agreement_score = (decisive > 0)
                          ? (100.0 * MathMax(bull, bear) / (double)(bull + bear + flat))
                          : 0.0;
      r.conflict_score = (bull > 0 && bear > 0)
                         ? (100.0 * MathMin(bull, bear) / (double)MathMax(1, decisive))
                         : 0.0;

      // Dominant = highest strength among non-flat
      double best = -1.0;
      r.dominant_tf = "H4";
      Pick(r.h4, "H4", best, r.dominant_tf);
      Pick(r.d1, "D1", best, r.dominant_tf);
      Pick(r.w1, "W1", best, r.dominant_tf);
      Pick(r.mn1, "MN", best, r.dominant_tf);

      // Higher TF bias = W1 then MN
      if(r.mn1.direction != GM_TREND_DIR_FLAT && r.mn1.direction != GM_TREND_DIR_UNKNOWN)
         r.higher_tf_bias = r.mn1.direction;
      else
         r.higher_tf_bias = r.w1.direction;

      r.lower_tf_bias = r.h4.direction;
     }

private:
   void Count(const ENUM_GM_TREND_DIR d, int &bull, int &bear, int &flat)
     {
      if(d == GM_TREND_DIR_BULL) bull++;
      else if(d == GM_TREND_DIR_BEAR) bear++;
      else flat++;
     }

   void Pick(const SGmTrendTFState &st, const string name, double &best, string &dom)
     {
      if(st.direction == GM_TREND_DIR_FLAT || st.direction == GM_TREND_DIR_UNKNOWN)
         return;
      if(st.strength > best)
        {
         best = st.strength;
         dom = name;
        }
     }
  };

#endif // GM_CMULTI_TIMEFRAME_TREND_MQH
//+------------------------------------------------------------------+
