//+------------------------------------------------------------------+
//|                             CTimeframeCorrelationEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CTIMEFRAME_CORRELATION_ENGINE_MQH
#define GM_CTIMEFRAME_CORRELATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMultiTimeframeResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"

class CGmTimeframeCorrelationEngine
  {
private:
   double DirCorr(const ENUM_GM_TREND_DIR a, const ENUM_GM_TREND_DIR b) const
     {
      if(a == GM_TREND_DIR_UNKNOWN || b == GM_TREND_DIR_UNKNOWN) return 50.0;
      if(a == GM_TREND_DIR_FLAT || b == GM_TREND_DIR_FLAT) return 60.0;
      return (a == b) ? 92.0 : 18.0;
     }

   double MomCorr(const double a, const double b) const
     {
      const double diff = MathAbs(a - b);
      return GmMtfClamp(100.0 - diff);
     }

public:
   void Analyze(const SGmVolatilityAnalysisResult &vol,
                const SGmMultiTimeframeResult &partial,
                SGmMultiTimeframeResult &r)
     {
      // Pairwise soft correlations vs H4 (execution hub)
      const double c_h1 = DirCorr(partial.h4.direction, partial.h1.direction);
      const double c_d1 = DirCorr(partial.h4.direction, partial.d1.direction);
      const double c_w1 = DirCorr(partial.h4.direction, partial.w1.direction);
      const double c_m15 = DirCorr(partial.h4.direction, partial.m15.direction);

      r.corr_trend = GmMtfClamp(0.35 * c_d1 + 0.30 * c_w1 + 0.20 * c_h1 + 0.15 * c_m15);
      r.corr_momentum = GmMtfClamp(
                           0.40 * MomCorr(partial.h4.momentum, partial.h1.momentum) +
                           0.35 * MomCorr(partial.h4.momentum, partial.d1.momentum) +
                           0.25 * MomCorr(partial.h4.momentum, partial.m15.momentum));
      r.corr_volatility = vol.valid
                          ? GmMtfClamp(vol.vol_stability)
                          : GmMtfClamp(0.5 * partial.volatility_alignment + 50.0);
      r.corr_atr = vol.valid
                   ? GmMtfClamp(55.0 + vol.atr_strength * 0.25 -
                                MathAbs(vol.atr_change_rate) * 0.5)
                   : 55.0;
      r.corr_structure = GmMtfClamp(
                            0.50 * partial.structure_alignment +
                            0.50 * DirCorr(partial.h4.direction, partial.d1.direction));
      r.corr_historical = GmMtfClamp(
                             0.50 * partial.historical_similarity +
                             0.50 * partial.timeframe_agreement);

      r.correlation_index = GmMtfClamp(
                               0.25 * r.corr_trend +
                               0.20 * r.corr_momentum +
                               0.15 * r.corr_volatility +
                               0.15 * r.corr_atr +
                               0.15 * r.corr_structure +
                               0.10 * r.corr_historical);

      r.correlation_confidence = GmMtfClamp(
                                    0.50 * r.correlation_index +
                                    0.30 * partial.alignment_confidence +
                                    0.20 * partial.timeframe_agreement);

      r.correlation_matrix = StringFormat(
                                "H4↔H1=%.0f H4↔D1=%.0f H4↔W1=%.0f H4↔M15=%.0f | Trend=%.0f Mom=%.0f Vol=%.0f ATR=%.0f",
                                c_h1, c_d1, c_w1, c_m15,
                                r.corr_trend, r.corr_momentum, r.corr_volatility, r.corr_atr);

      r.correlation_report = StringFormat(
                                "Timeframe Correlation:\r\nIndex=%.0f Conf=%.0f\r\n%s\r\nStruct=%.0f Hist=%.0f\r\n%s\r\n",
                                r.correlation_index, r.correlation_confidence,
                                r.correlation_matrix, r.corr_structure, r.corr_historical,
                                GM_MTF_ANALYSIS_ONLY);
     }
  };

#endif // GM_CTIMEFRAME_CORRELATION_ENGINE_MQH
//+------------------------------------------------------------------+
