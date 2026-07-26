//+------------------------------------------------------------------+
//|                                    SGmRiskIntelligenceResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_RISK_INTELLIGENCE_RESULT_MQH
#define GM_SGM_RISK_INTELLIGENCE_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "RiskIntelligenceConstants.mqh"

struct SGmRiskIntelligenceResult
  {
   datetime                 stamped_at;
   string                   symbol;
   ulong                    session_id;
   string                   account_id;
   ENUM_GM_RISKINT_STATUS   status;

   // Capital protection
   double                   capital_protection_score;
   ENUM_GM_CAP_STATUS       capital_status;
   string                   equity_stability;
   string                   risk_pressure;
   string                   recovery_requirement;
   string                   capital_report;

   // Predictive risk
   double                   risk_probability;
   ENUM_GM_RISK_LEVEL       risk_level;
   string                   predictive_reason;
   string                   predictive_report;

   // Exposure
   double                   exposure_score;
   string                   exposure_status;
   string                   exposure_report;

   // Drawdown intelligence
   double                   current_dd_pct;
   double                   max_dd_pct;
   double                   avg_dd_pct;
   string                   dd_range_status;
   string                   recovery_probability;
   string                   drawdown_report;

   // Margin safety
   ENUM_GM_MARGIN_GRADE     margin_grade;
   double                   margin_level;
   double                   free_margin;
   string                   margin_report;

   // Trends / alerts / explanation
   string                   risk_trend;
   string                   recovery_pressure;
   string                   historical_comparison;
   string                   risk_explanation;
   int                      alert_count;
   string                   alerts[GM_RISKINT_ALERT_MAX];
   string                   alert_summary;

   double                   confidence;
   string                   center_status;
   string                   advisory_status;
   string                   insight;
   bool                     may_execute;
   bool                     may_modify_risk;
   bool                     from_cache;
   bool                     valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = account_id = "";
      session_id = 0;
      status = GM_RISKINT_STATUS_IDLE;
      capital_protection_score = 0.0;
      capital_status = GM_CAP_STATUS_UNKNOWN;
      equity_stability = risk_pressure = recovery_requirement = capital_report = "";
      risk_probability = 0.0;
      risk_level = GM_RISK_LEVEL_UNKNOWN;
      predictive_reason = predictive_report = "";
      exposure_score = 0.0;
      exposure_status = exposure_report = "";
      current_dd_pct = max_dd_pct = avg_dd_pct = 0.0;
      dd_range_status = recovery_probability = drawdown_report = "";
      margin_grade = GM_MARGIN_GRADE_UNKNOWN;
      margin_level = free_margin = 0.0;
      margin_report = "";
      risk_trend = recovery_pressure = historical_comparison = risk_explanation = "";
      alert_count = 0;
      for(int i = 0; i < GM_RISKINT_ALERT_MAX; i++)
         alerts[i] = "";
      alert_summary = "None";
      confidence = 0.0;
      center_status = "Idle";
      advisory_status = GM_RISKINT_ADVISORY;
      insight = "";
      may_execute = false;
      may_modify_risk = false;
      from_cache = false;
      valid = false;
     }
  };

#endif // GM_SGM_RISK_INTELLIGENCE_RESULT_MQH
//+------------------------------------------------------------------+
