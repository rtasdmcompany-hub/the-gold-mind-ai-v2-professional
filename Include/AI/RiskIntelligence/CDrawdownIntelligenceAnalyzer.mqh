//+------------------------------------------------------------------+
//|                               CDrawdownIntelligenceAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CDRAWDOWN_INTELLIGENCE_ANALYZER_MQH
#define GM_CDRAWDOWN_INTELLIGENCE_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmRiskIntelligenceResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../../Analytics/SGmAnalyticsSnapshot.mqh"

class CGmDrawdownIntelligenceAnalyzer
  {
public:
   void Analyze(const SGmAssistantResult &sup,
                const SGmAnalyticsSnapshot &an,
                SGmRiskIntelligenceResult &r)
     {
      r.current_dd_pct = MathMax(sup.valid ? MathMax(sup.current_dd_pct, MathMax(sup.daily_dd_pct, 0.0)) : 0.0,
                                 an.valid ? an.current_dd_pct : 0.0);
      r.max_dd_pct = MathMax(an.valid ? an.maximum_dd_pct : 0.0,
                             MathMax(r.current_dd_pct, sup.valid ? MathMax(sup.weekly_dd_pct, sup.monthly_dd_pct) : 0.0));
      r.avg_dd_pct = 0.5 * r.current_dd_pct + 0.3 * (sup.valid ? MathMax(sup.weekly_dd_pct, 0.0) : 0.0)
                     + 0.2 * (sup.valid ? MathMax(sup.monthly_dd_pct, 0.0) : 0.0);

      if(r.max_dd_pct <= 0.01)
         r.max_dd_pct = MathMax(r.current_dd_pct, 1.0);

      if(r.current_dd_pct <= r.max_dd_pct * 0.85 + 0.5)
         r.dd_range_status = "Within Historical Range";
      else
         r.dd_range_status = "Above Typical Historical Range";

      const bool recovering = (sup.valid && (sup.recovery_active ||
                               StringFind(sup.recovery_status, "Recovery") >= 0));
      if(r.current_dd_pct < 3.0 && !recovering)
         r.recovery_probability = "High";
      else if(r.current_dd_pct < 7.0)
         r.recovery_probability = "Moderate";
      else
         r.recovery_probability = "Lower — monitor closely";

      r.historical_comparison = StringFormat("Cur=%.1f%% Avg=%.1f%% Max=%.1f%% | %s",
                                             r.current_dd_pct, r.avg_dd_pct, r.max_dd_pct,
                                             r.dd_range_status);

      r.drawdown_report = StringFormat(
                             "Drawdown Intelligence Report:\r\nCurrent Drawdown:\r\n%s\r\n\r\nRecovery Probability:\r\n%s\r\n\r\nCur=%.1f%% Avg=%.1f%% Max=%.1f%%\r\n%s\r\n",
                             r.dd_range_status,
                             r.recovery_probability,
                             r.current_dd_pct,
                             r.avg_dd_pct,
                             r.max_dd_pct,
                             GM_RISKINT_ANALYSIS_ONLY);
     }
  };

#endif // GM_CDRAWDOWN_INTELLIGENCE_ANALYZER_MQH
//+------------------------------------------------------------------+
