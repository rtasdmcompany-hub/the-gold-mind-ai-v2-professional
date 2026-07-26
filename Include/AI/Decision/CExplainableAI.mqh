//+------------------------------------------------------------------+
//|                                          CExplainableAI.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CEXPLAINABLE_AI_MQH
#define GM_CEXPLAINABLE_AI_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmDecisionSupportResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../News/SGmNewsAnalysisResult.mqh"
#include "../Confidence/SGmConfidenceAnalysisResult.mqh"

/// @brief Human-readable XAI explanations — ADVISORY ONLY.
class CGmExplainableAI
  {
   void AddReason(SGmDecisionSupportResult &r, const string reason)
     {
      if(r.reason_count >= GM_DEC_REASON_MAX || StringLen(reason) == 0)
         return;
      r.reasons[r.reason_count++] = reason;
     }

public:
   void Explain(const SGmTrendAnalysisResult &trend,
                const SGmVolatilityAnalysisResult &vol,
                const SGmNewsAnalysisResult &news,
                const SGmConfidenceAnalysisResult &conf,
                SGmDecisionSupportResult &r)
     {
      r.reason_count = 0;

      if(trend.valid)
        {
         if(trend.primary == GM_TREND_DIR_BULL && trend.strength_score >= 60.0)
            AddReason(r, "Strong bullish market structure detected.");
         else if(trend.primary == GM_TREND_DIR_BEAR && trend.strength_score >= 60.0)
            AddReason(r, "Strong bearish market structure detected.");
         else if(trend.primary == GM_TREND_DIR_FLAT)
            AddReason(r, "Flat / consolidating market structure detected.");

         if(trend.h4.direction == trend.d1.direction &&
            trend.h4.direction != GM_TREND_DIR_FLAT)
            AddReason(r, "Trend alignment across H4 and Daily.");
         else if(trend.conflict_score >= 40.0)
            AddReason(r, "Trend conflict across timeframes reduces clarity.");

         if(trend.bos_up || trend.bos_down)
            AddReason(r, StringFormat("Break of structure observed (%s).",
                                      trend.bos_up ? "BOS Up" : "BOS Down"));
        }

      if(vol.valid)
        {
         if(vol.atr_expansion)
            AddReason(r, "ATR expansion indicates increased movement potential.");
         if(vol.atr_compression)
            AddReason(r, "ATR compression suggests range contraction.");
         if(vol.energy == GM_ENERGY_EXPLOSIVE || vol.energy == GM_ENERGY_EXTREME)
            AddReason(r, "Elevated market energy detected.");
        }

      if(news.valid)
        {
         if(news.seconds_until_high > 0 && news.seconds_until_high <= 7200)
            AddReason(r, StringFormat("High-impact news expected within %d hours.",
                                      MathMax(1, news.seconds_until_high / 3600)));
         else if(news.news_risk_score >= 60.0)
            AddReason(r, "Elevated news risk environment for gold/USD.");
         else
            AddReason(r, "News risk currently contained.");
        }

      const double spread = (r.symbol != "")
                            ? (double)SymbolInfoInteger(r.symbol, SYMBOL_SPREAD) : 0.0;
      if(spread > 0.0 && spread <= 35.0)
         AddReason(r, "Spread remains within acceptable limits.");
      else if(spread > 35.0)
         AddReason(r, "Spread expansion may affect fill quality (advisory).");

      if(r.historical_similarity >= 70.0)
         AddReason(r, "Historical confidence for similar sessions is high.");
      else if(r.historical_similarity > 0.0 && r.historical_similarity < 40.0)
         AddReason(r, "Limited historical similarity to prior H4 environments.");

      if(conf.valid)
         AddReason(r, StringFormat("Gold Mind H4 setup evaluated under %s environment (3 buy / 3 sell levels, ATR TP, 30-pip SL model — advisory only).",
                                   GmConfEnvName(conf.environment)));

      // Build full explanation
      r.explanation = StringFormat("%s (%.0f%%). ",
                                   GmDecRecoName(r.recommendation),
                                   r.overall_confidence);
      for(int i = 0; i < r.reason_count; i++)
        {
         r.explanation += r.reasons[i];
         if(i + 1 < r.reason_count)
            r.explanation += " ";
        }
      r.explanation += " " + GM_DEC_ADVISORY_ONLY + ".";
     }
  };

#endif // GM_CEXPLAINABLE_AI_MQH
//+------------------------------------------------------------------+
