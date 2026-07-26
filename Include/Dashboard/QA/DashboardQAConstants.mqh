//+------------------------------------------------------------------+
//|                                    DashboardQAConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_DASHBOARD_QA_CONSTANTS_MQH
#define GM_DASHBOARD_QA_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file DashboardQAConstants.mqh
/// @brief Phase 2 Sprint 9 — Dashboard QA / stress / RC-1 (READ-ONLY).

#define GM_DASH_QA_STRESS_LOOPS         50
#define GM_DASH_QA_MEM_SAMPLES          32
#define GM_DASH_QA_RUNTIME_MILESTONE_H  12
#define GM_DASH_QA_REPORT_PREFIX        "GM_DASH_QA_"
#define GM_DASH_QA_RC_LABEL             "Dashboard-RC-1"
#define GM_DASH_LAYOUT_THROTTLE_MS      40

enum ENUM_GM_DASH_QA_STATUS
  {
   GM_DASH_QA_PASS = 0,
   GM_DASH_QA_WARN,
   GM_DASH_QA_FAIL
  };

#endif // GM_DASHBOARD_QA_CONSTANTS_MQH
//+------------------------------------------------------------------+
