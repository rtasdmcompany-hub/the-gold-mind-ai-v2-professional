//+------------------------------------------------------------------+
//|                                CEnterpriseAnalyticsEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Long-term observational analytics — NEVER mutates Core      |
//+------------------------------------------------------------------+
#ifndef GM_CENTERPRISE_ANALYTICS_ENGINE_MQH
#define GM_CENTERPRISE_ANALYTICS_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmReportingResult.mqh"
#include "../Intelligence/SGmIntelligenceResult.mqh"
#include "../Memory/SGmMemoryLearningResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../../Analytics/CAnalyticsEngine.mqh"

class CGmEnterpriseAnalyticsEngine
  {
public:
   void Analyze(CGmAnalyticsEngine *analytics,
                const SGmIntelligenceResult &intel,
                const SGmMemoryLearningResult &mem,
                const SGmAssistantResult &sup,
                const SGmReportingResult &scorecard,
                SGmReportingResult &r)
     {
      double monthly = intel.valid ? intel.market_score : 60.0;
      double quarterly = monthly;
      double yearly = monthly;
      if(analytics != NULL)
        {
         const SGmAnalyticsSnapshot a = analytics.Snapshot();
         monthly = GmRptClamp(0.5 * monthly + 0.5 * a.session_win_rate);
         quarterly = GmRptClamp(0.6 * monthly + 0.4 * GmRptClamp(100.0 - a.maximum_dd_pct * 5.0));
         yearly = GmRptClamp(0.55 * quarterly + 0.45 * (a.profit_factor > 0.0
                              ? GmRptClamp(40.0 + a.profit_factor * 20.0) : 55.0));
        }

      r.monthly_intelligence = StringFormat("MonthlyIntel=%.0f | Strat=%.0f | DD_m=%.1f",
                                            monthly,
                                            intel.valid ? intel.strategy_performance_score : 0.0,
                                            sup.valid ? sup.monthly_dd_pct : 0.0);

      r.risk_evolution = StringFormat("Risk=%s | Cap=%.0f | Exp=%.1f | Trend=%s",
                                      r.risk_level_label,
                                      sup.valid ? sup.capital_protection_score : 0.0,
                                      sup.valid ? sup.risk_exposure_pct : 0.0,
                                      (sup.valid && MathMax(sup.current_dd_pct, sup.daily_dd_pct) >= 5.0)
                                      ? "Elevating" : "Stable");

      r.accuracy_trend = StringFormat("Pred=%.0f Warn=%.0f Pat=%.0f ConfAcc=%.0f Score=%.0f/%s",
                                      scorecard.prediction_accuracy,
                                      scorecard.warning_accuracy,
                                      scorecard.pattern_accuracy,
                                      scorecard.confidence_accuracy,
                                      scorecard.performance_score,
                                      GmRptGradeName(scorecard.performance_grade));

      r.learning_growth = StringFormat("Know=%.0f Improve=%.0f Acc=%.0f Sessions=%d",
                                       mem.valid ? mem.knowledge_growth : 0.0,
                                       mem.valid ? mem.improvement_score : 0.0,
                                       mem.valid ? mem.learning_accuracy : 0.0,
                                       mem.valid ? mem.total_analyzed_sessions : 0);

      r.enterprise_analytics = StringFormat(
                                  "=== ENTERPRISE INTELLIGENCE ANALYTICS ===\r\nMonthly=%.0f Quarterly=%.0f Yearly=%.0f\r\n%s\r\n%s\r\n%s\r\n%s\r\n%s\r\n",
                                  monthly, quarterly, yearly,
                                  r.monthly_intelligence,
                                  r.risk_evolution,
                                  r.accuracy_trend,
                                  r.learning_growth,
                                  GM_RPT_ADVISORY);
     }
  };

#endif // GM_CENTERPRISE_ANALYTICS_ENGINE_MQH
//+------------------------------------------------------------------+
