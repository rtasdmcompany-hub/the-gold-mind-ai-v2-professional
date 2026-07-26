//+------------------------------------------------------------------+
//|                                     SGmProtectionSettings.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_PROTECTION_SETTINGS_MQH
#define GM_SGM_PROTECTION_SETTINGS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ProtectionConstants.mqh"

/// @file SGmProtectionSettings.mqh
/// @brief Configurable Capital Protection inputs (no source change required).

struct SGmProtectionSettings
  {
   bool   enable_capital_protection;
   int    max_spread_points;
   double max_drawdown_warn_pct;
   double max_daily_loss_warn_pct;
   bool   enable_detailed_logs;

   void Defaults(void)
     {
      enable_capital_protection = GM_PROT_ENABLE_DEFAULT;
      max_spread_points = GM_PROT_MAX_SPREAD_POINTS_DEFAULT;
      max_drawdown_warn_pct = GM_PROT_MAX_DD_WARN_PCT_DEFAULT;
      max_daily_loss_warn_pct = GM_PROT_MAX_DAILY_LOSS_WARN_DEFAULT;
      enable_detailed_logs = GM_PROT_DETAILED_LOGS_DEFAULT;
     }
  };

#endif // GM_SGM_PROTECTION_SETTINGS_MQH
//+------------------------------------------------------------------+
