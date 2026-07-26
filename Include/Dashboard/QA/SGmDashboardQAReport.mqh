//+------------------------------------------------------------------+
//|                                      SGmDashboardQAReport.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_DASHBOARD_QA_REPORT_MQH
#define GM_SGM_DASHBOARD_QA_REPORT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "DashboardQAConstants.mqh"

struct SGmDashboardQAReport
  {
   datetime stamped_at;
   string   rc_label;
   double   performance_score;      // 0..100
   double   ui_stability_score;
   double   sync_accuracy_pct;
   double   recovery_success_pct;
   double   rendering_quality;
   double   avg_collect_us;
   double   peak_collect_us;
   ulong    memory_kb_start;
   ulong    memory_kb_end;
   ulong    memory_kb_peak;
   double   cpu_est_pct;
   int      stress_pass;
   int      stress_fail;
   int      sync_pass;
   int      sync_fail;
   int      visual_pass;
   int      visual_fail;
   int      settings_pass;
   int      settings_fail;
   int      recovery_pass;
   int      recovery_fail;
   int      modules_verified;
   string   decision;               // PASS / FAIL
   string   known_issues;
   string   compatibility;
   bool     valid;

   void Reset(void)
     {
      stamped_at = 0;
      rc_label = GM_DASH_QA_RC_LABEL;
      performance_score = 0.0;
      ui_stability_score = 0.0;
      sync_accuracy_pct = 0.0;
      recovery_success_pct = 0.0;
      rendering_quality = 0.0;
      avg_collect_us = 0.0;
      peak_collect_us = 0.0;
      memory_kb_start = 0;
      memory_kb_end = 0;
      memory_kb_peak = 0;
      cpu_est_pct = 0.0;
      stress_pass = 0;
      stress_fail = 0;
      sync_pass = 0;
      sync_fail = 0;
      visual_pass = 0;
      visual_fail = 0;
      settings_pass = 0;
      settings_fail = 0;
      recovery_pass = 0;
      recovery_fail = 0;
      modules_verified = 0;
      decision = "FAIL";
      known_issues = "None";
      compatibility = "MT5 Build Compatible";
      valid = false;
     }
  };

#endif // GM_SGM_DASHBOARD_QA_REPORT_MQH
//+------------------------------------------------------------------+
