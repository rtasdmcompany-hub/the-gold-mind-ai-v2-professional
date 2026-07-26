//+------------------------------------------------------------------+
//|                                      SGmValidationSettings.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_VALIDATION_SETTINGS_MQH
#define GM_SGM_VALIDATION_SETTINGS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ValidationConstants.mqh"

/// @file SGmValidationSettings.mqh
/// @brief Configurable Sprint 8 validation options.

struct SGmValidationSettings
  {
   bool enable_validation;
   bool enable_backtest_metrics;
   bool enable_stress_tests;
   bool run_on_startup;

   void Defaults(void)
     {
      enable_validation = GM_VAL_ENABLE_DEFAULT;
      enable_backtest_metrics = GM_VAL_BACKTEST_DEFAULT;
      enable_stress_tests = GM_VAL_STRESS_DEFAULT;
      run_on_startup = true;
     }
  };

#endif // GM_SGM_VALIDATION_SETTINGS_MQH
//+------------------------------------------------------------------+
