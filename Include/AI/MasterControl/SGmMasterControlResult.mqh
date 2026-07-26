//+------------------------------------------------------------------+
//|                                    SGmMasterControlResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_MASTER_CONTROL_RESULT_MQH
#define GM_SGM_MASTER_CONTROL_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "MasterControlAIConstants.mqh"

struct SGmMasterControlResult
  {
   datetime            stamped_at;
   string              symbol;
   ulong               session_id;
   ENUM_GM_MCC_STATUS  status;

   // Master overview
   string              system_health;
   double              ai_intelligence;
   string              risk_status;
   string              market_condition;
   string              learning_status;
   string              master_overview;

   // Unified health
   double              ai_health_score;
   ENUM_GM_MCC_GRADE   ai_health_grade;
   string              supervisor_status;
   string              reporting_status;
   string              forecast_status;
   string              assistant_status;
   string              enterprise_status;
   string              orchestration_status;
   string              database_status;
   string              api_status;
   string              unified_status_report;

   // Integration
   int                 modules_connected;
   int                 modules_expected;
   string              integration_map;
   string              integration_report;

   // Ops dashboard panels
   string              panel_master;
   string              panel_system_health;
   string              panel_market;
   string              panel_risk;
   string              panel_forecast;
   string              panel_learning;
   string              panel_reports;
   string              panel_assistant;
   string              panel_enterprise;
   string              panel_audit;

   // Audit / production / security
   double              audit_score;
   string              audit_report;
   bool                audit_pass;
   double              production_readiness;
   string              production_status;
   string              production_report;
   bool                security_pass;
   string              security_report;
   string              database_audit_report;
   string              performance_report;

   string              center_status;
   string              phase4_status;
   string              advisory_status;
   string              insight;
   bool                may_execute;
   bool                may_modify_risk;
   bool                may_modify_strategy;
   bool                from_cache;
   bool                valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = "";
      session_id = 0;
      status = GM_MCC_STATUS_IDLE;
      system_health = risk_status = market_condition = learning_status = "";
      ai_intelligence = 0.0;
      master_overview = "";
      ai_health_score = 0.0;
      ai_health_grade = GM_MCC_GRADE_UNKNOWN;
      supervisor_status = reporting_status = forecast_status = "";
      assistant_status = enterprise_status = orchestration_status = "";
      database_status = api_status = unified_status_report = "";
      modules_connected = modules_expected = 0;
      integration_map = integration_report = "";
      panel_master = panel_system_health = panel_market = panel_risk = "";
      panel_forecast = panel_learning = panel_reports = panel_assistant = "";
      panel_enterprise = panel_audit = "";
      audit_score = production_readiness = 0.0;
      audit_report = production_status = production_report = "";
      security_report = database_audit_report = performance_report = "";
      audit_pass = security_pass = false;
      center_status = "Idle";
      phase4_status = "";
      advisory_status = GM_MCC_ADVISORY;
      insight = "";
      may_execute = false;
      may_modify_risk = false;
      may_modify_strategy = false;
      from_cache = false;
      valid = false;
     }
  };

#endif // GM_SGM_MASTER_CONTROL_RESULT_MQH
//+------------------------------------------------------------------+
