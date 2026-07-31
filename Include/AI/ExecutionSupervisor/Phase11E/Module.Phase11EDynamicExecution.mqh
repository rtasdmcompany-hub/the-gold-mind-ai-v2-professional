//+------------------------------------------------------------------+
//|              Module.Phase11EDynamicExecution.mqh                 |
//|  Phase 11E module registration — Dynamic Pre-Activation Engine   |
//+------------------------------------------------------------------+
#ifndef GM_MODULE_PHASE11E_DYNAMIC_EXECUTION_MQH
#define GM_MODULE_PHASE11E_DYNAMIC_EXECUTION_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "Phase11EConstants.mqh"
#include "CPhase11EDynamicExecutionEngine.mqh"

#define GM_PHASE11E_DYNAMIC_EXECUTION_ACTIVE 1
#define GM_PHASE11E_EXECUTION_LABEL "PHASE11E_DYNAMIC_PRE_ACTIVATION_ENGINE"

string GmPhase11EModuleBanner(void)
  {
   return StringFormat("THE GOLD MIND AI | %s | %s | Trading Engine MASTER | AI PRE-ACTIVATION ONLY | DYNAMIC",
                       GM_P11E_VERSION, GM_PHASE11E_EXECUTION_LABEL);
  }

#endif // GM_MODULE_PHASE11E_DYNAMIC_EXECUTION_MQH
//+------------------------------------------------------------------+
