//+------------------------------------------------------------------+
//|                               SGmNewsIntelligenceResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_NEWS_INTELLIGENCE_RESULT_MQH
#define GM_SGM_NEWS_INTELLIGENCE_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "NewsIntelligenceConstants.mqh"

struct SGmNewsIntelligenceResult
  {
   datetime               stamped_at;
   string                 symbol;
   ulong                  session_id;
   ENUM_GM_NI_STATUS      status;

   // Upcoming / calendar
   string                 upcoming_news;
   string                 calendar_summary;
   int                    seconds_until_event;
   string                 countdown_text;
   int                    event_count;
   ENUM_GM_NI_EVENT_CLASS event_class;

   // News intelligence scores
   double                 news_confidence;
   double                 expected_volatility;
   double                 expected_direction_bias; // -100..+100 mapped display via score
   double                 news_impact_score;
   ENUM_GM_NI_IMPACT      impact_class;
   string                 news_intel_report;

   // Impact analyzer
   double                 expected_price_expansion;
   double                 expected_atr_expansion;
   double                 expected_liquidity;
   double                 expected_spread_expansion;
   string                 historical_behavior;
   string                 impact_report;

   // Gold news
   double                 gold_sentiment_score;
   double                 bullish_bias;
   double                 bearish_bias;
   double                 neutral_bias;
   ENUM_GM_NI_GOLD_BIAS   gold_bias;
   string                 gold_report;

   // Historical
   double                 historical_similarity;
   double                 historical_success_stats;
   string                 historical_report;

   // Volatility forecast
   double                 atr_forecast;
   double                 candle_size_forecast;
   double                 expansion_forecast;
   double                 compression_forecast;
   double                 energy_forecast;
   double                 momentum_forecast;
   double                 liquidity_forecast;
   double                 forecast_confidence;
   string                 forecast_report;

   // Recommendation (advisory only)
   string                 ai_news_recommendation;
   string                 center_status;
   string                 advisory_status;
   string                 insight;
   bool                   may_disable_trading;   // ALWAYS false
   bool                   may_skip_trades;       // ALWAYS false
   bool                   from_cache;
   bool                   valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = "";
      session_id = 0;
      status = GM_NI_STATUS_IDLE;
      upcoming_news = calendar_summary = countdown_text = "";
      seconds_until_event = event_count = 0;
      event_class = GM_NI_EVT_UNKNOWN;
      news_confidence = expected_volatility = expected_direction_bias = 0.0;
      news_impact_score = 0.0;
      impact_class = GM_NI_IMPACT_NONE;
      news_intel_report = "";
      expected_price_expansion = expected_atr_expansion = 0.0;
      expected_liquidity = expected_spread_expansion = 0.0;
      historical_behavior = impact_report = "";
      gold_sentiment_score = bullish_bias = bearish_bias = neutral_bias = 0.0;
      gold_bias = GM_NI_GOLD_NEUTRAL;
      gold_report = "";
      historical_similarity = historical_success_stats = 0.0;
      historical_report = "";
      atr_forecast = candle_size_forecast = expansion_forecast = 0.0;
      compression_forecast = energy_forecast = momentum_forecast = 0.0;
      liquidity_forecast = forecast_confidence = 0.0;
      forecast_report = "";
      ai_news_recommendation = "";
      center_status = "Idle";
      advisory_status = GM_NI_ADVISORY;
      insight = "";
      may_disable_trading = false;
      may_skip_trades = false;
      from_cache = false;
      valid = false;
     }
  };

#endif // GM_SGM_NEWS_INTELLIGENCE_RESULT_MQH
//+------------------------------------------------------------------+
