//+------------------------------------------------------------------+
//|                                   CAIMarketTemperatureEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_MARKET_TEMPERATURE_ENGINE_MQH
#define GM_CAI_MARKET_TEMPERATURE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmOrderFlowResult.mqh"

class CGmAIMarketTemperatureEngine
  {
public:
   void Analyze(const SGmOrderFlowResult &partial,
                SGmOrderFlowResult &r)
     {
      r.temperature_index = GmOfClamp(
                               0.30 * partial.energy_score +
                               0.25 * partial.order_flow_score +
                               0.20 * partial.session_volatility +
                               0.15 * partial.session_strength +
                               0.10 * partial.institutional_activity_index);

      if(r.temperature_index < 25.0)
        {
         r.market_temperature = GM_OF_TEMP_COLD;
         r.temperature_explanation = "Participation and energy are subdued. Market is cold with limited institutional drive.";
        }
      else if(r.temperature_index < 40.0)
        {
         r.market_temperature = GM_OF_TEMP_CALM;
         r.temperature_explanation = "Calm conditions prevail. Liquidity is present but expansion energy is muted.";
        }
      else if(r.temperature_index < 55.0)
        {
         r.market_temperature = GM_OF_TEMP_NORMAL;
         r.temperature_explanation = "Normal market temperature. Balanced session flow suitable for standard observation.";
        }
      else if(r.temperature_index < 70.0)
        {
         r.market_temperature = GM_OF_TEMP_ACTIVE;
         r.temperature_explanation = "Active market. Order flow and session strength indicate elevated participation.";
        }
      else if(r.temperature_index < 85.0)
        {
         r.market_temperature = GM_OF_TEMP_HOT;
         r.temperature_explanation = "Hot market. Strong energy and institutional activity; monitor volatility closely.";
        }
      else
        {
         r.market_temperature = GM_OF_TEMP_EXTREME;
         r.temperature_explanation = "Extreme market temperature. Expansion and speed are elevated — advisory monitoring only.";
        }

      r.temperature_report = StringFormat(
                                "AI Market Temperature:\r\nIndex=%.0f | Class=%s\r\nExplanation:\r\n%s\r\n%s\r\n",
                                r.temperature_index, GmOfTempName(r.market_temperature),
                                r.temperature_explanation, GM_OF_ANALYSIS_ONLY);
     }
  };

#endif // GM_CAI_MARKET_TEMPERATURE_ENGINE_MQH
//+------------------------------------------------------------------+
