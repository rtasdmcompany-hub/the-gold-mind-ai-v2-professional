//+------------------------------------------------------------------+
//|                               CKnowledgeEvolutionEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CKNOWLEDGE_EVOLUTION_ENGINE_MQH
#define GM_CKNOWLEDGE_EVOLUTION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmSelfLearningResult.mqh"
#include "../Learning/SGmLearningAnalysisResult.mqh"
#include "../Memory/SGmMemoryLearningResult.mqh"
#include "../RecoveryIntelligence/SGmRecoveryIntelligenceResult.mqh"
#include "../OrderFlow/SGmOrderFlowResult.mqh"
#include "../PredictiveIntelligence/SGmPredictiveIntelligenceResult.mqh"
#include "../../Analytics/SGmAnalyticsSnapshot.mqh"

class CGmKnowledgeEvolutionEngine
  {
public:
   void Analyze(const SGmAnalyticsSnapshot &a,
                const SGmLearningAnalysisResult &learn,
                const SGmMemoryLearningResult &mem,
                const SGmRecoveryIntelligenceResult &ri,
                const SGmOrderFlowResult &of,
                const SGmPredictiveIntelligenceResult &pred,
                SGmSelfLearningResult &r)
     {
      int pats = 0;
      string lib = "";

      // Pattern discovery from fused intelligence layers
      string tags[GM_SL_PATTERN_MAX];
      int n = 0;
      if(a.overall_win_rate >= 55.0 && n < GM_SL_PATTERN_MAX)
         tags[n++] = "H4 Win Bias";
      if(a.second_attempt_win_rate >= 50.0 && n < GM_SL_PATTERN_MAX)
         tags[n++] = "Second Attempt Resilience";
      if(ri.valid && ri.recovery_efficiency >= 60.0 && n < GM_SL_PATTERN_MAX)
         tags[n++] = "Recovery Efficiency";
      if(of.valid && of.institutional_activity_index >= 65.0 && n < GM_SL_PATTERN_MAX)
         tags[n++] = "Institutional Participation";
      if(of.valid && of.energy_score >= 70.0 && n < GM_SL_PATTERN_MAX)
         tags[n++] = "Market Energy Expansion";
      if(pred.valid && pred.historical_match >= 60.0 && n < GM_SL_PATTERN_MAX)
         tags[n++] = "Historical Similarity";
      if(learn.valid && learn.patterns_detected > 0 && n < GM_SL_PATTERN_MAX)
         tags[n++] = "Legacy Pattern Hit";
      if(mem.valid && mem.calibrated_confidence >= 65.0 && n < GM_SL_PATTERN_MAX)
         tags[n++] = "Calibrated Memory";

      pats = n;
      for(int i = 0; i < n; i++)
        {
         if(i > 0) lib += " | ";
         lib += tags[i];
        }
      if(StringLen(lib) == 0)
         lib = "No Dominant Pattern";

      r.patterns_discovered = pats;
      r.pattern_frequency = GmSlClamp(pats * 12.5);
      r.pattern_library = lib;

      double hist_sim = (pred.valid) ? pred.historical_match
                        : ((learn.valid) ? learn.pattern_accuracy : 50.0);
      double sess_beh = (of.valid) ? of.session_strength : a.session_win_rate;
      double rec_beh = (ri.valid) ? ri.recovery_intelligence_score : a.second_attempt_win_rate;
      double env = (a.atr14 > 0.0) ? GmSlClamp(55.0 + MathMin(25.0, a.atr14 * 0.05)) : 55.0;

      r.knowledge_index = GmSlClamp(
         0.25 * r.learning_confidence +
         0.20 * r.knowledge_growth +
         0.20 * hist_sim +
         0.15 * sess_beh +
         0.10 * rec_beh +
         0.10 * env);

      r.learning_score = GmSlClamp(
         0.4 * r.learning_confidence +
         0.3 * r.learning_stability +
         0.3 * r.knowledge_index);

      r.knowledge_quality = GmSlClamp(
         0.35 * r.knowledge_index +
         0.25 * hist_sim +
         0.20 * r.pattern_frequency +
         0.20 * ((mem.valid) ? mem.calibrated_confidence : 55.0));

      r.knowledge_report = StringFormat(
         "Index=%.0f Score=%.0f Quality=%.0f | Patterns=%d Freq=%.0f | Lib=[%s]",
         r.knowledge_index, r.learning_score, r.knowledge_quality,
         r.patterns_discovered, r.pattern_frequency, r.pattern_library);

      r.historical_intelligence = StringFormat(
         "HistMatch=%.0f SessionWR=%.0f FirstWR=%.0f SecondWR=%.0f PF=%.2f | %s",
         hist_sim, a.session_win_rate, a.first_attempt_win_rate,
         a.second_attempt_win_rate, a.profit_factor, GM_SL_CONTEXT);
     }
  };

#endif // GM_CKNOWLEDGE_EVOLUTION_ENGINE_MQH
//+------------------------------------------------------------------+
