//+------------------------------------------------------------------+
//|                                   SGmMarketAnalysisResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_MARKET_ANALYSIS_RESULT_MQH
#define GM_SGM_MARKET_ANALYSIS_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "MarketAnalysisConstants.mqh"

struct SGmMarketAnalysisResult
  {
   datetime                  stamped_at;
   string                    symbol;
   ulong                     session_id;
   double                    bid;
   double                    ask;
   double                    mid;
   double                    spread_points;
   long                      tick_volume;
   double                    atr14;
   double                    volatility_ratio;
   double                    candle_h4;
   double                    candle_d1;
   double                    candle_w1;
   double                    candle_mn1;
   double                    avg_candle_size;
   double                    daily_range;
   double                    weekly_range;
   double                    market_speed;
   bool                      expansion;
   bool                      contraction;
   double                    swing_high;
   double                    swing_low;
   double                    trend_strength;   // 0..100
   double                    momentum;         // -100..100
   double                    confidence;       // 0..100
   ENUM_GM_MKT_DIRECTION     direction;
   ENUM_GM_MKT_STRUCTURE     structure;
   ENUM_GM_MKT_PATTERN       pattern;
   ENUM_GM_MKT_CONDITION     condition;
   string                    insight;
   string                    analysis_status;
   bool                      valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = "";
      session_id = 0;
      bid = ask = mid = 0.0;
      spread_points = 0.0;
      tick_volume = 0;
      atr14 = 0.0;
      volatility_ratio = 0.0;
      candle_h4 = candle_d1 = candle_w1 = candle_mn1 = 0.0;
      avg_candle_size = 0.0;
      daily_range = weekly_range = 0.0;
      market_speed = 0.0;
      expansion = contraction = false;
      swing_high = swing_low = 0.0;
      trend_strength = 0.0;
      momentum = 0.0;
      confidence = 0.0;
      direction = GM_MKT_DIR_UNKNOWN;
      structure = GM_MKT_STRUCT_NONE;
      pattern = GM_MKT_PAT_NONE;
      condition = GM_MKT_COND_UNCERTAIN;
      insight = "";
      analysis_status = "Idle";
      valid = false;
     }
  };

#endif // GM_SGM_MARKET_ANALYSIS_RESULT_MQH
//+------------------------------------------------------------------+
