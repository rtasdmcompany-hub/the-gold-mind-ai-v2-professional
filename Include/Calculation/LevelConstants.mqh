//+------------------------------------------------------------------+
//|                                            LevelConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_LEVEL_CONSTANTS_MQH
#define GM_LEVEL_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file LevelConstants.mqh
/// @brief Official Gold Mind H4 level fractions — FROZEN (Phase 1 Architecture Freeze).
/// @details Source: CalculateH4GridLevels() in production The_Gold_Mind.mq5
///          Buy  = Low  - diff * fraction
///          Sell = High + diff * fraction
/// @warning DO NOT CHANGE — Phase 2+ must not modify these constants.

#define GM_LEVEL_FRAC_1           0.20
#define GM_LEVEL_FRAC_2           0.58
#define GM_LEVEL_FRAC_3           0.92

#define GM_COMMENT_BL1            "GM_BL1"
#define GM_COMMENT_BL2            "GM_BL2"
#define GM_COMMENT_BL3            "GM_BL3"
#define GM_COMMENT_SL1            "GM_SL1"
#define GM_COMMENT_SL2            "GM_SL2"
#define GM_COMMENT_SL3            "GM_SL3"

#define GM_TRADE_ID_MARKER        "#T"
#define GM_LEVEL_COUNT            6

#endif // GM_LEVEL_CONSTANTS_MQH
//+------------------------------------------------------------------+
