//+------------------------------------------------------------------+
//|                               CMarketConditionClassifier.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CMARKET_CONDITION_CLASSIFIER_MQH
#define GM_CMARKET_CONDITION_CLASSIFIER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMarketAnalysisResult.mqh"

class CGmMarketConditionClassifier
  {
public:
   void Classify(SGmMarketAnalysisResult &r)
     {
      r.condition = GM_MKT_COND_UNCERTAIN;
      r.confidence = 40.0;

      if(r.structure == GM_MKT_STRUCT_BOS_UP || r.structure == GM_MKT_STRUCT_BOS_DOWN)
        {
         r.condition = GM_MKT_COND_BREAKOUT;
         r.confidence = 72.0;
        }
      else if(r.volatility_ratio >= 1.8)
        {
         r.condition = GM_MKT_COND_HIGH_VOL;
         r.confidence = 68.0;
        }
      else if(r.volatility_ratio > 0.0 && r.volatility_ratio <= 0.55)
        {
         r.condition = GM_MKT_COND_LOW_VOL;
         r.confidence = 65.0;
        }
      else if(r.trend_strength >= 70.0 &&
              (r.direction == GM_MKT_DIR_BULLISH || r.direction == GM_MKT_DIR_BEARISH))
        {
         r.condition = GM_MKT_COND_STRONG_TREND;
         r.confidence = 78.0;
        }
      else if(r.trend_strength >= 40.0 &&
              (r.direction == GM_MKT_DIR_BULLISH || r.direction == GM_MKT_DIR_BEARISH))
        {
         r.condition = GM_MKT_COND_TRENDING;
         r.confidence = 70.0;
        }
      else if(r.contraction || r.direction == GM_MKT_DIR_SIDEWAYS)
        {
         r.condition = (r.pattern == GM_MKT_PAT_INSIDE)
                       ? GM_MKT_COND_CONSOLIDATION
                       : GM_MKT_COND_RANGING;
         r.confidence = 62.0;
        }
      else if((r.direction == GM_MKT_DIR_BULLISH && r.momentum < -20.0) ||
              (r.direction == GM_MKT_DIR_BEARISH && r.momentum > 20.0))
        {
         r.condition = GM_MKT_COND_PULLBACK;
         r.confidence = 66.0;
        }

      // Blend confidence with structure clarity
      if(r.structure != GM_MKT_STRUCT_NONE)
         r.confidence = MathMin(95.0, r.confidence + 5.0);
      if(r.pattern != GM_MKT_PAT_NONE)
         r.confidence = MathMin(95.0, r.confidence + 3.0);
     }
  };

#endif // GM_CMARKET_CONDITION_CLASSIFIER_MQH
//+------------------------------------------------------------------+
