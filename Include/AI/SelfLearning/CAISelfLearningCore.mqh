//+------------------------------------------------------------------+
//|                                   CAISelfLearningEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Continuous learning from completed cycles — never mutates   |
//+------------------------------------------------------------------+
#ifndef GM_CAI_SELF_LEARNING_CORE_MQH
#define GM_CAI_SELF_LEARNING_CORE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmSelfLearningResult.mqh"
#include "../Learning/SGmLearningAnalysisResult.mqh"
#include "../Memory/SGmMemoryLearningResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../../Analytics/SGmAnalyticsSnapshot.mqh"
#include "../ExecutionSupervisor/SGmExecutionSupervisorResult.mqh"

class CGmAISelfLearningCore
  {
public:
   void Analyze(const SGmAnalyticsSnapshot &a,
                const SGmLearningAnalysisResult &learn,
                const SGmMemoryLearningResult &mem,
                const SGmAssistantResult &sup,
                const SGmExecutionSupervisorResult &es,
                SGmSelfLearningResult &r)
     {
      r.sessions_studied = a.completed_sessions;
      r.winning_trades_studied = a.winning_trades;
      r.losing_trades_studied = a.losing_trades;
      r.recovery_trades_studied = a.recovery_trades;

      double base_conf = 50.0;
      if(learn.valid)
         base_conf = 0.55 * learn.confidence + 0.45 * ((learn.knowledge_entries > 0)
                     ? MathMin(100.0, learn.knowledge_entries * 4.0) : 45.0);
      if(mem.valid)
         base_conf = 0.5 * base_conf + 0.5 * mem.calibrated_confidence;

      // Session diversity bonus (wins/losses/recovery/vol regimes)
      double diversity = 40.0;
      if(a.winning_trades > 0) diversity += 10.0;
      if(a.losing_trades > 0) diversity += 8.0;
      if(a.recovery_trades > 0) diversity += 10.0;
      if(a.second_attempt_win_rate > 0.0) diversity += 8.0;
      if(sup.valid && sup.volatility_score > 60.0) diversity += 6.0;
      else if(sup.valid && sup.volatility_score < 35.0) diversity += 6.0;
      if(es.valid && (es.lifecycle_stage == GM_ES_STAGE_BREAK_EVEN ||
                      es.lifecycle_stage == GM_ES_STAGE_TRAILING ||
                      es.lifecycle_stage == GM_ES_STAGE_PARTIAL))
         diversity += 8.0;

      r.learning_confidence = GmSlClamp(0.7 * base_conf + 0.3 * diversity);

      // Growth from cumulative study volume
      const int studied = a.total_trades + a.completed_sessions;
      r.knowledge_growth = GmSlClamp(35.0 + MathMin(50.0, studied * 1.2) +
                                     ((learn.valid) ? MathMin(15.0, learn.patterns_detected * 2.0) : 0.0));

      // Stability: win-rate consistency + memory calibration
      double stab = 0.4 * a.overall_win_rate + 0.2 * a.week_win_rate + 0.2 * a.month_win_rate;
      if(mem.valid)
         stab = 0.6 * stab + 0.4 * mem.calibrated_confidence;
      if(sup.valid)
         stab = 0.85 * stab + 0.15 * (100.0 - MathMin(100.0, MathAbs(sup.current_dd_pct) * 5.0));
      r.learning_stability = GmSlClamp(stab);

      r.learning_report = StringFormat(
         "Sessions=%d Wins=%d Losses=%d Recovery=%d | Conf=%.0f Growth=%.0f Stab=%.0f | %s",
         r.sessions_studied, r.winning_trades_studied, r.losing_trades_studied,
         r.recovery_trades_studied, r.learning_confidence, r.knowledge_growth,
         r.learning_stability, GM_SL_CONTEXT);
     }
  };

#endif // GM_CAI_SELF_LEARNING_CORE_MQH
//+------------------------------------------------------------------+
