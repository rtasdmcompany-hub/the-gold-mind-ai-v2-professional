//+------------------------------------------------------------------+
//|                                CBacktestIntelligenceEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CBACKTEST_INTELLIGENCE_ENGINE_MQH
#define GM_CBACKTEST_INTELLIGENCE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmAIValidationResult.mqh"
#include "../Learning/CTradeStudyCollector.mqh"

/// @brief Historical Gold Mind methodology understanding (read-only).
class CGmBacktestIntelligenceEngine
  {
public:
   void Analyze(const string symbol, const long magic, SGmAIValidationResult &r)
     {
      SGmTradeStudyStats st;
      CGmTradeStudyCollector study;
      if(!study.Collect(symbol, magic, st))
        {
         r.backtest_status = "No history";
         r.backtest_score = 45.0;
         return;
        }

      r.h4_sessions_evaluated = st.h4_buckets;
      r.wins_observed = st.wins;
      r.losses_observed = st.losses;

      const int total = MathMax(1, st.wins + st.losses);
      const double wr = 100.0 * (double)st.wins / (double)total;

      // Proxies for Gold Mind mechanics understanding (analytical, not rule changes)
      r.first_attempt_proxy = GmAiValClamp(wr);
      r.second_attempt_proxy = GmAiValClamp(40.0 + st.second_proxy * 8.0);
      r.recovery_proxy = GmAiValClamp(40.0 + st.recovery_proxy * 8.0);
      r.be_proxy = GmAiValClamp(40.0 + st.be_proxy * 5.0);
      r.sl_model_proxy = GmAiValClamp(50.0 + (st.sl_like > 0 ? 15.0 : 0.0) -
                                      (st.losses > st.wins * 2 ? 20.0 : 0.0));

      r.backtest_score = GmAiValClamp(
         wr * 0.35 +
         r.second_attempt_proxy * 0.15 +
         r.recovery_proxy * 0.15 +
         r.be_proxy * 0.10 +
         r.sl_model_proxy * 0.10 +
         MathMin(100.0, st.h4_buckets * 3.0) * 0.15);

      r.backtest_status = StringFormat("H4=%d W/L=%d/%d score=%.0f | GM: 3B/3S ATR TP 30pip SL BE PC trail 2nd",
                                       st.h4_buckets, st.wins, st.losses, r.backtest_score);
     }
  };

#endif // GM_CBACKTEST_INTELLIGENCE_ENGINE_MQH
//+------------------------------------------------------------------+
