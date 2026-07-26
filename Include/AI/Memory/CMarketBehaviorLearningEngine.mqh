//+------------------------------------------------------------------+
//|                             CMarketBehaviorLearningEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CMARKET_BEHAVIOR_LEARNING_ENGINE_MQH
#define GM_CMARKET_BEHAVIOR_LEARNING_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMemoryLearningResult.mqh"
#include "../Intelligence/SGmIntelligenceResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../News/SGmNewsAnalysisResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"

class CGmMarketBehaviorLearningEngine
  {
public:
   void Analyze(const SGmIntelligenceResult &intel,
                const SGmAssistantResult &sup,
                const SGmNewsAnalysisResult &news,
                const SGmTrendAnalysisResult &trend,
                const SGmVolatilityAnalysisResult &vol,
                SGmMemoryLearningResult &r)
     {
      ENUM_GM_BEHAVIOR_TYPE beh = GM_BEH_UNKNOWN;
      double match = 55.0;

      const bool high_vol = (intel.valid && intel.market_condition == GM_MKT_COND_HIGH_VOL) ||
                            (vol.valid && vol.energy_score >= 80.0);
      const bool recovery = (sup.valid && (sup.recovery_active ||
                             StringFind(sup.recovery_status, "Recovery") >= 0));
      const bool news_hot = (news.valid && news.news_risk_score >= 65.0);
      const bool low_liq = (intel.valid && intel.liquidity_condition < 45.0);
      const bool trending = (intel.valid &&
                             (intel.market_condition == GM_MKT_COND_TRENDING ||
                              intel.market_condition == GM_MKT_COND_STRONG_TREND)) ||
                            (trend.valid && trend.strength_score >= 65.0);
      const bool sideways = (intel.valid && intel.market_condition == GM_MKT_COND_RANGING) ||
                            (trend.valid && trend.strength_score < 35.0);
      const bool fake_bo = (vol.valid && vol.atr_expansion && trend.valid &&
                            trend.conflict_score >= 55.0);
      const bool momentum = (trend.valid && MathAbs(trend.momentum_strength) >= 70.0);

      if(high_vol && recovery)
        {
         beh = GM_BEH_HIGH_VOL_RECOVERY;
         match = 78.0;
        }
      else if(high_vol)
        {
         beh = GM_BEH_HIGH_VOL;
         match = 74.0;
        }
      else if(recovery)
        {
         beh = GM_BEH_RECOVERY;
         match = 72.0;
        }
      else if(news_hot)
        {
         beh = GM_BEH_NEWS_DRIVEN;
         match = 70.0;
        }
      else if(fake_bo)
        {
         beh = GM_BEH_FAKE_BREAKOUT;
         match = 68.0;
        }
      else if(momentum)
        {
         beh = GM_BEH_STRONG_MOMENTUM;
         match = 76.0;
        }
      else if(low_liq)
        {
         beh = GM_BEH_LOW_LIQUIDITY;
         match = 66.0;
        }
      else if(trending)
        {
         beh = GM_BEH_TRENDING;
         match = 80.0;
        }
      else if(sideways)
        {
         beh = GM_BEH_SIDEWAYS;
         match = 75.0;
        }
      else
        {
         beh = GM_BEH_UNKNOWN;
         match = 50.0;
        }

      if(intel.valid)
         match = 0.65 * match + 0.35 * GmMemClamp(intel.historical_similarity);

      r.behavior_type = beh;
      r.behavior_label = GmBehaviorName(beh);
      r.behavior_match_pct = GmMemClamp(match);
      r.behavior_map = StringFormat("%s | Match=%.0f%% | Hist=%.0f%%",
                                    r.behavior_label,
                                    r.behavior_match_pct,
                                    intel.valid ? intel.historical_similarity : 0.0);
     }
  };

#endif // GM_CMARKET_BEHAVIOR_LEARNING_ENGINE_MQH
//+------------------------------------------------------------------+
