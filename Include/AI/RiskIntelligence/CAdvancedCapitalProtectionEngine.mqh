//+------------------------------------------------------------------+
//|                          CAdvancedCapitalProtectionEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CADVANCED_CAPITAL_PROTECTION_ENGINE_MQH
#define GM_CADVANCED_CAPITAL_PROTECTION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmRiskIntelligenceResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../../Analytics/SGmAnalyticsSnapshot.mqh"

class CGmAdvancedCapitalProtectionEngine
  {
public:
   void Analyze(const SGmAssistantResult &sup,
                const SGmAnalyticsSnapshot &an,
                SGmRiskIntelligenceResult &r)
     {
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      if(an.valid && an.equity > 0.0)
         equity = an.equity;

      const double dd = MathMax(sup.valid ? MathMax(sup.current_dd_pct, MathMax(sup.daily_dd_pct, 0.0)) : 0.0,
                                an.valid ? an.current_dd_pct : 0.0);
      const double weekly = (sup.valid ? MathMax(sup.weekly_dd_pct, 0.0) : 0.0);
      const double monthly = (sup.valid ? MathMax(sup.monthly_dd_pct, 0.0) : 0.0);
      const double floating = (sup.valid ? MathAbs(sup.floating_exposure)
                              : (an.valid ? MathAbs(an.floating_loss) + MathAbs(an.floating_profit) : 0.0));
      const double margin_use = (sup.valid ? sup.margin_usage_pct : 0.0);
      const double base_cap = (sup.valid ? sup.capital_protection_score : 75.0);

      double score = base_cap;
      score -= dd * 2.2;
      score -= weekly * 1.1;
      score -= monthly * 0.6;
      score -= margin_use * 0.15;
      if(balance > 0.0)
        {
         const double drift = 100.0 * MathAbs(equity - balance) / balance;
         score -= MathMin(12.0, drift * 0.4);
        }
      if(sup.valid && sup.recovery_active)
         score -= 8.0;
      r.capital_protection_score = GmRiskIntClamp(score);

      if(r.capital_protection_score >= 88.0)
         r.capital_status = GM_CAP_STATUS_EXCELLENT;
      else if(r.capital_protection_score >= 75.0)
         r.capital_status = GM_CAP_STATUS_GOOD;
      else if(r.capital_protection_score >= 60.0)
         r.capital_status = GM_CAP_STATUS_FAIR;
      else if(r.capital_protection_score >= 45.0)
         r.capital_status = GM_CAP_STATUS_PRESSURE;
      else
         r.capital_status = GM_CAP_STATUS_STRESSED;

      if(dd < 2.0 && MathAbs(equity - balance) < balance * 0.02)
         r.equity_stability = "High";
      else if(dd < 5.0)
         r.equity_stability = "Moderate";
      else
         r.equity_stability = "Low";

      if(dd < 3.0 && margin_use < 40.0 && !(sup.valid && sup.recovery_active))
         r.risk_pressure = "Low";
      else if(dd < 7.0)
         r.risk_pressure = "Moderate";
      else
         r.risk_pressure = "Elevated";

      if(sup.valid && (sup.recovery_active || StringFind(sup.recovery_status, "Recovery") >= 0))
         r.recovery_requirement = "Observed";
      else if(dd >= 8.0)
         r.recovery_requirement = "Monitor";
      else
         r.recovery_requirement = "None";

      r.capital_report = StringFormat(
                            "Capital Protection Status:\r\n%s\r\n\r\nEquity Stability:\r\n%s\r\n\r\nRisk Pressure:\r\n%s\r\n\r\nRecovery Requirement:\r\n%s\r\n\r\nScore=%.0f | DD=%.1f%% | Float=%.2f | MarginUse=%.0f%%\r\n%s\r\n",
                            GmCapStatusName(r.capital_status),
                            r.equity_stability,
                            r.risk_pressure,
                            r.recovery_requirement,
                            r.capital_protection_score,
                            dd,
                            floating,
                            margin_use,
                            GM_RISKINT_ANALYSIS_ONLY);
     }
  };

#endif // GM_CADVANCED_CAPITAL_PROTECTION_ENGINE_MQH
//+------------------------------------------------------------------+
