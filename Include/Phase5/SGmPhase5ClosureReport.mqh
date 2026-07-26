//+------------------------------------------------------------------+
//|                                    SGmPhase5ClosureReport.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_PHASE5_CLOSURE_REPORT_MQH
#define GM_SGM_PHASE5_CLOSURE_REPORT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "Phase5ClosureConstants.mqh"

struct SGmPhase5ClosureReport
  {
   datetime stamped_at;
   string   rc_label;
   int      modules_audited;
   int      modules_pass;
   int      modules_fail;

   double   performance_score;
   double   accuracy_score;
   double   reliability_score;
   double   safety_score;
   double   scalability_score;
   double   maintainability_score;
   double   future_expansion_score;
   double   dashboard_validation_score;
   double   documentation_score;
   double   ai_completion_pct;
   double   phase_completion_pct;
   double   overall_score;

   string   reliability_grade;
   string   decision;
   string   recommendation;
   string   safety_summary;
   string   safety_certificate;
   string   performance_summary;
   string   accuracy_summary;
   string   reliability_summary;
   string   architecture_summary;

   bool     core_frozen;
   bool     dashboard_frozen;
   bool     ai_phase3_frozen;
   bool     phase4_complete;
   bool     phase5_frozen;
   bool     production_ready;
   bool     valid;

   void Reset(void)
     {
      stamped_at = 0;
      rc_label = GM_PHASE5_RC_LABEL;
      modules_audited = modules_pass = modules_fail = 0;
      performance_score = accuracy_score = reliability_score = 0.0;
      safety_score = scalability_score = maintainability_score = 0.0;
      future_expansion_score = dashboard_validation_score = documentation_score = 0.0;
      ai_completion_pct = phase_completion_pct = overall_score = 0.0;
      reliability_grade = "—";
      decision = "FAIL";
      recommendation = "Review Phase 5 closure report";
      safety_summary = safety_certificate = "";
      performance_summary = accuracy_summary = reliability_summary = "";
      architecture_summary = "";
      core_frozen = dashboard_frozen = ai_phase3_frozen = false;
      phase4_complete = phase5_frozen = production_ready = false;
      valid = false;
     }
  };

#endif // GM_SGM_PHASE5_CLOSURE_REPORT_MQH
//+------------------------------------------------------------------+
