//+------------------------------------------------------------------+
//|                               CH4ExecutionContextEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CH4_EXECUTION_CONTEXT_ENGINE_MQH
#define GM_CH4_EXECUTION_CONTEXT_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMultiTimeframeResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../OrderFlow/SGmOrderFlowResult.mqh"
#include "../NewsIntelligence/SGmNewsIntelligenceResult.mqh"
#include "../RecoveryIntelligence/SGmRecoveryIntelligenceResult.mqh"
#include "../MarketIntelligence/SGmMarketIntelligenceResult.mqh"

class CGmH4ExecutionContextEngine
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
      r.h4_structure_score = mi.valid
                             ? GmMtfClamp(mi.market_structure_score)
                             : (trend.valid ? GmMtfClamp(trend.strength_score) : 50.0);

      // Higher TF support for H4
      double htf = 40.0;
      if(partial.higher_tf_bias == GmMtfBiasFromTrend(partial.h4.direction) &&
         partial.h4.direction != GM_TREND_DIR_FLAT &&
         partial.h4.direction != GM_TREND_DIR_UNKNOWN)
         htf = 82.0;
      else if(partial.higher_tf_bias == GM_MTF_BIAS_NEUTRAL)
         htf = 55.0;
      else if(partial.higher_tf_bias == GM_MTF_BIAS_MIXED)
         htf = 45.0;
      else
         htf = 28.0;
      r.htf_support = GmMtfClamp(htf);

      // Lower TF confirmation (context only)
      double ltf = 40.0;
      if(partial.lower_tf_bias == GmMtfBiasFromTrend(partial.h4.direction) &&
         partial.h4.direction != GM_TREND_DIR_FLAT)
         ltf = 78.0;
      else if(partial.lower_tf_bias == GM_MTF_BIAS_MIXED)
         ltf = 48.0;
      else
         ltf = 32.0;
      r.ltf_confirmation = GmMtfClamp(ltf);

      r.historical_similarity = GmMtfClamp(
                                   0.40 * partial.synchronization_score +
                                   0.30 * partial.timeframe_agreement +
                                   0.30 * (ri.valid ? ri.historical_recovery_pct : 55.0));

      r.liquidity_context = of.valid ? GmMtfClamp(of.session_liquidity)
                            : (mi.valid ? GmMtfClamp(mi.liquidity_score) : 55.0);
      r.news_context = ni.valid
                       ? GmMtfClamp(50.0 + ni.news_impact_score * 0.35)
                       : 50.0;
      r.volatility_context = vol.valid
                             ? GmMtfClamp(vol.energy_score)
                             : (of.valid ? GmMtfClamp(of.energy_score) : 50.0);
      r.recovery_context = ri.valid
                           ? GmMtfClamp(ri.recovery_health_index)
                           : 55.0;

      r.execution_context_score = GmMtfClamp(
                                     0.22 * r.h4_structure_score +
                                     0.18 * r.htf_support +
                                     0.12 * r.ltf_confirmation +
                                     0.12 * r.historical_similarity +
                                     0.10 * r.liquidity_context +
                                     0.08 * r.volatility_context +
                                     0.08 * r.recovery_context +
                                     0.10 * partial.synchronization_score);

      if(r.execution_context_score >= 88.0)
         r.market_context_grade = GM_MTF_GRADE_A_PLUS;
      else if(r.execution_context_score >= 78.0)
         r.market_context_grade = GM_MTF_GRADE_A;
      else if(r.execution_context_score >= 65.0)
         r.market_context_grade = GM_MTF_GRADE_B;
      else if(r.execution_context_score >= 50.0)
         r.market_context_grade = GM_MTF_GRADE_C;
      else if(r.execution_context_score >= 35.0)
         r.market_context_grade = GM_MTF_GRADE_D;
      else
         r.market_context_grade = GM_MTF_GRADE_F;

      r.context_report = StringFormat(
                            "H4 Execution Context:\r\nContext=%.0f Grade=%s\r\nH4Struct=%.0f HTF=%.0f LTF=%.0f Hist=%.0f\r\nLiq=%.0f News=%.0f Vol=%.0f Rec=%.0f\r\n%s | %s\r\n",
                            r.execution_context_score, GmMtfGradeName(r.market_context_grade),
                            r.h4_structure_score, r.htf_support, r.ltf_confirmation,
                            r.historical_similarity, r.liquidity_context, r.news_context,
                            r.volatility_context, r.recovery_context,
                            GM_MTF_H4_RULE, GM_MTF_ADVISORY);
     }
  };

#endif // GM_CH4_EXECUTION_CONTEXT_ENGINE_MQH
//+------------------------------------------------------------------+
