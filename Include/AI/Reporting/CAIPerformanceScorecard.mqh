//+------------------------------------------------------------------+
//|                                   CAIPerformanceScorecard.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_PERFORMANCE_SCORECARD_MQH
#define GM_CAI_PERFORMANCE_SCORECARD_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmReportingResult.mqh"
#include "../Intelligence/SGmIntelligenceResult.mqh"
#include "../Memory/SGmMemoryLearningResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../Learning/SGmLearningAnalysisResult.mqh"

class CGmAIPerformanceScorecard
  {
public:
   void Analyze(const SGmIntelligenceResult &intel,
                const SGmMemoryLearningResult &mem,
                const SGmAssistantResult &sup,
                const SGmLearningAnalysisResult &learn,
                SGmReportingResult &r)
     {
      r.prediction_accuracy = learn.valid ? GmRptClamp(learn.prediction_accuracy)
                                          : (intel.valid ? GmRptClamp(intel.ai_confidence * 0.9) : 55.0);
      r.pattern_accuracy = learn.valid ? GmRptClamp(learn.pattern_accuracy)
                                       : (mem.valid && mem.top_pattern.active
                                          ? mem.top_pattern.success_rate : 60.0);
      r.confidence_accuracy = learn.valid ? GmRptClamp(learn.confidence_accuracy)
                                          : (mem.valid ? GmRptClamp(mem.learning_accuracy) : 60.0);
      r.learning_improvement = mem.valid
                               ? GmRptClamp(50.0 + mem.analysis_improvement_pct * 2.0)
                               : 55.0;

      // Warning accuracy: fewer false warnings => higher
      double warn_acc = 80.0;
      if(mem.valid)
         warn_acc = GmRptClamp(100.0 - mem.false_warning_rate);
      else if(sup.valid && sup.warning_count >= 4)
         warn_acc = 62.0;
      r.warning_accuracy = warn_acc;

      r.report_quality = GmRptClamp(
                            0.25 * r.prediction_accuracy +
                            0.20 * r.warning_accuracy +
                            0.20 * r.pattern_accuracy +
                            0.20 * r.confidence_accuracy +
                            0.15 * r.learning_improvement);

      r.performance_score = GmRptClamp(
                               0.22 * r.prediction_accuracy +
                               0.18 * r.warning_accuracy +
                               0.18 * r.pattern_accuracy +
                               0.18 * r.confidence_accuracy +
                               0.12 * r.learning_improvement +
                               0.12 * r.report_quality);

      r.performance_grade = GmRptGradeFromScore(r.performance_score);
     }
  };

#endif // GM_CAI_PERFORMANCE_SCORECARD_MQH
//+------------------------------------------------------------------+
