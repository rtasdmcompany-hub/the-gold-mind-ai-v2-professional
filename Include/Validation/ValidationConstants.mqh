//+------------------------------------------------------------------+
//|                                        ValidationConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_VALIDATION_CONSTANTS_MQH
#define GM_VALIDATION_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file ValidationConstants.mqh
/// @brief Sprint 8 validation / backtest defaults (read-only verification).

#define GM_VAL_REPORT_PREFIX          "GM_ValidationReport_"
#define GM_VAL_BACKTEST_PREFIX        "GM_BacktestMetrics_"
#define GM_VAL_STRESS_PREFIX          "GM_StressReport_"
#define GM_VAL_MAX_CHECKS             64
#define GM_VAL_MAX_ERRORS             128
#define GM_VAL_SL_PIP_TOLERANCE       0.5
#define GM_VAL_LEVEL_PRICE_TOLERANCE  0.00001
#define GM_VAL_PASS_SCORE_MIN         80.0
#define GM_VAL_PERF_SLOW_US           750000
#define GM_VAL_ENABLE_DEFAULT         true
#define GM_VAL_STRESS_DEFAULT         true
#define GM_VAL_BACKTEST_DEFAULT       true

#endif // GM_VALIDATION_CONSTANTS_MQH
//+------------------------------------------------------------------+
