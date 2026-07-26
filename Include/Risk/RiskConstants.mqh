//+------------------------------------------------------------------+
//|                                             RiskConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_RISK_CONSTANTS_MQH
#define GM_RISK_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file RiskConstants.mqh
/// @brief Official Gold Mind risk / SL / ATR constants — FROZEN (Phase 1).
/// @warning DO NOT invent or modify — Phase 2 AI layers on top only.

#define GM_RISK_EQUITY_FRACTION       0.03      // 3% of equity per trade
#define GM_FIXED_SL_PIPS              30.0      // Fixed Stop Loss = 30 pips
#define GM_ATR_PERIOD                 14        // ATR(14)
#define GM_ATR_TP_MULTIPLIER          1.0       // TP = 1.0 × live H4 ATR
#define GM_ATR_TIMEFRAME              PERIOD_H4
#define GM_MAX_SPREAD_POINTS_DEFAULT  500       // Broker spread gate (points)
#define GM_ORDER_RETRY_MAX            3
#define GM_ORDER_RETRY_SLEEP_MS       250
#define GM_REGISTRY_MAX_TRADES        128
#define GM_REGISTRY_FILE_PREFIX       "GM_TradeRegistry_"

#endif // GM_RISK_CONSTANTS_MQH
//+------------------------------------------------------------------+
