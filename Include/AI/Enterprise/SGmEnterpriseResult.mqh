//+------------------------------------------------------------------+
//|                                      SGmEnterpriseResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_ENTERPRISE_RESULT_MQH
#define GM_SGM_ENTERPRISE_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "EnterpriseAIConstants.mqh"

struct SGmEnterpriseAccountProfile
  {
   string account_id;
   string broker;
   string server;
   string account_type;
   string currency;
   string risk_profile;
   string connection_status;
   bool   valid;

   void Reset(void)
     {
      account_id = broker = server = account_type = currency = "";
      risk_profile = "Observed";
      connection_status = "Unknown";
      valid = false;
     }
  };

struct SGmEnterpriseResult
  {
   datetime                stamped_at;
   string                  symbol;
   ulong                   session_id;
   ENUM_GM_ENT_STATUS      status;

   // Multi-account overview
   int                     accounts_monitored;
   int                     healthy_accounts;
   int                     warning_accounts;
   int                     critical_accounts;
   string                  multi_account_report;

   // Local profile
   SGmEnterpriseAccountProfile local_profile;
   ENUM_GM_ENT_ACCT_HEALTH local_health;
   double                  local_equity;
   double                  local_dd_pct;
   double                  local_margin_usage;
   string                  local_recovery;
   string                  local_env;

   // Cloud foundation
   string                  cloud_system_status;
   string                  core_status;
   string                  dashboard_status;
   string                  api_health;
   string                  database_health;
   string                  connection_health;
   string                  service_availability;
   string                  cloud_health_report;

   // Comparison
   string                  comparison_report;
   string                  performance_map;
   string                  risk_overview;
   ENUM_GM_ENT_RANK        local_rank;

   // Fleet
   double                  fleet_health_score;
   string                  fleet_status;
   int                     connected_systems;
   int                     active_sessions;
   string                  learning_service;
   string                  reporting_service;
   string                  assistant_service;
   string                  enterprise_alerts;

   // API foundation
   string                  api_endpoints;
   bool                    api_execution_enabled; // ALWAYS false

   string                  enterprise_status;
   string                  advisory_status;
   string                  insight;
   bool                    may_execute;
   bool                    may_control_accounts;
   bool                    from_cache;
   bool                    valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = "";
      session_id = 0;
      status = GM_ENT_STATUS_IDLE;
      accounts_monitored = healthy_accounts = warning_accounts = critical_accounts = 0;
      multi_account_report = "";
      local_profile.Reset();
      local_health = GM_ENT_ACCT_UNKNOWN;
      local_equity = local_dd_pct = local_margin_usage = 0.0;
      local_recovery = local_env = "";
      cloud_system_status = core_status = dashboard_status = "";
      api_health = database_health = connection_health = service_availability = "";
      cloud_health_report = "";
      comparison_report = performance_map = risk_overview = "";
      local_rank = GM_ENT_RANK_UNKNOWN;
      fleet_health_score = 0.0;
      fleet_status = "—";
      connected_systems = active_sessions = 0;
      learning_service = reporting_service = assistant_service = "";
      enterprise_alerts = "None";
      api_endpoints = "";
      api_execution_enabled = false;
      enterprise_status = "Idle";
      advisory_status = GM_ENT_ADVISORY;
      insight = "";
      may_execute = false;
      may_control_accounts = false;
      from_cache = false;
      valid = false;
     }
  };

#endif // GM_SGM_ENTERPRISE_RESULT_MQH
//+------------------------------------------------------------------+
