//+------------------------------------------------------------------+
//|                              CPortfolioCorrelationEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CPORTFOLIO_CORRELATION_ENGINE_MQH
#define GM_CPORTFOLIO_CORRELATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmPortfolioIntelligenceResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../OrderFlow/SGmOrderFlowResult.mqh"

/// Soft architectural correlations for future multi-symbol (observation proxies only).
class CGmPortfolioCorrelationEngine
  {
public:
   void Analyze(const SGmTrendAnalysisResult &trend,
                const SGmOrderFlowResult &of,
                const SGmPortfolioIntelligenceResult &partial,
                SGmPortfolioIntelligenceResult &r)
     {
      // Soft institutional priors (architecture): Gold vs silver +, Gold vs USD -, indices mixed
      const double gold_bias = trend.valid ? trend.directional_bias : 0.0;
      const double participation = of.valid ? of.participation_score : 55.0;

      r.positive_correlation = GmPiClamp(62.0 + MathAbs(gold_bias) * 0.15); // XAU↔XAG prior
      r.negative_correlation = GmPiClamp(58.0 + MathAbs(gold_bias) * 0.12); // XAU↔USD prior
      r.weak_correlation = GmPiClamp(35.0 + (100.0 - participation) * 0.15);
      r.strong_correlation = GmPiClamp(0.55 * r.positive_correlation + 0.45 * r.negative_correlation);

      // Single live symbol → portfolio corr reflects concentration
      r.portfolio_correlation = GmPiClamp(
                                   85.0 - (double)(partial.enabled_symbol_count - 1) * 10.0);
      r.market_correlation = GmPiClamp(
                                0.40 * r.strong_correlation +
                                0.30 * participation +
                                0.30 * (trend.valid ? trend.trend_stability : 55.0));

      r.diversification_score = GmPiClamp(
                                   15.0 + (double)partial.enabled_symbol_count * 8.0 +
                                   (100.0 - r.portfolio_correlation) * 0.5);
      // Explicit: single-symbol portfolio is concentrated by design
      if(partial.enabled_symbol_count <= 1)
         r.diversification_score = GmPiClamp(22.0 + (100.0 - r.portfolio_exposure) * 0.15);

      r.correlation_confidence = GmPiClamp(
                                    55.0 + (trend.valid ? 20.0 : 0.0) +
                                    (of.valid ? 15.0 : 0.0));

      r.correlation_matrix = StringFormat(
                                "XAUUSD[LIVE] | XAGUSD[+%.0f DISABLED] | USD[~-%.0f DISABLED] | FX/IDX/CRYPTO[FUTURE DISABLED]\r\nPos=%.0f Neg=%.0f Weak=%.0f Strong=%.0f | Port=%.0f Mkt=%.0f",
                                r.positive_correlation, r.negative_correlation,
                                r.positive_correlation, r.negative_correlation,
                                r.weak_correlation, r.strong_correlation,
                                r.portfolio_correlation, r.market_correlation);

      r.correlation_report = StringFormat(
                                "Portfolio Correlation Engine:\r\nDivScore=%.0f Conf=%.0f\r\n%s\r\n%s\r\n",
                                r.diversification_score, r.correlation_confidence,
                                r.correlation_matrix, GM_PI_ADVISORY);
     }
  };

#endif // GM_CPORTFOLIO_CORRELATION_ENGINE_MQH
//+------------------------------------------------------------------+
