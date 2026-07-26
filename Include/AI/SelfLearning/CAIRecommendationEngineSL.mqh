//+------------------------------------------------------------------+
//|                                CAIRecommendationEngineSL.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Advisory recommendations only — never mutates strategy      |
//+------------------------------------------------------------------+
#ifndef GM_CAI_RECOMMENDATION_ENGINE_SL_MQH
#define GM_CAI_RECOMMENDATION_ENGINE_SL_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmSelfLearningResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../OrderFlow/SGmOrderFlowResult.mqh"
#include "../RecoveryIntelligence/SGmRecoveryIntelligenceResult.mqh"
#include "../PredictiveIntelligence/SGmPredictiveIntelligenceResult.mqh"
#include "../NewsIntelligence/SGmNewsIntelligenceResult.mqh"

class CGmAIRecommendationEngineSL
  {
private:
   void Push(SGmSelfLearningResult &r, const string msg)
     {
      if(r.recommendation_count >= GM_SL_REC_MAX)
         return;
      r.recommendations[r.recommendation_count++] = msg;
     }

public:
   void Analyze(const SGmAssistantResult &sup,
                const SGmOrderFlowResult &of,
                const SGmRecoveryIntelligenceResult &ri,
                const SGmPredictiveIntelligenceResult &pred,
                const SGmNewsIntelligenceResult &ni,
                SGmSelfLearningResult &r)
     {
      r.recommendation_count = 0;
      for(int i = 0; i < GM_SL_REC_MAX; i++)
         r.recommendations[i] = "";

      if(pred.valid && pred.historical_match >= 65.0)
         Push(r, "Historical Similarity Increased");
      if(ri.valid && ri.recovery_efficiency >= 65.0 && ri.recovery_health_index >= 60.0)
         Push(r, "Recovery Environment Improving");
      if(r.learning_confidence >= 70.0 && r.learning_stability >= 65.0)
         Push(r, "High Confidence Session");
      if(sup.valid && of.valid && of.momentum_energy < 40.0 && of.energy_score < 45.0)
         Push(r, "Weak Momentum Environment");
      else if(of.valid && of.institutional_activity_index >= 70.0)
         Push(r, "Strong Institutional Participation");
      if(pred.valid && (pred.dominant_scenario == GM_PRED_SCN_BREAKOUT ||
                        pred.dominant_scenario == GM_PRED_SCN_HIGH_VOL ||
                        pred.overall_probability_score >= 70.0))
         Push(r, "High Probability Expansion");
      if(ni.valid && ni.news_impact_score >= 70.0)
         Push(r, "Elevated News Environment — Observe Carefully");
      if(r.knowledge_growth >= 70.0)
         Push(r, "Knowledge Base Expanding");

      if(r.recommendation_count == 0)
         Push(r, "Continue Observation — No Dominant Advisory Signal");

      r.recommendation_center = "";
      for(int j = 0; j < r.recommendation_count; j++)
        {
         if(j > 0) r.recommendation_center += " | ";
         r.recommendation_center += r.recommendations[j];
        }
      r.recommendation_report = "ADVISORY: " + r.recommendation_center + " | " + GM_SL_ADVISORY;
     }
  };

#endif // GM_CAI_RECOMMENDATION_ENGINE_SL_MQH
//+------------------------------------------------------------------+
