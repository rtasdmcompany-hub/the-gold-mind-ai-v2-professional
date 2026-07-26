//+------------------------------------------------------------------+
//|                           CEnterpriseOptimizationAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CENTERPRISE_OPTIMIZATION_ANALYZER_MQH
#define GM_CENTERPRISE_OPTIMIZATION_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmSelfLearningResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../ExecutionSupervisor/SGmExecutionSupervisorResult.mqh"
#include "../../Analytics/SGmAnalyticsSnapshot.mqh"

class CGmEnterpriseOptimizationAnalyzer
  {
public:
   void Analyze(const SGmAnalyticsSnapshot &a,
                const SGmAssistantResult &sup,
                const SGmExecutionSupervisorResult &es,
                SGmSelfLearningResult &r)
     {
      // Analysis speed from analytics collect time (us)
      double speed = 75.0;
      if(a.last_collect_us > 0)
        {
         if(a.last_collect_us < 1500) speed = 92.0;
         else if(a.last_collect_us < 4000) speed = 82.0;
         else if(a.last_collect_us < 10000) speed = 68.0;
         else speed = 50.0;
        }
      r.analysis_speed_score = speed;

      // Memory efficiency from assistant health
      r.memory_efficiency = 70.0;
      if(sup.valid)
        {
         if(sup.memory_available_mb > 0)
           {
            const double used_pct = 100.0 * (double)sup.memory_used_mb /
                                    (double)(sup.memory_used_mb + MathMax((ulong)1, sup.memory_available_mb));
            r.memory_efficiency = GmSlClamp(100.0 - used_pct * 0.7);
           }
         else
            r.memory_efficiency = GmSlClamp(0.5 * sup.system_health_score + 0.5 * 70.0);
        }

      r.dashboard_performance = (sup.valid) ? GmSlClamp(sup.dashboard_health) : 70.0;
      if(es.valid)
         r.dashboard_performance = GmSlClamp(0.6 * r.dashboard_performance +
                                             0.4 * es.execution_health_score);

      // Knowledge processing proxy
      const double knowledge_proc = GmSlClamp(0.5 * r.knowledge_index + 0.5 * r.learning_score);

      r.optimization_score = GmSlClamp(
         0.25 * r.analysis_speed_score +
         0.20 * r.memory_efficiency +
         0.20 * r.dashboard_performance +
         0.20 * knowledge_proc +
         0.15 * ((sup.valid) ? sup.database_health : 70.0));

      r.system_efficiency_rating = GmSlClamp(
         0.4 * r.optimization_score +
         0.3 * ((sup.valid) ? sup.overall_health_score : 65.0) +
         0.3 * r.analysis_speed_score);

      r.optimization_report = StringFormat(
         "Opt=%.0f Eff=%.0f | Speed=%.0f Mem=%.0f Dash=%.0f CollectUs=%I64u | NO auto strategy optimize",
         r.optimization_score, r.system_efficiency_rating,
         r.analysis_speed_score, r.memory_efficiency, r.dashboard_performance,
         a.last_collect_us);
     }
  };

#endif // GM_CENTERPRISE_OPTIMIZATION_ANALYZER_MQH
//+------------------------------------------------------------------+
