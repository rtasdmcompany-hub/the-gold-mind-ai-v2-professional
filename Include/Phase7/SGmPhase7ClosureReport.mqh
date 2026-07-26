//+------------------------------------------------------------------+
//|                                    SGmPhase7ClosureReport.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_PHASE7_CLOSURE_REPORT_MQH
#define GM_SGM_PHASE7_CLOSURE_REPORT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "Phase7ClosureConstants.mqh"

struct SGmPhase7ClosureReport
  {
   datetime stamped_at;
   string   rc_label;
   int      modules_audited;
   int      modules_pass;
   int      modules_fail;

   double   performance_score;
   double   security_score;
   double   reliability_score;
   double   functional_score;
   double   safety_score;
   double   dashboard_validation_score;
   double   documentation_score;
   double   ecosystem_completion_pct;
   double   phase_completion_pct;
   double   overall_score;

   string   reliability_grade;
   string   decision;
   string   recommendation;
   string   safety_summary;
   string   security_certificate;
   string   functional_summary;
   string   performance_summary;
   string   security_summary;
   string   reliability_summary;
   string   architecture_summary;

   bool     core_frozen;
   bool     dashboard_frozen;
   bool     ai_phase3_frozen;
   bool     phase4_complete;
   bool     phase5_frozen;
   bool     phase6_frozen;
   bool     phase7_frozen;
   bool     production_ready;
   bool     valid;

   void Reset(void)
     {
      stamped_at = 0;
      rc_label = GM_PHASE7_RC_LABEL;
      modules_audited = modules_pass = modules_fail = 0;
      performance_score = security_score = reliability_score = 0.0;
      functional_score = safety_score = dashboard_validation_score = 0.0;
      documentation_score = ecosystem_completion_pct = phase_completion_pct = 0.0;
      overall_score = 0.0;
      reliability_grade = "—";
      decision = "FAIL";
      recommendation = "Review Phase 7 closure report";
      safety_summary = security_certificate = functional_summary = "";
      performance_summary = security_summary = reliability_summary = "";
      architecture_summary = "";
      core_frozen = dashboard_frozen = ai_phase3_frozen = false;
      phase4_complete = phase5_frozen = phase6_frozen = phase7_frozen = false;
      production_ready = false;
      valid = false;
     }
  };

#endif // GM_SGM_PHASE7_CLOSURE_REPORT_MQH
//+------------------------------------------------------------------+
