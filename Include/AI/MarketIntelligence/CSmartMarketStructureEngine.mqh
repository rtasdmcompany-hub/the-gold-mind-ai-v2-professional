//+------------------------------------------------------------------+
//|                            CSmartMarketStructureEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CSMART_MARKET_STRUCTURE_ENGINE_MQH
#define GM_CSMART_MARKET_STRUCTURE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMarketIntelligenceResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Trend/TrendAIConstants.mqh"

class CGmSmartMarketStructureEngine
  {
public:
   void Analyze(const SGmTrendAnalysisResult &trend,
                SGmMarketIntelligenceResult &r)
     {
      r.higher_highs = false;
      r.higher_lows = false;
      r.lower_highs = false;
      r.lower_lows = false;
      r.break_of_structure = (trend.valid && (trend.bos_up || trend.bos_down));
      r.change_of_character = (trend.valid && (trend.choch_up || trend.choch_down));

      if(trend.valid)
        {
         if(trend.primary == GM_TREND_DIR_BULL || trend.directional_bias > 15.0)
           {
            r.higher_highs = true;
            r.higher_lows = true;
            r.structure_type = GM_MI_STRUCT_HH_HL;
           }
         else if(trend.primary == GM_TREND_DIR_BEAR || trend.directional_bias < -15.0)
           {
            r.lower_highs = true;
            r.lower_lows = true;
            r.structure_type = GM_MI_STRUCT_LH_LL;
           }
         else
           {
            r.range_formation = true;
            r.structure_type = GM_MI_STRUCT_RANGE;
           }

         if(r.change_of_character)
            r.structure_type = GM_MI_STRUCT_TRANSITION;

         r.trend_continuation = (trend.trend_stability >= 55.0 && trend.trend_exhaustion < 45.0 &&
                                 !r.change_of_character);
         r.trend_weakness = (trend.trend_exhaustion >= 50.0 || trend.trend_stability < 40.0);
         r.swing_strength = GmMiClamp(0.5 * trend.strength_score + 0.5 * MathAbs(trend.directional_bias));
         r.structure_quality = GmMiClamp(
                                  0.40 * trend.trend_stability +
                                  0.30 * trend.strength_score +
                                  0.20 * (100.0 - trend.trend_exhaustion) +
                                  0.10 * (r.break_of_structure ? 70.0 : 50.0));
         r.market_structure_score = r.structure_quality;
         r.trend_strength = trend.strength_score;
        }
      else
        {
         r.structure_type = GM_MI_STRUCT_UNKNOWN;
         r.structure_quality = 50.0;
         r.market_structure_score = 50.0;
        }

      r.structure_report = StringFormat(
                              "Smart Market Structure:\r\nType=%s | Quality=%.0f | Swing=%.0f\r\nHH=%s HL=%s LH=%s LL=%s\r\nCont=%s Weak=%s Range=%s BOS=%s CHoCH=%s\r\n%s\r\n",
                              GmMiStructureName(r.structure_type), r.structure_quality, r.swing_strength,
                              (r.higher_highs ? "Y" : "N"), (r.higher_lows ? "Y" : "N"),
                              (r.lower_highs ? "Y" : "N"), (r.lower_lows ? "Y" : "N"),
                              (r.trend_continuation ? "Y" : "N"), (r.trend_weakness ? "Y" : "N"),
                              (r.range_formation ? "Y" : "N"),
                              (r.break_of_structure ? "Y" : "N"), (r.change_of_character ? "Y" : "N"),
                              GM_MI_ANALYSIS_ONLY);
     }
  };

#endif // GM_CSMART_MARKET_STRUCTURE_ENGINE_MQH
//+------------------------------------------------------------------+
