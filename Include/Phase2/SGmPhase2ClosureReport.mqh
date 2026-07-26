//+------------------------------------------------------------------+
//|                                    SGmPhase2ClosureReport.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_PHASE2_CLOSURE_REPORT_MQH
#define GM_SGM_PHASE2_CLOSURE_REPORT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "Phase2ClosureConstants.mqh"

struct SGmPhase2ClosureReport
  {
   datetime stamped_at;
   string   rc_label;
   int      modules_audited;
   int      modules_pass;
   int      modules_fail;
   double   ui_cert_score;
   double   analytics_cert_score;
   double   health_score;
   double   ai_readiness_score;
   double   performance_score;
   double   security_score;
   double   scalability_score;
   double   maintainability_score;
   double   production_readiness_score;
   double   phase_completion_pct;
   double   overall_score;
   string   dashboard_status;
   string   analytics_status;
   string   decision;               // PASS / FAIL
   string   recommendation;
   bool     dashboard_frozen;
   bool     core_frozen;
   bool     valid;

   void Reset(void)
     {
      stamped_at = 0;
      rc_label = GM_PHASE2_RC_LABEL;
      modules_audited = 0;
      modules_pass = 0;
      modules_fail = 0;
      ui_cert_score = 0.0;
      analytics_cert_score = 0.0;
      health_score = 0.0;
      ai_readiness_score = 0.0;
      performance_score = 0.0;
      security_score = 0.0;
      scalability_score = 0.0;
      maintainability_score = 0.0;
      production_readiness_score = 0.0;
      phase_completion_pct = 0.0;
      overall_score = 0.0;
      dashboard_status = "UNKNOWN";
      analytics_status = "UNKNOWN";
      decision = "FAIL";
      recommendation = "Review Phase 2 closure report";
      dashboard_frozen = false;
      core_frozen = false;
      valid = false;
     }
  };

#endif // GM_SGM_PHASE2_CLOSURE_REPORT_MQH
//+------------------------------------------------------------------+
