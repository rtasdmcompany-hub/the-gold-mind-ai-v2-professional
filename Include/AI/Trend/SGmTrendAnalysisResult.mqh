//+------------------------------------------------------------------+
//|                                    SGmTrendAnalysisResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_TREND_ANALYSIS_RESULT_MQH
#define GM_SGM_TREND_ANALYSIS_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "TrendAIConstants.mqh"

struct SGmTrendTFState
  {
   ENUM_TIMEFRAMES   tf;
   ENUM_GM_TREND_DIR direction;
   double            strength;     // 0..100
   double            momentum;

   void Reset(void)
     {
      tf = PERIOD_CURRENT;
      direction = GM_TREND_DIR_UNKNOWN;
      strength = 0.0;
      momentum = 0.0;
     }
  };

struct SGmTrendAnalysisResult
  {
   datetime                 stamped_at;
   string                   symbol;
   ulong                    session_id;

   ENUM_GM_TREND_DIR        primary;
   ENUM_GM_TREND_DIR        secondary;
   ENUM_GM_TREND_DIR        micro;
   SGmTrendTFState          h4;
   SGmTrendTFState          d1;
   SGmTrendTFState          w1;
   SGmTrendTFState          mn1;

   double                   strength_score;
   double                   bullish_pressure;
   double                   bearish_pressure;
   double                   momentum_strength;
   double                   directional_bias;   // -100..100
   double                   trend_stability;
   double                   trend_exhaustion;
   double                   confidence;

   ENUM_GM_TREND_STRUCTURE  structure;
   bool                     bos_up;
   bool                     bos_down;
   bool                     choch_up;
   bool                     choch_down;
   bool                     liq_sweep_high;
   bool                     liq_sweep_low;
   double                   swing_high;
   double                   swing_low;

   ENUM_GM_TREND_PHASE      phase;
   double                   agreement_score;
   double                   conflict_score;
   string                   dominant_tf;
   ENUM_GM_TREND_DIR        higher_tf_bias;
   ENUM_GM_TREND_DIR        lower_tf_bias;

   int                      trend_duration_bars;
   datetime                 last_trend_change;
   ENUM_GM_TREND_DIR        prev_primary;
   string                   insight;
   bool                     valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = "";
      session_id = 0;
      primary = secondary = micro = GM_TREND_DIR_UNKNOWN;
      h4.Reset(); d1.Reset(); w1.Reset(); mn1.Reset();
      h4.tf = PERIOD_H4; d1.tf = PERIOD_D1; w1.tf = PERIOD_W1; mn1.tf = PERIOD_MN1;
      strength_score = bullish_pressure = bearish_pressure = 0.0;
      momentum_strength = directional_bias = 0.0;
      trend_stability = trend_exhaustion = confidence = 0.0;
      structure = GM_TREND_STRUCT_NONE;
      bos_up = bos_down = choch_up = choch_down = false;
      liq_sweep_high = liq_sweep_low = false;
      swing_high = swing_low = 0.0;
      phase = GM_TREND_PHASE_UNCERTAIN;
      agreement_score = conflict_score = 0.0;
      dominant_tf = "H4";
      higher_tf_bias = lower_tf_bias = GM_TREND_DIR_UNKNOWN;
      trend_duration_bars = 0;
      last_trend_change = 0;
      prev_primary = GM_TREND_DIR_UNKNOWN;
      insight = "";
      valid = false;
     }
  };

#endif // GM_SGM_TREND_ANALYSIS_RESULT_MQH
//+------------------------------------------------------------------+
