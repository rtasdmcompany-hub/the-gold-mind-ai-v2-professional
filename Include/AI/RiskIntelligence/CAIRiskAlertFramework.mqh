//+------------------------------------------------------------------+
//|                                      CAIRiskAlertFramework.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Alerts only — NEVER triggers trading or risk changes        |
//+------------------------------------------------------------------+
#ifndef GM_CAI_RISK_ALERT_FRAMEWORK_MQH
#define GM_CAI_RISK_ALERT_FRAMEWORK_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmRiskIntelligenceResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"

class CGmAIRiskAlertFramework
  {
private:
   void Add(SGmRiskIntelligenceResult &r, const string msg)
     {
      if(r.alert_count >= GM_RISKINT_ALERT_MAX)
         return;
      r.alerts[r.alert_count++] = msg;
     }

public:
   void Analyze(const SGmAssistantResult &sup,
                SGmRiskIntelligenceResult &r)
     {
      r.alert_count = 0;
      for(int i = 0; i < GM_RISKINT_ALERT_MAX; i++)
         r.alerts[i] = "";

      if(r.current_dd_pct >= 4.0 && r.current_dd_pct >= r.avg_dd_pct * 1.15)
         Add(r, "⚠ Increasing Drawdown Pattern");
      if(r.exposure_score < 65.0)
         Add(r, "⚠ Abnormal Exposure Growth");
      if(r.margin_grade == GM_MARGIN_GRADE_D || r.margin_grade == GM_MARGIN_GRADE_F)
         Add(r, "⚠ Margin Safety Reduction");
      if(sup.valid && sup.volatility_score >= 70.0)
         Add(r, "⚠ High Volatility Risk");
      if(r.recovery_requirement == "Observed" || r.recovery_requirement == "Monitor")
         Add(r, "⚠ Recovery Pressure Increase");
      if(r.dd_range_status == "Above Typical Historical Range" ||
         r.risk_probability >= 55.0)
         Add(r, "⚠ Historical Risk Match Detected");

      if(r.alert_count <= 0)
         r.alert_summary = "None";
      else
        {
         r.alert_summary = r.alerts[0];
         for(int j = 1; j < r.alert_count && j < 3; j++)
            r.alert_summary += " | " + r.alerts[j];
         if(r.alert_count > 3)
            r.alert_summary += StringFormat(" (+%d)", r.alert_count - 3);
        }

      // Trend + recovery pressure labels for dashboard
      if(r.risk_probability < 20.0 && r.capital_protection_score >= 80.0)
         r.risk_trend = "Stable / Improving";
      else if(r.risk_probability < 40.0)
         r.risk_trend = "Stable";
      else if(r.risk_probability < 65.0)
         r.risk_trend = "Deteriorating";
      else
         r.risk_trend = "Elevated Risk Trend";

      r.recovery_pressure = r.recovery_requirement;
      if(r.recovery_pressure == "None")
         r.recovery_pressure = "None";
      else if(r.recovery_pressure == "Monitor")
         r.recovery_pressure = "Rising";
      else
         r.recovery_pressure = "Active Observation";

      r.risk_explanation = StringFormat(
                              "Capital=%s (%.0f) | PredRisk=%.0f%% (%s) | Exposure=%.0f | Margin=%s | DD=%s | Alerts=%s | %s",
                              GmCapStatusName(r.capital_status),
                              r.capital_protection_score,
                              r.risk_probability,
                              GmRiskLevelName(r.risk_level),
                              r.exposure_score,
                              GmMarginGradeName(r.margin_grade),
                              r.dd_range_status,
                              r.alert_summary,
                              GM_RISKINT_ADVISORY);
     }
  };

#endif // GM_CAI_RISK_ALERT_FRAMEWORK_MQH
//+------------------------------------------------------------------+
