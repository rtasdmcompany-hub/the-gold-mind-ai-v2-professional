//+------------------------------------------------------------------+
//|              Module.Phase11BExecutionAuthority.mqh               |
//|     Phase 11B module registration for enterprise AI stack        |
//+------------------------------------------------------------------+
#ifndef GM_MODULE_PHASE11B_EXECUTION_AUTHORITY_MQH
#define GM_MODULE_PHASE11B_EXECUTION_AUTHORITY_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "Phase11BConstants.mqh"
#include "CPhase11BExecutionAuthority.mqh"

#define GM_PHASE11B_EXECUTION_AUTHORITY_ACTIVE 1
#define GM_PHASE11B_EXECUTION_LABEL "PHASE11B_PRE_ACTIVATION_AUTHORITY"

string GmPhase11BModuleBanner(void)
  {
   return StringFormat("THE GOLD MIND AI | %s | %s | Trading Engine MASTER | AI PRE-ACTIVATION ONLY",
                       GM_P11B_VERSION, GM_PHASE11B_EXECUTION_LABEL);
  }

#endif // GM_MODULE_PHASE11B_EXECUTION_AUTHORITY_MQH
//+------------------------------------------------------------------+
