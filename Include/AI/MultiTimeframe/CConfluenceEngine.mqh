//+------------------------------------------------------------------+
//|                                         CConfluenceEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CCONFLUENCE_ENGINE_MQH
#define GM_CCONFLUENCE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMultiTimeframeResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../OrderFlow/SGmOrderFlowResult.mqh"
#include "../NewsIntelligence/SGmNewsIntelligenceResult.mqh"
#include "../RecoveryIntelligence/SGmRecoveryIntelligenceResult.mqh"
#include "../MarketIntelligence/SGmMarketIntelligenceResult.mqh"

class CGmConfluenceEngine
  {
public:
   void Analyze(const SGmTrendAnalysisResult &trend,
                const SGmVolatilityAnalysisResult &vol,
                const SGmOrderFlowResult &of,
                const SGmNewsIntelligenceResult &ni,
                const SGmRecoveryIntelligenceResult &ri,
                const SGmMarketIntelligenceResult &mi,
                const SGmMultiTimeframeResult &partial,
                SGmMultiTimeframeResult &r)
     {
      const double trend_c = trend.valid ? GmMtfClamp(trend.strength_score) : 50.0;
      const double atr_c = vol.valid ? GmMtfClamp(vol.atr_strength) : 50.0;
      const double mom_c = trend.valid ? GmMtfClamp(trend.momentum_strength)
                           : GmMtfClamp(MathAbs(partial.h4.momentum));
      const double struct_c = mi.valid ? GmMtfClamp(mi.structure_quality)
                              : partial.structure_alignment;
      const double liq_c = of.valid ? GmMtfClamp(of.session_liquidity)
                           : (mi.valid ? GmMtfClamp(mi.liquidity_score) : 55.0);
      const double news_c = ni.valid
                            ? GmMtfClamp(100.0 - ni.news_impact_score * 0.25)
                            : 60.0;
      const double sess_c = of.valid ? GmMtfClamp(of.session_strength) : 55.0;
      const double rec_c = ri.valid ? GmMtfClamp(ri.recovery_success_rate) : 55.0;
      const double hist_c = partial.historical_similarity;

      r.confluence_score = GmMtfClamp(
                              0.16 * trend_c +
                              0.12 * atr_c +
                              0.12 * mom_c +
                              0.12 * struct_c +
                              0.10 * liq_c +
                              0.08 * news_c +
                              0.08 * sess_c +
                              0.08 * rec_c +
                              0.14 * partial.synchronization_score);

      r.strength_rating = GmMtfClamp(
                             0.40 * r.confluence_score +
                             0.30 * partial.execution_context_score +
                             0.30 * partial.correlation_index);

      r.confluence_confidence = GmMtfClamp(
                                   0.35 * r.confluence_score +
                                   0.25 * partial.alignment_confidence +
                                   0.20 * hist_c +
                                   0.20 * (trend.valid ? trend.confidence : 50.0));

      r.confluence_report = StringFormat(
                               "AI Confluence Engine:\r\nConfluence=%.0f Strength=%.0f Conf=%.0f\r\nTrend=%.0f ATR=%.0f Mom=%.0f Struct=%.0f Liq=%.0f\r\nNews=%.0f Sess=%.0f Rec=%.0f Hist=%.0f Sync=%.0f\r\n%s\r\n",
                               r.confluence_score, r.strength_rating, r.confluence_confidence,
                               trend_c, atr_c, mom_c, struct_c, liq_c,
                               news_c, sess_c, rec_c, hist_c, partial.synchronization_score,
                               GM_MTF_ADVISORY);
     }
  };

#endif // GM_CCONFLUENCE_ENGINE_MQH
//+------------------------------------------------------------------+
