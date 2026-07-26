//+------------------------------------------------------------------+
//|                               SGmVolatilityAnalysisResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_VOLATILITY_ANALYSIS_RESULT_MQH
#define GM_SGM_VOLATILITY_ANALYSIS_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "VolatilityAIConstants.mqh"

struct SGmVolatilityAnalysisResult
  {
   datetime                 stamped_at;
   string                   symbol;
   ulong                    session_id;

   // ATR Intelligence
   double                   atr14;
   double                   atr_change_rate;
   double                   atr_acceleration;
   double                   atr_deceleration;
   bool                     atr_expansion;
   bool                     atr_compression;
   double                   atr_average;
   double                   atr_momentum;
   double                   atr_strength;
   ENUM_GM_ATR_TREND        atr_trend;

   // Volatility Intelligence
   double                   current_vol;
   double                   historical_vol;
   double                   relative_vol;
   double                   intraday_vol;
   double                   weekly_vol;
   double                   monthly_vol;
   double                   expected_vol;
   double                   vol_stability;
   double                   vol_confidence;

   // Market Energy
   ENUM_GM_MARKET_ENERGY    energy;
   double                   energy_score;

   // Phase
   ENUM_GM_VOL_PHASE        phase;
   double                   phase_confidence;

   // Range Analyzer
   double                   range_h4;
   double                   range_d1;
   double                   range_w1;
   double                   range_mn1;
   double                   avg_candle_range;
   bool                     range_expansion;
   bool                     range_compression;
   double                   range_efficiency;
   double                   expected_next_range;

   // Movement Probability (estimates only)
   double                   prob_large_move;
   double                   prob_small_move;
   double                   prob_breakout;
   double                   prob_continuation;
   double                   prob_reversal;
   double                   prob_confidence;

   double                   confidence;
   string                   insight;
   bool                     valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = "";
      session_id = 0;
      atr14 = atr_change_rate = atr_acceleration = atr_deceleration = 0.0;
      atr_expansion = atr_compression = false;
      atr_average = atr_momentum = atr_strength = 0.0;
      atr_trend = GM_ATR_TREND_UNKNOWN;
      current_vol = historical_vol = relative_vol = 0.0;
      intraday_vol = weekly_vol = monthly_vol = expected_vol = 0.0;
      vol_stability = vol_confidence = 0.0;
      energy = GM_ENERGY_UNKNOWN;
      energy_score = 0.0;
      phase = GM_VOL_PHASE_UNCERTAIN;
      phase_confidence = 0.0;
      range_h4 = range_d1 = range_w1 = range_mn1 = 0.0;
      avg_candle_range = 0.0;
      range_expansion = range_compression = false;
      range_efficiency = expected_next_range = 0.0;
      prob_large_move = prob_small_move = prob_breakout = 0.0;
      prob_continuation = prob_reversal = prob_confidence = 0.0;
      confidence = 0.0;
      insight = "";
      valid = false;
     }
  };

#endif // GM_SGM_VOLATILITY_ANALYSIS_RESULT_MQH
//+------------------------------------------------------------------+
