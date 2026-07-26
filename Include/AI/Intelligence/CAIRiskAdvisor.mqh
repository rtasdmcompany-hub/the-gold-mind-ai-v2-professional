//+------------------------------------------------------------------+
//|                                            CAIRiskAdvisor.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Risk advisory levels — NEVER modifies Risk Engine           |
//+------------------------------------------------------------------+
#ifndef GM_CAI_RISK_ADVISOR_MQH
#define GM_CAI_RISK_ADVISOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmIntelligenceResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../News/SGmNewsAnalysisResult.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Protection/SGmAccountSnapshot.mqh"

class CGmAIRiskAdvisor
  {
public:
   void Analyze(CGmPhase2Bridge *bridge,
                const SGmAssistantResult &sup,
                const SGmNewsAnalysisResult &news,
                const SGmIntelligenceResult &partial,
                SGmIntelligenceResult &r)
     {
      r.exposure_pct = sup.valid ? sup.risk_exposure_pct : 0.0;
      r.drawdown_level = sup.valid
                         ? MathMax(sup.current_dd_pct, MathMax(sup.daily_dd_pct, sup.weekly_dd_pct))
                         : 0.0;
      r.recovery_status = (sup.valid && StringLen(sup.recovery_status) > 0)
                          ? sup.recovery_status : "Idle";

      SGmAccountSnapshot acct;
      acct.Reset();
      if(bridge != NULL)
         bridge.ReadAccount(acct);
      if(acct.valid)
        {
         r.equity = acct.equity;
         // Margin safety: high free margin / low usage => safer
         r.margin_safety = GmIntelClamp(100.0 - (sup.valid ? sup.margin_usage_pct : 0.0));
         if(acct.margin_level > 0.0)
            r.margin_safety = GmIntelClamp(0.5 * r.margin_safety +
                                           0.5 * MathMin(100.0, acct.margin_level / 5.0));
        }
      else
        {
         r.equity = 0.0;
         r.margin_safety = 70.0;
        }

      double market_risk = 40.0;
      if(partial.market_condition == GM_MKT_COND_HIGH_VOL)
         market_risk = 80.0;
      else if(partial.market_condition == GM_MKT_COND_BREAKOUT)
         market_risk = 60.0;
      else if(partial.market_condition == GM_MKT_COND_CONSOLIDATION ||
              partial.market_condition == GM_MKT_COND_LOW_VOL)
         market_risk = 35.0;
      else if(partial.market_condition == GM_MKT_COND_TRENDING ||
              partial.market_condition == GM_MKT_COND_STRONG_TREND)
         market_risk = 45.0;

      if(news.valid)
         market_risk = 0.7 * market_risk + 0.3 * GmIntelClamp(news.news_risk_score);

      double session_risk = GmIntelClamp(r.drawdown_level * 8.0);
      if(sup.valid && sup.recovery_active)
         session_risk = MathMin(100.0, session_risk + 15.0);

      // Higher risk_score => worse
      r.risk_score = GmIntelClamp(
                        0.30 * GmIntelClamp(r.exposure_pct * 8.0) +
                        0.25 * session_risk +
                        0.20 * market_risk +
                        0.15 * GmIntelClamp(100.0 - r.margin_safety) +
                        0.10 * GmIntelClamp(r.drawdown_level * 7.0));

      if(r.risk_score < 30.0)
         r.risk_advisory = GM_RISK_ADV_LOW;
      else if(r.risk_score < 50.0)
         r.risk_advisory = GM_RISK_ADV_MODERATE;
      else if(r.risk_score < 70.0)
         r.risk_advisory = GM_RISK_ADV_ELEVATED;
      else
         r.risk_advisory = GM_RISK_ADV_HIGH;

      r.risk_explanation = StringFormat(
                              "%s | DD=%.1f%% Exp=%.1f%% MarginSafe=%.0f | MarketRisk=%.0f | ADVISORY ONLY",
                              GmRiskAdvName(r.risk_advisory),
                              r.drawdown_level,
                              r.exposure_pct,
                              r.margin_safety,
                              market_risk);
     }
  };

#endif // GM_CAI_RISK_ADVISOR_MQH
//+------------------------------------------------------------------+
