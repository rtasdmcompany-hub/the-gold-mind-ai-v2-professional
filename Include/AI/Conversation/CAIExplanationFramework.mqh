//+------------------------------------------------------------------+
//|                                CAIExplanationFramework.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_EXPLANATION_FRAMEWORK_MQH
#define GM_CAI_EXPLANATION_FRAMEWORK_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmConversationResult.mqh"
#include "../Intelligence/SGmIntelligenceResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../Market/MarketAnalysisConstants.mqh"

class CGmAIExplanationFramework
  {
public:
   string ExplainVolatility(const SGmVolatilityAnalysisResult &vol,
                            const SGmIntelligenceResult &intel) const
     {
      if(vol.valid && vol.atr_expansion)
         return "Market volatility increased because average candle movement expanded compared with previous sessions (ATR expansion observed).";
      if(vol.valid && vol.atr_compression)
         return "Volatility looks compressed — candle ranges are tighter than recent averages, so energy may be building.";
      if(intel.valid && intel.market_condition == GM_MKT_COND_HIGH_VOL)
         return "Current classification indicates a high-volatility environment; closer observation is recommended (analysis only).";
      return "Volatility appears moderate relative to recent Gold Mind session context.";
     }

   string ExplainDrawdown(const SGmAssistantResult &sup) const
     {
      if(!sup.valid)
         return "Drawdown context is not available yet.";
      const double dd = MathMax(sup.current_dd_pct, MathMax(sup.daily_dd_pct, 0.0));
      if(dd >= 5.0 || sup.recovery_active)
         return StringFormat(
                   "Account exposure increased temporarily (observed drawdown %.1f%%) while recovery monitoring remains active. No risk parameters were changed by the Assistant.",
                   dd);
      if(dd > 0.0)
         return StringFormat("Current observed drawdown is %.1f%% and remains within informational monitoring thresholds.", dd);
      return "No meaningful drawdown pressure is currently highlighted by the Supervisor.";
     }

   string ExplainRecovery(const SGmAssistantResult &sup) const
     {
      if(!sup.valid)
         return "Recovery status is pending.";
      if(sup.recovery_active)
         return "Recovery activity is being observed from analytics/statistics. The Assistant reports this status only — Core Trading remains the sole execution authority.";
      return "No active recovery flag is highlighted. Status: " + sup.recovery_status;
     }
  };

#endif // GM_CAI_EXPLANATION_FRAMEWORK_MQH
//+------------------------------------------------------------------+
