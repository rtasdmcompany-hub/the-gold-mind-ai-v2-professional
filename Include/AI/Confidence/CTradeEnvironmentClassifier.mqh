//+------------------------------------------------------------------+
//|                             CTradeEnvironmentClassifier.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CTRADE_ENVIRONMENT_CLASSIFIER_MQH
#define GM_CTRADE_ENVIRONMENT_CLASSIFIER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmConfidenceAnalysisResult.mqh"

class CGmTradeEnvironmentClassifier
  {
public:
   void Classify(SGmConfidenceAnalysisResult &r)
     {
      const double c = r.overall_confidence;
      const double risk = r.risk_environment;

      if(risk >= 80.0 || (r.news_risk >= 85.0 && r.volatility_score >= 85.0))
        {
         r.environment = GM_CONF_ENV_EXTREME_RISK;
         r.environment_explain = "Extreme risk from news and/or explosive volatility; advisor note only — Core still executes.";
        }
      else if(risk >= 65.0 || c < 30.0)
        {
         r.environment = GM_CONF_ENV_HIGH_RISK;
         r.environment_explain = "High risk environment: elevated news/vol or weak multi-factor confidence.";
        }
      else if(c < 42.0 || r.quality.spread_stability < 40.0)
        {
         r.environment = GM_CONF_ENV_CAUTION;
         r.environment_explain = "Caution: confidence or spread stability below preferred H4 thresholds.";
        }
      else if(c >= 82.0 && r.market_quality >= 75.0 && risk < 40.0)
        {
         r.environment = GM_CONF_ENV_EXCELLENT;
         r.environment_explain = "Excellent H4 environment: strong trend/structure alignment with stable liquidity.";
        }
      else if(c >= 72.0 && r.market_quality >= 65.0)
        {
         r.environment = GM_CONF_ENV_VERY_GOOD;
         r.environment_explain = "Very good conditions for Gold Mind level deployment this H4 cycle.";
        }
      else if(c >= 58.0)
        {
         r.environment = GM_CONF_ENV_GOOD;
         r.environment_explain = "Good trading conditions; factors support normal Gold Mind H4 execution.";
        }
      else if(c >= 45.0)
        {
         r.environment = GM_CONF_ENV_NEUTRAL;
         r.environment_explain = "Neutral environment; mixed factors — Core proceeds per strategy rules.";
        }
      else
        {
         r.environment = GM_CONF_ENV_UNKNOWN;
         r.environment_explain = "Insufficient or conflicting signals for a firm grade.";
        }
     }
  };

#endif // GM_CTRADE_ENVIRONMENT_CLASSIFIER_MQH
//+------------------------------------------------------------------+
