//+------------------------------------------------------------------+
//|                                       SGmValidationResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_VALIDATION_RESULT_MQH
#define GM_SGM_VALIDATION_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ValidationConstants.mqh"

/// @file SGmValidationResult.mqh
/// @brief Validation check / error / score structures.

enum ENUM_GM_VAL_SEVERITY
  {
   GM_VAL_SEV_INFO = 0,
   GM_VAL_SEV_WARNING,
   GM_VAL_SEV_MINOR,
   GM_VAL_SEV_MAJOR,
   GM_VAL_SEV_CRITICAL,
   GM_VAL_SEV_PERF,
   GM_VAL_SEV_RECOVERY
  };

enum ENUM_GM_VAL_STATUS
  {
   GM_VAL_PENDING = 0,
   GM_VAL_PASS,
   GM_VAL_FAIL,
   GM_VAL_SKIP
  };

struct SGmValCheck
  {
   string            name;
   string            module;
   ENUM_GM_VAL_STATUS status;
   string            detail;
   bool              used;

   void Reset(void)
     {
      name = "";
      module = "";
      status = GM_VAL_PENDING;
      detail = "";
      used = false;
     }
  };

struct SGmValError
  {
   ENUM_GM_VAL_SEVERITY severity;
   string               module;
   string               message;
   string               fix;
   bool                 used;

   void Reset(void)
     {
      severity = GM_VAL_SEV_INFO;
      module = "";
      message = "";
      fix = "";
      used = false;
     }
  };

struct SGmBacktestMetrics
  {
   int    total_trades;
   int    winning_trades;
   int    losing_trades;
   double win_rate;
   double profit_factor;
   double max_drawdown;
   double average_win;
   double average_loss;
   double risk_reward;
   double net_profit;
   double recovery_factor;
   double expectancy;
   double gross_profit;
   double gross_loss;
   bool   valid;

   void Reset(void)
     {
      total_trades = 0;
      winning_trades = 0;
      losing_trades = 0;
      win_rate = 0.0;
      profit_factor = 0.0;
      max_drawdown = 0.0;
      average_win = 0.0;
      average_loss = 0.0;
      risk_reward = 0.0;
      net_profit = 0.0;
      recovery_factor = 0.0;
      expectancy = 0.0;
      gross_profit = 0.0;
      gross_loss = 0.0;
      valid = false;
     }
  };

struct SGmFinalValidation
  {
   double architecture_score;
   double module_score;
   double strategy_score;
   double performance_score;
   double risk_score;
   double recovery_score;
   double compiler_score;
   double overall_score;
   bool   production_ready;
   bool   passed;
   string decision;
   string summary;

   void Reset(void)
     {
      architecture_score = 0.0;
      module_score = 0.0;
      strategy_score = 0.0;
      performance_score = 0.0;
      risk_score = 0.0;
      recovery_score = 0.0;
      compiler_score = 100.0; // set at build time
      overall_score = 0.0;
      production_ready = false;
      passed = false;
      decision = "PENDING";
      summary = "";
     }
  };

#endif // GM_SGM_VALIDATION_RESULT_MQH
//+------------------------------------------------------------------+
