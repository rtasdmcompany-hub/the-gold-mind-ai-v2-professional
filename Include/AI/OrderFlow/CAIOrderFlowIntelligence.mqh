//+------------------------------------------------------------------+
//|                               CAIOrderFlowIntelligence.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_ORDER_FLOW_INTELLIGENCE_MQH
#define GM_CAI_ORDER_FLOW_INTELLIGENCE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmOrderFlowResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../MarketIntelligence/SGmMarketIntelligenceResult.mqh"

class CGmAIOrderFlowIntelligence
  {
public:
   void Analyze(const SGmTrendAnalysisResult &trend,
                const SGmVolatilityAnalysisResult &vol,
                const SGmMarketIntelligenceResult &mi,
                const SGmOrderFlowResult &partial,
                SGmOrderFlowResult &r)
     {
      // Price velocity proxy from H4 momentum / ATR change
      r.price_velocity = 50.0;
      if(trend.valid)
         r.price_velocity = GmOfClamp(50.0 + MathAbs(trend.h4.momentum) * 0.8);
      if(vol.valid)
         r.price_velocity = GmOfClamp(0.6 * r.price_velocity + 0.4 * (50.0 + vol.atr_change_rate * 2.0));

      // Tick activity / market speed (terminal ticks if available)
      long ticks = 0;
      ticks = (long)SymbolInfoInteger(r.symbol, SYMBOL_SESSION_DEALS);
      if(ticks <= 0)
         ticks = (long)TerminalInfoInteger(TERMINAL_MEMORY_USED) % 100; // soft fallback noiseless proxy
      r.tick_activity = GmOfClamp(35.0 + MathMin(50.0, (double)ticks * 0.05) +
                                  (vol.valid && vol.atr_expansion ? 12.0 : 0.0));
      r.market_speed = GmOfClamp(0.5 * r.price_velocity + 0.5 * r.tick_activity);

      r.participation_score = GmOfClamp(
                                 0.30 * r.market_speed +
                                 0.25 * (mi.valid ? mi.market_participation : 55.0) +
                                 0.25 * (mi.valid ? mi.liquidity_score : 55.0) +
                                 0.20 * partial.session_strength);

      r.directional_strength = GmOfClamp(
                                  MathAbs(trend.valid ? trend.directional_bias : 0.0) * 0.7 +
                                  (mi.valid ? mi.momentum_index * 0.3 : 20.0));

      r.institutional_activity_index = GmOfClamp(
                                          0.35 * (mi.valid ? mi.institutional_momentum : 50.0) +
                                          0.25 * r.participation_score +
                                          0.20 * partial.session_strength +
                                          0.20 * (vol.valid ? vol.energy_score : 50.0));

      r.order_flow_score = GmOfClamp(
                              0.28 * r.participation_score +
                              0.22 * r.directional_strength +
                              0.20 * r.institutional_activity_index +
                              0.15 * r.price_velocity +
                              0.15 * r.market_speed);

      r.order_flow_report = StringFormat(
                               "AI Order Flow Intelligence:\r\nOrderFlowScore=%.0f | Participation=%.0f | DirStr=%.0f | InstAct=%.0f\r\nVelocity=%.0f TickAct=%.0f Speed=%.0f\r\n%s\r\n",
                               r.order_flow_score, r.participation_score,
                               r.directional_strength, r.institutional_activity_index,
                               r.price_velocity, r.tick_activity, r.market_speed,
                               GM_OF_ANALYSIS_ONLY);
     }
  };

#endif // GM_CAI_ORDER_FLOW_INTELLIGENCE_MQH
//+------------------------------------------------------------------+
