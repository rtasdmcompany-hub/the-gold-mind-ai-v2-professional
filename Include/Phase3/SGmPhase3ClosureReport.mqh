//+------------------------------------------------------------------+
//|                                    SGmPhase3ClosureReport.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_PHASE3_CLOSURE_REPORT_MQH
#define GM_SGM_PHASE3_CLOSURE_REPORT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "Phase3ClosureConstants.mqh"

struct SGmPhase3ClosureReport
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
   double   ai_completion_pct;
   double   phase_completion_pct;
   double   overall_score;

   string   reliability_grade;
   string   decision;
   string   recommendation;
   string   safety_summary;

   bool     ai_frozen;
   bool     core_frozen;
   bool     dashboard_frozen;
   bool     valid;

   void Reset(void)
     {
      stamped_at = 0;
      rc_label = GM_PHASE3_RC_LABEL;
      modules_audited = modules_pass = modules_fail = 0;
      performance_score = accuracy_score = reliability_score = 0.0;
      safety_score = scalability_score = maintainability_score = 0.0;
      future_expansion_score = ai_completion_pct = phase_completion_pct = 0.0;
      overall_score = 0.0;
      reliability_grade = "—";
      decision = "FAIL";
      recommendation = "Review Phase 3 closure report";
      safety_summary = "";
      ai_frozen = core_frozen = dashboard_frozen = false;
      valid = false;
     }
  };

#endif // GM_SGM_PHASE3_CLOSURE_REPORT_MQH
//+------------------------------------------------------------------+
