//+------------------------------------------------------------------+
//|                                      CAIExplanationEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Human-readable explanations — ADVISORY ONLY                 |
//+------------------------------------------------------------------+
#ifndef GM_CAI_EXPLANATION_ENGINE_MQH
#define GM_CAI_EXPLANATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmIntelligenceResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"

class CGmAIExplanationEngine
  {
public:
   void Analyze(const SGmTrendAnalysisResult &trend,
                const SGmVolatilityAnalysisResult &vol,
                SGmIntelligenceResult &r)
     {
      string raw = "";
      string human = "";

      if(vol.valid && vol.atr_change_rate >= 25.0)
        {
         raw += StringFormat("ATR increased %.0f%%. ", vol.atr_change_rate);
         human += "Market volatility increased significantly. ";
        }
      else if(vol.valid && vol.atr_compression)
        {
         raw += "ATR compression detected. ";
         human += "Price range is compressing — energy may be building. ";
        }
      else if(vol.valid && vol.atr_expansion)
        {
         raw += "ATR expansion detected. ";
         human += "Range expansion is active — expect wider H4 movement. ";
        }

      if(r.liquidity_condition < 45.0)
        {
         raw += "Liquidity soft. ";
         human += "Liquidity appears thinner than usual. ";
        }
      else if(r.liquidity_condition >= 70.0)
        {
         human += "Liquidity conditions look healthy. ";
        }

      if(trend.valid && trend.strength_score < 40.0)
        {
         raw += "Trend weakened. ";
         human += "The current environment shows reduced directional stability. ";
        }
      else if(trend.valid && trend.strength_score >= 70.0)
        {
         raw += "Trend strong. ";
         human += "Directional structure remains constructive for observation. ";
        }

      if(r.risk_advisory == GM_RISK_ADV_HIGH || r.risk_advisory == GM_RISK_ADV_ELEVATED)
         human += "Risk advisory elevated — monitoring recommended. ";
      else if(r.market_score >= 80.0)
         human += "Overall conditions support continued strategy monitoring. ";
      else
         human += "Monitoring recommended. ";

      if(StringLen(human) == 0)
         human = "Market data reviewed. Continue advisory monitoring of Gold Mind sessions.";

      r.explanation_short = StringFormat("%s | Score %.0f/%s | %s",
                                         GmMktConditionName(r.market_condition),
                                         r.market_score,
                                         GmIntelGradeName(r.market_grade),
                                         GmRiskAdvName(r.risk_advisory));

      if(StringLen(raw) > 0)
         r.explanation = human + "[Signals: " + raw + "] | Pattern: " + r.pattern_insight +
                         " | " + GM_INTEL_ADVISORY;
      else
         r.explanation = human + " | Pattern: " + r.pattern_insight + " | " + GM_INTEL_ADVISORY;
     }
  };

#endif // GM_CAI_EXPLANATION_ENGINE_MQH
//+------------------------------------------------------------------+
