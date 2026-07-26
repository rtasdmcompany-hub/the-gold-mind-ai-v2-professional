//+------------------------------------------------------------------+
//|                                 CMarketScenarioSimulator.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CMARKET_SCENARIO_SIMULATOR_PRED_MQH
#define GM_CMARKET_SCENARIO_SIMULATOR_PRED_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmPredictiveIntelligenceResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../NewsIntelligence/SGmNewsIntelligenceResult.mqh"
#include "../RecoveryIntelligence/SGmRecoveryIntelligenceResult.mqh"
#include "../MarketIntelligence/SGmMarketIntelligenceResult.mqh"
#include "../Trend/TrendAIConstants.mqh"

class CGmMarketScenarioSimulatorPred
  {
private:
   void Normalize8(double &a, double &b, double &c, double &d,
                   double &e, double &f, double &g, double &h)
     {
      double sum = a + b + c + d + e + f + g + h;
      if(sum <= 0.0)
        {
         a = b = c = d = e = f = g = h = 12.5;
         return;
        }
      a = a / sum * 100.0; b = b / sum * 100.0; c = c / sum * 100.0; d = d / sum * 100.0;
      e = e / sum * 100.0; f = f / sum * 100.0; g = g / sum * 100.0; h = h / sum * 100.0;
     }

public:
   void Analyze(const SGmTrendAnalysisResult &trend,
                const SGmVolatilityAnalysisResult &vol,
                const SGmNewsIntelligenceResult &ni,
                const SGmRecoveryIntelligenceResult &ri,
                const SGmMarketIntelligenceResult &mi,
                SGmPredictiveIntelligenceResult &r)
     {
      const double bias = trend.valid ? trend.directional_bias : 0.0;
      const bool bull = (trend.valid && (trend.primary == GM_TREND_DIR_BULL || bias > 12.0));
      const bool bear = (trend.valid && (trend.primary == GM_TREND_DIR_BEAR || bias < -12.0));
      const bool expand = (vol.valid && vol.atr_expansion);
      const bool compress = (vol.valid && vol.atr_compression);
      const bool news_hi = (ni.valid && ni.impact_class >= GM_NI_IMPACT_HIGH);
      const bool recovery = (ri.valid && (ri.recovery_attempts > 0 || ri.recovery_health_index < 50.0));
      const bool range_env = (mi.valid && mi.range_formation) ||
                             (trend.valid && trend.primary == GM_TREND_DIR_FLAT);

      r.scn_bull_cont = 12.0 + (bull ? 22.0 : 0.0) + MathMax(0.0, bias) * 0.25;
      r.scn_bear_cont = 12.0 + (bear ? 22.0 : 0.0) + MathMax(0.0, -bias) * 0.25;
      r.scn_range = 10.0 + (range_env ? 20.0 : 0.0) + (compress ? 12.0 : 0.0);
      r.scn_breakout = 8.0 + (expand ? 18.0 : 0.0) + (mi.valid ? mi.breakout_probability * 0.25 : 0.0);
      r.scn_false_breakout = 7.0 + (mi.valid ? mi.false_breakout_probability * 0.30 : 8.0) +
                             (news_hi ? 8.0 : 0.0);
      r.scn_high_vol = 8.0 + (expand ? 16.0 : 0.0) + (news_hi ? 14.0 : 0.0) +
                       (vol.valid ? vol.energy_score * 0.12 : 0.0);
      r.scn_low_vol = 8.0 + (compress ? 18.0 : 0.0) +
                      (vol.valid ? (100.0 - vol.energy_score) * 0.12 : 0.0);
      r.scn_recovery = 6.0 + (recovery ? 20.0 : 0.0) +
                       (ri.valid ? ri.recovery_probability * 0.25 : 0.0);

      Normalize8(r.scn_bull_cont, r.scn_bear_cont, r.scn_range, r.scn_breakout,
                 r.scn_false_breakout, r.scn_high_vol, r.scn_low_vol, r.scn_recovery);

      // Dominant
      double best = r.scn_bull_cont;
      r.dominant_scenario = GM_PRED_SCN_BULL_CONT;
      if(r.scn_bear_cont > best) { best = r.scn_bear_cont; r.dominant_scenario = GM_PRED_SCN_BEAR_CONT; }
      if(r.scn_range > best) { best = r.scn_range; r.dominant_scenario = GM_PRED_SCN_RANGE; }
      if(r.scn_breakout > best) { best = r.scn_breakout; r.dominant_scenario = GM_PRED_SCN_BREAKOUT; }
      if(r.scn_false_breakout > best) { best = r.scn_false_breakout; r.dominant_scenario = GM_PRED_SCN_FALSE_BREAKOUT; }
      if(r.scn_high_vol > best) { best = r.scn_high_vol; r.dominant_scenario = GM_PRED_SCN_HIGH_VOL; }
      if(r.scn_low_vol > best) { best = r.scn_low_vol; r.dominant_scenario = GM_PRED_SCN_LOW_VOL; }
      if(r.scn_recovery > best) { best = r.scn_recovery; r.dominant_scenario = GM_PRED_SCN_RECOVERY; }

      r.scenario_probability = best;

      r.scenario_report = StringFormat(
                             "Market Scenario Simulator:\r\nDominant=%s (%.0f%%)\r\nBullCont=%.0f BearCont=%.0f Range=%.0f Breakout=%.0f\r\nFalseBO=%.0f HighVol=%.0f LowVol=%.0f Recovery=%.0f\r\n%s\r\n",
                             GmPredScenarioName(r.dominant_scenario), r.scenario_probability,
                             r.scn_bull_cont, r.scn_bear_cont, r.scn_range, r.scn_breakout,
                             r.scn_false_breakout, r.scn_high_vol, r.scn_low_vol, r.scn_recovery,
                             GM_PRED_ADVISORY);
     }
  };

#endif // GM_CMARKET_SCENARIO_SIMULATOR_PRED_MQH
//+------------------------------------------------------------------+
