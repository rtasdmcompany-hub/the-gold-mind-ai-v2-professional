//+------------------------------------------------------------------+
//|                                         SGmP14Validation.mqh |
//+------------------------------------------------------------------+
#ifndef GM_SGM_P14_VALIDATION_MQH
#define GM_SGM_P14_VALIDATION_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "Phase14Constants.mqh"

struct SGmP14ModuleResult
  {
   bool     pass;
   double   confidence;   // 0..100
   string   reason;

   void Reset(void)
     {
      pass = true;
      confidence = 100.0;
      reason = "";
     }
  };

struct SGmP14ValidationResult
  {
   bool                 enabled;
   bool                 approved;
   ENUM_GM_P14_VERDICT  verdict;
   double               h4_confidence;
   double               structure_confidence;
   double               institutional_confidence;
   double               market_confidence;
   double               final_confidence;
   bool                 structure_pass;
   bool                 institutional_pass;
   bool                 market_pass;
   double               sl_out;
   double               tp_out;
   bool                 sl_adjusted;
   bool                 tp_adjusted;
   string               why;

   void Reset(void)
     {
      enabled = false;
      approved = true;
      verdict = GM_P14_EXECUTE;
      h4_confidence = 100.0;
      structure_confidence = 100.0;
      institutional_confidence = 100.0;
      market_confidence = 100.0;
      final_confidence = 100.0;
      structure_pass = true;
      institutional_pass = true;
      market_pass = true;
      sl_out = 0.0;
      tp_out = 0.0;
      sl_adjusted = false;
      tp_adjusted = false;
      why = "";
     }
  };

#endif // GM_SGM_P14_VALIDATION_MQH
//+------------------------------------------------------------------+
