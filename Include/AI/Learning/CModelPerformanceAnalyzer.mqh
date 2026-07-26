//+------------------------------------------------------------------+
//|                                CModelPerformanceAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CMODEL_PERFORMANCE_ANALYZER_MQH
#define GM_CMODEL_PERFORMANCE_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmLearningAnalysisResult.mqh"

class CGmModelPerformanceAnalyzer
  {
public:
   void Analyze(SGmLearningAnalysisResult &r)
     {
      r.knowledge_score = GmLearnClamp(
         r.pattern_accuracy * 0.25 +
         r.prediction_accuracy * 0.25 +
         r.confidence_accuracy * 0.20 +
         r.recommendation_accuracy * 0.15 +
         r.learning_progress * 0.15);

      // Experience from cycles + knowledge size + accuracy
      const double xp = r.learning_cycles * 8.0 +
                        r.knowledge_entries * 0.5 +
                        r.knowledge_score * 0.3;
      if(xp >= 90.0)
         r.experience = GM_LEARN_XP_MASTER;
      else if(xp >= 70.0)
         r.experience = GM_LEARN_XP_EXPERT;
      else if(xp >= 50.0)
         r.experience = GM_LEARN_XP_PROFICIENT;
      else if(xp >= 30.0)
         r.experience = GM_LEARN_XP_COMPETENT;
      else if(xp >= 12.0)
         r.experience = GM_LEARN_XP_APPRENTICE;
      else
         r.experience = GM_LEARN_XP_NOVICE;

      r.confidence = GmLearnClamp(
         40.0 + r.knowledge_score * 0.35 + r.prediction_accuracy * 0.25);
     }
  };

#endif // GM_CMODEL_PERFORMANCE_ANALYZER_MQH
//+------------------------------------------------------------------+
