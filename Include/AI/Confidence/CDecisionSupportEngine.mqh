//+------------------------------------------------------------------+
//|                                    CDecisionSupportEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CDECISION_SUPPORT_ENGINE_MQH
#define GM_CDECISION_SUPPORT_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmConfidenceAnalysisResult.mqh"

/// @brief Recommendation generator — NEVER triggers trading actions.
class CGmDecisionSupportEngine
  {
public:
   void Recommend(SGmConfidenceAnalysisResult &r)
     {
      // Priority order for advisory labels
      if(r.news_risk >= 70.0)
         r.recommendation = GM_CONF_RECO_NEWS_VOL;
      else if(r.quality.spread_stability < 40.0)
         r.recommendation = GM_CONF_RECO_SPREAD_EXPAND;
      else if(r.volatility_score >= 75.0)
         r.recommendation = GM_CONF_RECO_ELEVATED_VOL;
      else if(r.factors.trend < 40.0)
         r.recommendation = GM_CONF_RECO_WEAK_TREND;
      else if(r.factors.momentum >= 70.0 && r.overall_confidence >= 60.0)
         r.recommendation = GM_CONF_RECO_STRONG_MOMENTUM;
      else if(r.overall_confidence >= 75.0 &&
              (r.environment == GM_CONF_ENV_EXCELLENT ||
               r.environment == GM_CONF_ENV_VERY_GOOD ||
               r.environment == GM_CONF_ENV_GOOD))
         r.recommendation = GM_CONF_RECO_HIGH_PROB;
      else if(r.overall_confidence < 40.0 ||
              r.environment == GM_CONF_ENV_UNKNOWN)
         r.recommendation = GM_CONF_RECO_UNCERTAIN;
      else
         r.recommendation = GM_CONF_RECO_NORMAL;

      r.insight = StringFormat("%s | %s | conf=%.0f | TQ=%.0f | MQ=%.0f | %s | %s",
                               GmConfEnvName(r.environment),
                               GmConfRecoName(r.recommendation),
                               r.overall_confidence,
                               r.trade_quality,
                               r.market_quality,
                               r.session_rating,
                               GM_CONF_ADVISOR_ONLY);
     }
  };

#endif // GM_CDECISION_SUPPORT_ENGINE_MQH
//+------------------------------------------------------------------+
