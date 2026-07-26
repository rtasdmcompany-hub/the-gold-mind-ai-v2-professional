//+------------------------------------------------------------------+
//|                                              SGmAISnapshot.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_AI_SNAPSHOT_MQH
#define GM_SGM_AI_SNAPSHOT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "AIConstants.mqh"

/// @file SGmAISnapshot.mqh
/// @brief AI Dashboard + Decision Center + Market Info snapshot (READ-ONLY).

struct SGmAISnapshot
  {
   datetime           stamped_at;
   long               magic;
   string             symbol;

   //--- Decision Center
   string             ai_status;
   string             ai_engine;
   string             ai_version;
   string             learning_status;
   string             decision_status;
   string             confidence_status;
   string             prediction_status;
   string             current_mode;
   string             future_ai_score;
   double             confidence_pct;

   //--- Information Panel widgets (Coming Soon until Phase 3)
   string             w_market_analyzer;
   string             w_trend_detector;
   string             w_volatility_scanner;
   string             w_news_analyzer;
   string             w_trade_confidence;
   string             w_recovery_ai;
   string             w_learning_engine;

   //--- Market Information Panel (live)
   double             spread_points;
   double             atr14;
   double             candle_size_cur;
   double             candle_size_prev;
   double             daily_range;
   double             weekly_range;
   ulong              h4_session_id;
   string             market_volatility;
   string             market_activity;

   //--- Source health (from Core observation)
   int                registry_count;
   int                running_trades;
   int                pending_orders;
   double             equity;
   double             balance;
   double             current_dd_pct;
   double             overall_win_rate;
   bool               recovery_ok;
   bool               dashboard_ok;
   bool               analytics_ok;

   //--- Perf
   ulong              collect_us;
   ulong              memory_kb;
   bool               valid;

   void Reset(void)
     {
      stamped_at = 0;
      magic = 0;
      symbol = "";
      ai_status = GM_AI_NOT_INITIALIZED;
      ai_engine = GM_AI_ENGINE_NAME;
      ai_version = GM_AI_VERSION_STRING;
      learning_status = GM_AI_NOT_INITIALIZED;
      decision_status = GM_AI_NOT_INITIALIZED;
      confidence_status = GM_AI_NOT_INITIALIZED;
      prediction_status = GM_AI_NOT_INITIALIZED;
      current_mode = "OFFLINE";
      future_ai_score = GM_AI_COMING_SOON;
      confidence_pct = 0.0;
      w_market_analyzer = GM_AI_COMING_SOON;
      w_trend_detector = GM_AI_COMING_SOON;
      w_volatility_scanner = GM_AI_COMING_SOON;
      w_news_analyzer = GM_AI_COMING_SOON;
      w_trade_confidence = GM_AI_COMING_SOON;
      w_recovery_ai = GM_AI_COMING_SOON;
      w_learning_engine = GM_AI_COMING_SOON;
      spread_points = 0.0;
      atr14 = 0.0;
      candle_size_cur = 0.0;
      candle_size_prev = 0.0;
      daily_range = 0.0;
      weekly_range = 0.0;
      h4_session_id = 0;
      market_volatility = "—";
      market_activity = "—";
      registry_count = 0;
      running_trades = 0;
      pending_orders = 0;
      equity = 0.0;
      balance = 0.0;
      current_dd_pct = 0.0;
      overall_win_rate = 0.0;
      recovery_ok = false;
      dashboard_ok = false;
      analytics_ok = false;
      collect_us = 0;
      memory_kb = 0;
      valid = false;
     }
  };

#endif // GM_SGM_AI_SNAPSHOT_MQH
//+------------------------------------------------------------------+
