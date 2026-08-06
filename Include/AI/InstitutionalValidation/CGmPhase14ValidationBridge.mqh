//+------------------------------------------------------------------+
//|                            CGmPhase14ValidationBridge.mqh    |
//|  Thin EA hooks — Feature Flag AI_VALIDATION_ENABLED          |
//|  Integrate ONLY before OrderSend / Place* trade calls        |
//+------------------------------------------------------------------+
#ifndef GM_CGM_PHASE14_VALIDATION_BRIDGE_MQH
#define GM_CGM_PHASE14_VALIDATION_BRIDGE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CInstitutionalValidationEngine.mqh"

input group "--- PHASE 14 Institutional AI Validation (enhancement layer) ---"
input bool   AI_VALIDATION_ENABLED        = false; // OFF = zero change (backtests stay valid)
input bool   AI_VALIDATION_ALLOW_OPTIONAL = true;  // Allow 70-84 confidence band

static CInstitutionalValidationEngine g_p14;

void GmP14_OnInit(const int atrHandle)
  {
   g_p14.Configure(AI_VALIDATION_ENABLED, AI_VALIDATION_ALLOW_OPTIONAL, atrHandle);
  }

void GmP14_OnDeinit(void)
  {
   // nothing to release — uses shared ATR handle from EA
  }

// Returns true to proceed with OrderSend. May nudge SL/TP within optimizer rules.
bool GmP14_ValidateBeforeOrderSend(const bool isBuy,
                                   const double entry,
                                   double &sl,
                                   double &tp,
                                   const string comment,
                                   const int levelIndex)
  {
   return g_p14.ValidateBeforeOrderSend(isBuy, entry, sl, tp, comment, levelIndex);
  }

bool GmP14_IsEnabled(void)
  {
   return g_p14.IsEnabled();
  }

#endif // GM_CGM_PHASE14_VALIDATION_BRIDGE_MQH
//+------------------------------------------------------------------+
