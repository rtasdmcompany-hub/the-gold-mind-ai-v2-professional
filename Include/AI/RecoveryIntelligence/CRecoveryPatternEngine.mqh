//+------------------------------------------------------------------+
//|                                    CRecoveryPatternEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CRECOVERY_PATTERN_ENGINE_MQH
#define GM_CRECOVERY_PATTERN_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmRecoveryIntelligenceResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../NewsIntelligence/SGmNewsIntelligenceResult.mqh"
#include "../Trend/TrendAIConstants.mqh"

class CGmRecoveryPatternEngine
  {
public:
   void Analyze(const SGmTrendAnalysisResult &trend,
                const SGmVolatilityAnalysisResult &vol,
                const SGmNewsIntelligenceResult &ni,
                const SGmRecoveryIntelligenceResult &partial,
                SGmRecoveryIntelligenceResult &r)
     {
      const bool news_env = (ni.valid && ni.impact_class >= GM_NI_IMPACT_MEDIUM);
      const bool trend_env = (trend.valid && trend.strength_score >= 55.0 &&
                              trend.primary != GM_TREND_DIR_FLAT);
      const bool range_env = (trend.valid &&
                              (trend.primary == GM_TREND_DIR_FLAT ||
                               trend.strength_score < 40.0));
      const bool high_vol = (vol.valid && (vol.atr_expansion || vol.energy_score >= 70.0));

      if(partial.recovery_success_rate >= 70.0 && partial.loss_control_score >= 65.0 &&
         !high_vol)
         r.primary_pattern = GM_RI_PAT_BEST;
      else if(partial.recovery_health_index < 40.0 || partial.final_failure_rate >= 55.0)
         r.primary_pattern = GM_RI_PAT_WORST;
      else if(news_env)
         r.primary_pattern = GM_RI_PAT_NEWS;
      else if(trend_env && partial.recovery_success_rate >= 60.0)
         r.primary_pattern = GM_RI_PAT_TREND;
      else if(range_env)
         r.primary_pattern = GM_RI_PAT_RANGE;
      else if(partial.recovery_success_rate >= 65.0)
         r.primary_pattern = GM_RI_PAT_HIGH_SUCCESS;
      else if(partial.recovery_success_rate < 45.0 || high_vol)
         r.primary_pattern = GM_RI_PAT_WEAK;
      else
         r.primary_pattern = GM_RI_PAT_HIGH_SUCCESS;

      r.pattern_library = StringFormat(
                             "Library: Best|Worst|HighSuccess|Weak|News|Trend|Range\r\nActive=%s\r\nNewsEnv=%s TrendEnv=%s RangeEnv=%s HighVol=%s\r\nSuccess=%.0f Health=%.0f LossCtrl=%.0f",
                             GmRiPatternName(r.primary_pattern),
                             (news_env ? "Y" : "N"), (trend_env ? "Y" : "N"),
                             (range_env ? "Y" : "N"), (high_vol ? "Y" : "N"),
                             partial.recovery_success_rate, partial.recovery_health_index,
                             partial.loss_control_score);

      r.pattern_report = StringFormat(
                            "Recovery Pattern Engine:\r\n%s\r\n%s\r\n%s\r\n",
                            GmRiPatternName(r.primary_pattern),
                            r.pattern_library, GM_RI_ANALYSIS_ONLY);
     }
  };

#endif // GM_CRECOVERY_PATTERN_ENGINE_MQH
//+------------------------------------------------------------------+
