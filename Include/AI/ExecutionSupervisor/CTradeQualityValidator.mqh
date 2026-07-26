//+------------------------------------------------------------------+
//|                                 CTradeQualityValidator.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CTRADE_QUALITY_VALIDATOR_MQH
#define GM_CTRADE_QUALITY_VALIDATOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmExecutionSupervisorResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../RecoveryIntelligence/SGmRecoveryIntelligenceResult.mqh"
#include "../../Analytics/SGmAnalyticsSnapshot.mqh"

class CGmTradeQualityValidator
  {
public:
   void Analyze(const SGmAssistantResult &sup,
                const SGmAnalyticsSnapshot &a,
                const SGmRecoveryIntelligenceResult &ri,
                SGmExecutionSupervisorResult &r)
     {
      r.entry_quality = GmEsClamp((sup.valid) ? (0.5 * sup.trend_quality + 0.5 * sup.confidence_score)
                                              : (0.5 * a.overall_win_rate + 40.0));
      r.execution_timing = GmEsClamp((sup.valid)
                                     ? (0.4 * sup.environment_score + 0.3 * (100.0 - MathMin(100.0, r.spread_points * 2.0)) +
                                        0.3 * r.decision_stability_score)
                                     : r.decision_stability_score);

      // BE / Partial / Trail timing heuristics from stage + float
      r.break_even_timing = 55.0;
      r.partial_close_timing = 55.0;
      r.trailing_performance = 55.0;
      if(r.lifecycle_stage == GM_ES_STAGE_BREAK_EVEN)
         r.break_even_timing = GmEsClamp(70.0 + (r.floating_profit >= 0.0 ? 10.0 : -15.0));
      if(r.lifecycle_stage == GM_ES_STAGE_PARTIAL || r.lifecycle_stage == GM_ES_STAGE_TRAILING)
        {
         r.partial_close_timing = GmEsClamp(68.0 + (r.floating_profit > 0.0 ? 12.0 : -10.0));
         r.trailing_performance = GmEsClamp(65.0 + (r.floating_profit > r.floating_loss ? 15.0 : -12.0));
        }
      if(r.lifecycle_stage == GM_ES_STAGE_IN_PROFIT)
         r.break_even_timing = GmEsClamp(62.0 + MathMin(20.0, r.floating_profit));

      r.recovery_efficiency = (ri.valid) ? GmEsClamp(ri.recovery_efficiency)
                                         : GmEsClamp(a.second_attempt_win_rate);
      r.risk_efficiency = GmEsClamp(
         0.4 * (100.0 - MathMin(100.0, a.current_risk_pct * 8.0)) +
         0.3 * MathMin(100.0, a.profit_factor * 40.0) +
         0.3 * ((sup.valid) ? (100.0 - MathMin(100.0, sup.current_dd_pct * 5.0)) : 60.0));

      // Duration score: Gold Mind H4 cycles prefer not ultra-short / not stalled forever
      double dur_score = 60.0;
      if(r.trade_duration_sec > 0.0)
        {
         if(r.trade_duration_sec < 300.0) dur_score = 45.0;
         else if(r.trade_duration_sec < 14400.0) dur_score = 78.0;
         else if(r.trade_duration_sec < 28800.0) dur_score = 65.0;
         else dur_score = 48.0;
        }

      r.trade_quality_score = GmEsClamp(
         0.18 * r.entry_quality +
         0.18 * r.execution_timing +
         0.12 * r.break_even_timing +
         0.12 * r.partial_close_timing +
         0.12 * r.trailing_performance +
         0.14 * r.recovery_efficiency +
         0.14 * r.risk_efficiency);

      r.execution_rating = GmEsClamp(
         0.4 * r.execution_health_score +
         0.3 * r.trade_quality_score +
         0.2 * r.decision_stability_score +
         0.1 * dur_score);

      r.trade_quality_grade = GmEsGradeFromScore(r.trade_quality_score);
      r.quality_report = StringFormat(
         "Grade=%s Quality=%.0f ExecRating=%.0f | Entry=%.0f Timing=%.0f BE=%.0f Partial=%.0f Trail=%.0f RecEff=%.0f RiskEff=%.0f",
         GmEsGradeName(r.trade_quality_grade), r.trade_quality_score, r.execution_rating,
         r.entry_quality, r.execution_timing, r.break_even_timing,
         r.partial_close_timing, r.trailing_performance,
         r.recovery_efficiency, r.risk_efficiency);
     }
  };

#endif // GM_CTRADE_QUALITY_VALIDATOR_MQH
//+------------------------------------------------------------------+
