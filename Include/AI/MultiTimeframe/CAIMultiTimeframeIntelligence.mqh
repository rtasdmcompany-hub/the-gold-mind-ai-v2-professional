//+------------------------------------------------------------------+
//|                         CAIMultiTimeframeIntelligence.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_MULTI_TIMEFRAME_INTELLIGENCE_MQH
#define GM_CAI_MULTI_TIMEFRAME_INTELLIGENCE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMultiTimeframeResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Trend/CTrendStrengthAnalyzer.mqh"

class CGmAIMultiTimeframeIntelligence
  {
private:
   CGmTrendStrengthAnalyzer m_tf;

   void CountDir(const ENUM_GM_TREND_DIR d, int &bull, int &bear, int &flat) const
     {
      if(d == GM_TREND_DIR_BULL) bull++;
      else if(d == GM_TREND_DIR_BEAR) bear++;
      else flat++;
     }

   ENUM_GM_MTF_BIAS Majority(const int bull, const int bear, const int flat) const
     {
      if(bull == 0 && bear == 0) return GM_MTF_BIAS_NEUTRAL;
      if(bull > 0 && bear > 0 && bull == bear) return GM_MTF_BIAS_MIXED;
      if(bull > bear && bull >= flat) return GM_MTF_BIAS_BULL;
      if(bear > bull && bear >= flat) return GM_MTF_BIAS_BEAR;
      if(flat >= bull && flat >= bear) return GM_MTF_BIAS_NEUTRAL;
      return (bull > bear) ? GM_MTF_BIAS_BULL : GM_MTF_BIAS_BEAR;
     }

public:
   void Analyze(const string symbol,
                const SGmTrendAnalysisResult &trend,
                SGmMultiTimeframeResult &r)
     {
      // Lower TFs — context only (sampled via reusable trend strength analyzer)
      m_tf.AnalyzeTF(symbol, PERIOD_M5, r.m5);
      m_tf.AnalyzeTF(symbol, PERIOD_M15, r.m15);
      m_tf.AnalyzeTF(symbol, PERIOD_M30, r.m30);
      m_tf.AnalyzeTF(symbol, PERIOD_H1, r.h1);

      // Higher + H4 from Trend engine when available
      if(trend.valid)
        {
         r.h4 = trend.h4;
         r.d1 = trend.d1;
         r.w1 = trend.w1;
         r.mn = trend.mn1;
        }
      else
        {
         m_tf.AnalyzeTF(symbol, PERIOD_H4, r.h4);
         m_tf.AnalyzeTF(symbol, PERIOD_D1, r.d1);
         m_tf.AnalyzeTF(symbol, PERIOD_W1, r.w1);
         m_tf.AnalyzeTF(symbol, PERIOD_MN1, r.mn);
        }

      int hb = 0, he = 0, hf = 0;
      CountDir(r.d1.direction, hb, he, hf);
      CountDir(r.w1.direction, hb, he, hf);
      CountDir(r.mn.direction, hb, he, hf);
      r.higher_tf_bias = Majority(hb, he, hf);

      int lb = 0, le = 0, lf = 0;
      CountDir(r.m5.direction, lb, le, lf);
      CountDir(r.m15.direction, lb, le, lf);
      CountDir(r.m30.direction, lb, le, lf);
      CountDir(r.h1.direction, lb, le, lf);
      r.lower_tf_bias = Majority(lb, le, lf);

      int ab = 0, ae = 0, af = 0;
      CountDir(r.m5.direction, ab, ae, af);
      CountDir(r.m15.direction, ab, ae, af);
      CountDir(r.m30.direction, ab, ae, af);
      CountDir(r.h1.direction, ab, ae, af);
      CountDir(r.h4.direction, ab, ae, af);
      CountDir(r.d1.direction, ab, ae, af);
      CountDir(r.w1.direction, ab, ae, af);
      CountDir(r.mn.direction, ab, ae, af);

      const int decisive = ab + ae;
      r.timeframe_agreement = (decisive > 0)
                              ? GmMtfClamp(100.0 * MathMax(ab, ae) / (double)(ab + ae + af))
                              : 35.0;
      r.timeframe_conflict = (ab > 0 && ae > 0)
                             ? GmMtfClamp(100.0 * MathMin(ab, ae) / (double)MathMax(1, decisive))
                             : 0.0;

      if(r.higher_tf_bias == r.lower_tf_bias &&
         r.higher_tf_bias != GM_MTF_BIAS_MIXED &&
         r.higher_tf_bias != GM_MTF_BIAS_UNKNOWN)
         r.overall_market_bias = r.higher_tf_bias;
      else if(r.h4.direction == GM_TREND_DIR_BULL || r.h4.direction == GM_TREND_DIR_BEAR)
         r.overall_market_bias = GmMtfBiasFromTrend(r.h4.direction);
      else if(ab > 0 && ae > 0)
         r.overall_market_bias = GM_MTF_BIAS_MIXED;
      else
         r.overall_market_bias = Majority(ab, ae, af);

      r.mtf_report = StringFormat(
                        "Multi-Timeframe Intelligence:\r\nHTF=%s LTF=%s Overall=%s\r\nAgree=%.0f Conflict=%.0f\r\nM5=%s M15=%s M30=%s H1=%s | H4=%s D1=%s W1=%s MN=%s\r\n%s | %s\r\n",
                        GmMtfBiasName(r.higher_tf_bias), GmMtfBiasName(r.lower_tf_bias),
                        GmMtfBiasName(r.overall_market_bias),
                        r.timeframe_agreement, r.timeframe_conflict,
                        GmTrendDirName(r.m5.direction), GmTrendDirName(r.m15.direction),
                        GmTrendDirName(r.m30.direction), GmTrendDirName(r.h1.direction),
                        GmTrendDirName(r.h4.direction), GmTrendDirName(r.d1.direction),
                        GmTrendDirName(r.w1.direction), GmTrendDirName(r.mn.direction),
                        GM_MTF_H4_RULE, GM_MTF_ANALYSIS_ONLY);
     }
  };

#endif // GM_CAI_MULTI_TIMEFRAME_INTELLIGENCE_MQH
//+------------------------------------------------------------------+
