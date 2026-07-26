//+------------------------------------------------------------------+
//|                                        TradeMgmtConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_TRADE_MGMT_CONSTANTS_MQH
#define GM_TRADE_MGMT_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file TradeMgmtConstants.mqh
/// @brief Sprint 5 trade-management constants — FROZEN (Phase 1).
/// @warning DO NOT invent strategy math. Phase 2 must not alter these values.

#define GM_BE_TRIGGER_PIPS            50.0    // Break Even at +50 pips
#define GM_PARTIAL_CLOSE_PERCENT      80.0    // Close 80%, leave 20%
#define GM_TRAIL_DISTANCE_PIPS        30.0    // Trailing distance 30 pips
#define GM_RUNNER_PERCENT             20.0

#endif // GM_TRADE_MGMT_CONSTANTS_MQH
//+------------------------------------------------------------------+
