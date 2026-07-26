//+------------------------------------------------------------------+
//|                                     AnalyticsConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_ANALYTICS_CONSTANTS_MQH
#define GM_ANALYTICS_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file AnalyticsConstants.mqh
/// @brief Phase 2 Sprint 3 — Analytics Engine defaults (READ-ONLY).

#define GM_ANALYTICS_HISTORY_DAYS       365
#define GM_ANALYTICS_HISTORY_THROTTLE_S  3
#define GM_ANALYTICS_PERF_WINDOW         64

enum ENUM_GM_EXPORT_TARGET
  {
   GM_EXPORT_CSV = 0,
   GM_EXPORT_JSON,
   GM_EXPORT_DATABASE,
   GM_EXPORT_CLOUD_API,
   GM_EXPORT_MOBILE,
   GM_EXPORT_WEB
  };

#endif // GM_ANALYTICS_CONSTANTS_MQH
//+------------------------------------------------------------------+
