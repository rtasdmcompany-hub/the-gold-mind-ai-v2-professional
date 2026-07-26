//+------------------------------------------------------------------+
//|                                      SGmNewsAnalysisResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_NEWS_ANALYSIS_RESULT_MQH
#define GM_SGM_NEWS_ANALYSIS_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "NewsAIConstants.mqh"

/// @brief Standardized economic / news event record.
struct SGmNewsEvent
  {
   long                      event_id;
   string                    name;
   string                    country;
   string                    currency;
   datetime                  event_time;
   ENUM_GM_NEWS_IMPACT       impact;
   double                    previous;
   double                    forecast;
   double                    actual;
   double                    revision;
   ENUM_GM_NEWS_EVENT_STATUS status;
   ENUM_GM_NEWS_PROVIDER     provider;
   bool                      gold_relevant;
   double                    impact_confidence;
   bool                      valid;

   void Reset(void)
     {
      event_id = 0;
      name = country = currency = "";
      event_time = 0;
      impact = GM_NEWS_IMPACT_VERY_LOW;
      previous = forecast = actual = revision = 0.0;
      status = GM_NEWS_STATUS_UNKNOWN;
      provider = GM_NEWS_PROVIDER_NONE;
      gold_relevant = false;
      impact_confidence = 0.0;
      valid = false;
     }
  };

struct SGmNewsMarketReaction
  {
   double                    spread_before;
   double                    spread_after;
   double                    atr_before;
   double                    atr_after;
   double                    atr_change_pct;
   bool                      spread_expansion;
   bool                      vol_spike;
   bool                      momentum_change;
   bool                      trend_continuation;
   bool                      trend_reversal;
   bool                      liquidity_expansion;
   bool                      price_acceleration;
   bool                      gap_detected;
   ENUM_GM_NEWS_REACTION     primary;
   string                    summary;

   void Reset(void)
     {
      spread_before = spread_after = 0.0;
      atr_before = atr_after = atr_change_pct = 0.0;
      spread_expansion = vol_spike = momentum_change = false;
      trend_continuation = trend_reversal = false;
      liquidity_expansion = price_acceleration = gap_detected = false;
      primary = GM_NEWS_REACT_NONE;
      summary = "";
     }
  };

struct SGmNewsAnalysisResult
  {
   datetime                  stamped_at;
   string                    symbol;
   ulong                     session_id;
   ENUM_GM_NEWS_PROVIDER     active_provider;
   string                    engine_status;

   SGmNewsEvent              upcoming;
   SGmNewsEvent              next_high_impact;
   SGmNewsEvent              last_released;
   int                       seconds_until_next;
   int                       seconds_until_high;
   int                       event_count;

   ENUM_GM_NEWS_IMPACT       current_impact;
   double                    news_risk_score;
   ENUM_GM_NEWS_REACTION     reaction_status;
   SGmNewsMarketReaction     reaction;

   bool                      gold_monitor_active;
   string                    gold_monitor_summary;
   int                       gold_event_count;

   double                    confidence;
   string                    insight;
   bool                      trade_block_allowed;   // ALWAYS false
   bool                      valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = "";
      session_id = 0;
      active_provider = GM_NEWS_PROVIDER_NONE;
      engine_status = "IDLE";
      upcoming.Reset();
      next_high_impact.Reset();
      last_released.Reset();
      seconds_until_next = seconds_until_high = 0;
      event_count = 0;
      current_impact = GM_NEWS_IMPACT_VERY_LOW;
      news_risk_score = 0.0;
      reaction_status = GM_NEWS_REACT_NONE;
      reaction.Reset();
      gold_monitor_active = false;
      gold_monitor_summary = "";
      gold_event_count = 0;
      confidence = 0.0;
      insight = "";
      trade_block_allowed = false; // HARD RULE — never block trades
      valid = false;
     }
  };

#endif // GM_SGM_NEWS_ANALYSIS_RESULT_MQH
//+------------------------------------------------------------------+
