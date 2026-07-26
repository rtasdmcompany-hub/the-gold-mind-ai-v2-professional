//+------------------------------------------------------------------+
//|                                        SGmAssistantResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_ASSISTANT_RESULT_MQH
#define GM_SGM_ASSISTANT_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "AssistantAIConstants.mqh"

struct SGmAssistWarning
  {
   ENUM_GM_WARN_TYPE type;
   string            message;
   double            severity;   // 0..100 informational
   bool              active;

   void Reset(void)
     {
      type = GM_WARN_NONE;
      message = "";
      severity = 0.0;
      active = false;
     }
  };

struct SGmAssistantResult
  {
   datetime              stamped_at;
   string                symbol;
   ulong                 session_id;
   ENUM_GM_ASSIST_STATUS status;

   // Capital Protection (read-only analysis)
   double                capital_protection_score;
   double                current_dd_pct;
   double                daily_dd_pct;
   double                weekly_dd_pct;
   double                monthly_dd_pct;
   double                risk_exposure_pct;
   double                margin_usage_pct;
   double                equity_stability;
   double                floating_exposure;
   bool                  recovery_active;
   string                recovery_status;

   // Trade Environment (H4)
   ENUM_GM_ENV_GRADE     environment_grade;
   double                environment_score;
   double                trend_quality;
   double                atr_environment;
   double                volatility_score;
   double                spread_points;
   double                market_energy;
   double                liquidity_score;
   double                news_environment;
   double                historical_similarity;
   double                confidence_score;

   // System Health
   double                system_health_score;
   double                ea_health;
   double                database_health;
   double                api_health;
   double                dashboard_health;
   double                learning_health;
   double                validation_health;
   ulong                 memory_used_mb;
   ulong                 memory_available_mb;
   int                   terminal_ping_ms;
   bool                  terminal_connected;

   // Warnings
   int                   warning_count;
   SGmAssistWarning      warnings[GM_ASSIST_WARN_MAX];
   string                warning_center;   // compact summary

   // Overall
   double                overall_health_score;
   string                supervisor_status;
   string                advisory_status;
   string                market_health;
   string                insight;
   bool                  may_execute;      // ALWAYS false
   bool                  may_modify_risk;  // ALWAYS false
   bool                  valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = "";
      session_id = 0;
      status = GM_ASSIST_STATUS_IDLE;
      capital_protection_score = 0.0;
      current_dd_pct = daily_dd_pct = weekly_dd_pct = monthly_dd_pct = 0.0;
      risk_exposure_pct = margin_usage_pct = equity_stability = floating_exposure = 0.0;
      recovery_active = false;
      recovery_status = "Idle";
      environment_grade = GM_ENV_GRADE_UNKNOWN;
      environment_score = 0.0;
      trend_quality = atr_environment = volatility_score = spread_points = 0.0;
      market_energy = liquidity_score = news_environment = 0.0;
      historical_similarity = confidence_score = 0.0;
      system_health_score = ea_health = database_health = api_health = 0.0;
      dashboard_health = learning_health = validation_health = 0.0;
      memory_used_mb = memory_available_mb = 0;
      terminal_ping_ms = 0;
      terminal_connected = false;
      warning_count = 0;
      for(int i = 0; i < GM_ASSIST_WARN_MAX; i++)
         warnings[i].Reset();
      warning_center = "None";
      overall_health_score = 0.0;
      supervisor_status = "Idle";
      advisory_status = GM_ASSIST_ADVISORY;
      market_health = "—";
      insight = "";
      may_execute = false;
      may_modify_risk = false;
      valid = false;
     }
  };

#endif // GM_SGM_ASSISTANT_RESULT_MQH
//+------------------------------------------------------------------+
