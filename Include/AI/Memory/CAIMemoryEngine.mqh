//+------------------------------------------------------------------+
//|                                          CAIMemoryEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Stores organized historical knowledge — NO strategy change  |
//+------------------------------------------------------------------+
#ifndef GM_CAI_MEMORY_ENGINE_MQH
#define GM_CAI_MEMORY_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMemoryLearningResult.mqh"
#include "../Intelligence/SGmIntelligenceResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../Learning/SGmLearningAnalysisResult.mqh"
#include "../../Analytics/CAnalyticsEngine.mqh"

class CGmAIMemoryEngine
  {
private:
   int    m_sessions;
   int    m_patterns;
   int    m_recovery;
   double m_conf_improve_accum;
   int    m_cycles;

public:
                     CGmAIMemoryEngine(void)
                       : m_sessions(0), m_patterns(0), m_recovery(0),
                         m_conf_improve_accum(0.0), m_cycles(0) {}

   void Analyze(CGmAnalyticsEngine *analytics,
                const SGmIntelligenceResult &intel,
                const SGmAssistantResult &sup,
                const SGmLearningAnalysisResult &learn,
                SGmMemoryLearningResult &r)
     {
      m_cycles++;

      int sessions = 0;
      if(analytics != NULL)
         sessions = analytics.Snapshot().completed_sessions;
      if(learn.valid && learn.h4_sessions_studied > sessions)
         sessions = learn.h4_sessions_studied;
      if(sessions > m_sessions)
         m_sessions = sessions;
      else if(m_sessions == 0)
         m_sessions = MathMax(1, m_cycles);

      // Soft growth of stored pattern counters (observational memory)
      if(intel.valid)
        {
         m_patterns += 1 + (intel.historical_similarity >= 70.0 ? 1 : 0);
         if(intel.market_condition == GM_MKT_COND_HIGH_VOL ||
            intel.market_condition == GM_MKT_COND_BREAKOUT)
            m_patterns++;
        }
      if(sup.valid && (sup.recovery_active || StringFind(sup.recovery_status, "Recovery") >= 0))
         m_recovery++;
      if(learn.valid && learn.patterns_detected > 0)
         m_patterns = MathMax(m_patterns, learn.patterns_detected + m_cycles / 3);

      // Confidence improvement proxy vs learning progress
      double improve = 0.0;
      if(learn.valid)
         improve = GmMemClamp(learn.learning_progress_pct * 0.25);
      if(intel.valid && intel.ai_confidence >= 70.0)
         improve += 1.5;
      m_conf_improve_accum = 0.85 * m_conf_improve_accum + 0.15 * improve;

      r.total_analyzed_sessions = m_sessions;
      r.market_patterns_stored = m_patterns;
      r.recovery_patterns = m_recovery;
      r.confidence_improvement_pct = GmMemClamp(m_conf_improve_accum);

      r.memory_profile = StringFormat(
                            "Sessions=%d | Patterns=%d | Recovery=%d | ConfImprove=+%.0f%%",
                            r.total_analyzed_sessions,
                            r.market_patterns_stored,
                            r.recovery_patterns,
                            r.confidence_improvement_pct);
     }
  };

#endif // GM_CAI_MEMORY_ENGINE_MQH
//+------------------------------------------------------------------+
