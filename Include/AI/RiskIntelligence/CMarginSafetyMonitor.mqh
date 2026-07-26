//+------------------------------------------------------------------+
//|                                       CMarginSafetyMonitor.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CMARGIN_SAFETY_MONITOR_MQH
#define GM_CMARGIN_SAFETY_MONITOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmRiskIntelligenceResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"

class CGmMarginSafetyMonitor
  {
public:
   void Analyze(const SGmAssistantResult &sup,
                SGmRiskIntelligenceResult &r)
     {
      r.margin_level = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
      r.free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      const double margin_use = (sup.valid ? MathMax(sup.margin_usage_pct, 0.0) : 0.0);
      const double equity = AccountInfoDouble(ACCOUNT_EQUITY);

      // Prefer broker margin level when positions exist; else infer from usage
      double safety = 100.0;
      if(r.margin_level > 0.0)
        {
         if(r.margin_level >= 800.0) safety = 98.0;
         else if(r.margin_level >= 400.0) safety = 90.0;
         else if(r.margin_level >= 250.0) safety = 78.0;
         else if(r.margin_level >= 150.0) safety = 60.0;
         else if(r.margin_level >= 100.0) safety = 40.0;
         else safety = 20.0;
        }
      else
         safety = GmRiskIntClamp(100.0 - margin_use);

      if(equity > 0.0 && r.free_margin >= 0.0)
         safety = 0.7 * safety + 0.3 * GmRiskIntClamp(100.0 * r.free_margin / equity);

      if(safety >= 90.0)
         r.margin_grade = GM_MARGIN_GRADE_A;
      else if(safety >= 78.0)
         r.margin_grade = GM_MARGIN_GRADE_B;
      else if(safety >= 60.0)
         r.margin_grade = GM_MARGIN_GRADE_C;
      else if(safety >= 40.0)
         r.margin_grade = GM_MARGIN_GRADE_D;
      else
         r.margin_grade = GM_MARGIN_GRADE_F;

      r.margin_report = StringFormat(
                           "Margin Safety Grade:\r\n%s\r\n\r\nMarginLevel=%.0f | FreeMargin=%.2f | Usage=%.0f%% | Equity=%.2f\r\n%s\r\n",
                           GmMarginGradeName(r.margin_grade),
                           r.margin_level,
                           r.free_margin,
                           margin_use,
                           equity,
                           GM_RISKINT_ADVISORY);
     }
  };

#endif // GM_CMARGIN_SAFETY_MONITOR_MQH
//+------------------------------------------------------------------+
