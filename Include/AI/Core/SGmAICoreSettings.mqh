//+------------------------------------------------------------------+
//|                                          SGmAICoreSettings.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_AI_CORE_SETTINGS_MQH
#define GM_SGM_AI_CORE_SETTINGS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "Phase3AIConstants.mqh"

/// @file SGmAICoreSettings.mqh
/// @brief Phase 3 AI Core configuration (ANALYSIS ONLY — no execution flags).

struct SGmAICoreSettings
  {
   bool                 enable_ai;
   ENUM_GM_AI_CORE_MODE mode;
   bool                 safe_mode;
   bool                 learning_mode;
   bool                 analysis_only;       ///< Always true in Phase 3
   bool                 simulation_mode;
   bool                 future_live_blocked; ///< Always true — Live Decision cannot execute
   int                  process_throttle_ms;
   int                  bus_throttle_ms;
   bool                 persist_database;

   void Defaults(void)
     {
      enable_ai = true;
      mode = GM_AI_CORE_MODE_ANALYSIS_ONLY;
      safe_mode = false;
      learning_mode = false;
      analysis_only = true;
      simulation_mode = false;
      future_live_blocked = true;
      process_throttle_ms = GM_AI_CORE_PROCESS_THROTTLE_MS;
      bus_throttle_ms = GM_AI_CORE_BUS_THROTTLE_MS;
      persist_database = true;
     }

   void Clamp(void)
     {
      // Phase 3 hard rule: analysis only — never unlock execution
      analysis_only = true;
      future_live_blocked = true;
      if(!enable_ai)
         mode = GM_AI_CORE_MODE_DISABLED;
      else if(safe_mode)
         mode = GM_AI_CORE_MODE_SAFE;
      else if(learning_mode)
         mode = GM_AI_CORE_MODE_LEARNING;
      else if(simulation_mode)
         mode = GM_AI_CORE_MODE_SIMULATION;
      else if(mode == GM_AI_CORE_MODE_FUTURE_LIVE)
         mode = GM_AI_CORE_MODE_ANALYSIS_ONLY; // force down
      else if(mode == GM_AI_CORE_MODE_DISABLED && enable_ai)
         mode = GM_AI_CORE_MODE_ANALYSIS_ONLY;

      if(process_throttle_ms < 100)
         process_throttle_ms = 100;
      if(process_throttle_ms > 5000)
         process_throttle_ms = 5000;
      if(bus_throttle_ms < 50)
         bus_throttle_ms = 50;
      if(bus_throttle_ms > 5000)
         bus_throttle_ms = 5000;
     }
  };

#endif // GM_SGM_AI_CORE_SETTINGS_MQH
//+------------------------------------------------------------------+
