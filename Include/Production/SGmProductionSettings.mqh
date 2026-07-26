//+------------------------------------------------------------------+
//|                                     SGmProductionSettings.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_PRODUCTION_SETTINGS_MQH
#define GM_SGM_PRODUCTION_SETTINGS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ProductionConstants.mqh"
#include "../Logging/EnumsLogging.mqh"

/// @file SGmProductionSettings.mqh
/// @brief Production / Debug / Development runtime configuration.

struct SGmProductionSettings
  {
   ENUM_GM_RUNTIME_MODE runtime_mode;
   ENUM_GM_LOG_LEVEL    logging_level;
   bool                 recovery_mode;
   bool                 performance_mode;
   bool                 enable_fail_safe;
   bool                 enable_security_guard;
   bool                 enable_live_validation;
   bool                 enterprise_logging;

   void Defaults(void)
     {
      runtime_mode = GM_MODE_PRODUCTION;
      logging_level = GM_LOG_INFO;
      recovery_mode = true;
      performance_mode = true;
      enable_fail_safe = true;
      enable_security_guard = true;
      enable_live_validation = true;
      enterprise_logging = true;
     }

   bool IsProduction(void) const { return (runtime_mode == GM_MODE_PRODUCTION); }
   bool IsDebug(void) const { return (runtime_mode == GM_MODE_DEBUG); }
   bool IsDevelopment(void) const { return (runtime_mode == GM_MODE_DEVELOPMENT); }
  };

#endif // GM_SGM_PRODUCTION_SETTINGS_MQH
//+------------------------------------------------------------------+
