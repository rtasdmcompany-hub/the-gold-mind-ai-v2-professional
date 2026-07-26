//+------------------------------------------------------------------+
//|                                   CSecondAttemptAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CSECOND_ATTEMPT_ANALYZER_MQH
#define GM_CSECOND_ATTEMPT_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmRecoveryIntelligenceResult.mqh"
#include "../../Analytics/SGmAnalyticsSnapshot.mqh"

class CGmSecondAttemptAnalyzer
  {
public:
   void Analyze(const SGmAnalyticsSnapshot &a,
                const SGmRecoveryIntelligenceResult &partial,
                SGmRecoveryIntelligenceResult &r)
     {
      r.first_sl_rate = GmRiClamp(100.0 - a.first_attempt_win_rate);
      r.second_attempt_rate = GmRiClamp(
                                 (a.losing_trades > 0)
                                 ? MathMin(100.0, (double)a.losing_trades /
                                           MathMax(1.0, (double)a.total_trades) * 100.0)
                                 : (a.second_attempt_win_rate > 0.0 ? 40.0 : 15.0));
      r.second_attempt_success = GmRiClamp(a.second_attempt_win_rate);
      r.final_failure_rate = GmRiClamp(
                                100.0 - r.second_attempt_success * 0.7 -
                                a.first_attempt_win_rate * 0.3);
      r.historical_recovery_pct = GmRiClamp(
                                     0.50 * r.second_attempt_success +
                                     0.30 * partial.recovery_success_rate +
                                     0.20 * GmRiClamp(a.recovery_factor * 30.0));
      r.recovery_time_sec = (a.avg_loss_duration_sec > 0.0)
                            ? a.avg_loss_duration_sec
                            : partial.recovery_duration;

      r.recovery_conditions = StringFormat(
                                 "FirstAttemptWR=%.0f%% SecondAttemptWR=%.0f%% Losing=%d Total=%d | %s",
                                 a.first_attempt_win_rate, a.second_attempt_win_rate,
                                 a.losing_trades, a.total_trades, GM_RI_GOLDMIND_CONTEXT);

      r.second_attempt_report = StringFormat(
                                   "Second Attempt Analyzer:\r\nFirstSL=%.0f%% SecondRate=%.0f%% SecondSuccess=%.0f%%\r\nFinalFail=%.0f%% HistRecovery=%.0f%% Time=%.0fs\r\n%s\r\n%s\r\n",
                                   r.first_sl_rate, r.second_attempt_rate,
                                   r.second_attempt_success, r.final_failure_rate,
                                   r.historical_recovery_pct, r.recovery_time_sec,
                                   r.recovery_conditions, GM_RI_ADVISORY);
     }
  };

#endif // GM_CSECOND_ATTEMPT_ANALYZER_MQH
//+------------------------------------------------------------------+
