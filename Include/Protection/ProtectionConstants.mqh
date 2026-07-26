//+------------------------------------------------------------------+
//|                                        ProtectionConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_PROTECTION_CONSTANTS_MQH
#define GM_PROTECTION_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file ProtectionConstants.mqh
/// @brief Sprint 6 Capital Protection defaults (monitor/warn — no halt yet).

#define GM_PROT_ENABLE_DEFAULT              true
#define GM_PROT_MAX_SPREAD_POINTS_DEFAULT   500
#define GM_PROT_MAX_DD_WARN_PCT_DEFAULT     10.0   // % equity drawdown warning
#define GM_PROT_MAX_DAILY_LOSS_WARN_DEFAULT 5.0    // % daily loss warning
#define GM_PROT_DETAILED_LOGS_DEFAULT       false
#define GM_PROT_STATE_FILE_PREFIX           "GM_Protection_"
#define GM_PROT_HEALTH_STALE_SEC            120
#define GM_PROT_EXEC_SLOW_US                500000 // 0.5s abnormal execution

#endif // GM_PROTECTION_CONSTANTS_MQH
//+------------------------------------------------------------------+
