//+------------------------------------------------------------------+
//|                               CCapitalProtectionAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     ANALYSIS ONLY — never changes risk / exposure / orders      |
//+------------------------------------------------------------------+
#ifndef GM_CCAPITAL_PROTECTION_ANALYZER_MQH
#define GM_CCAPITAL_PROTECTION_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmAssistantResult.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Analytics/CAnalyticsEngine.mqh"
#include "../../Recovery/CRecoveryBase.mqh"
#include "../../Protection/SGmAccountSnapshot.mqh"
#include "../../Protection/SGmDrawdownState.mqh"

/// @brief Scores capital health from read-only Protection / Analytics / Recovery.
class CGmCapitalProtectionAnalyzer
  {
public:
   void Analyze(CGmPhase2Bridge *bridge,
                CGmAnalyticsEngine *analytics,
                CGmRecoveryBase *recovery,
                SGmAssistantResult &r)
     {
      SGmAccountSnapshot acct;
      SGmDrawdownState dd;
      acct.Reset();
      dd.Reset();

      if(bridge != NULL)
        {
         bridge.ReadAccount(acct);
         bridge.ReadDrawdown(dd);
        }

      if(dd.valid)
        {
         r.current_dd_pct = dd.current_dd_pct;
         r.daily_dd_pct = dd.daily_dd_pct;
         r.weekly_dd_pct = dd.weekly_dd_pct;
         r.monthly_dd_pct = dd.monthly_dd_pct;
        }
      else if(analytics != NULL)
        {
         const SGmAnalyticsSnapshot a = analytics.Snapshot();
         r.current_dd_pct = a.current_dd_pct;
         r.daily_dd_pct = a.daily_dd_pct;
         r.weekly_dd_pct = a.weekly_dd_pct;
         r.monthly_dd_pct = a.monthly_dd_pct;
         r.risk_exposure_pct = a.current_risk_pct;
        }

      if(acct.valid)
        {
         if(acct.equity > 0.0 && acct.margin > 0.0)
            r.margin_usage_pct = GmAssistClamp(100.0 * acct.margin / acct.equity);
         r.floating_exposure = MathAbs(acct.floating_pnl);
         // Equity stability: closer to balance => higher score
         if(acct.balance > 0.0)
           {
            const double drift = 100.0 * MathAbs(acct.equity - acct.balance) / acct.balance;
            r.equity_stability = GmAssistClamp(100.0 - drift * 4.0);
           }
         else
            r.equity_stability = 50.0;
        }

      if(analytics != NULL && r.risk_exposure_pct <= 0.0)
         r.risk_exposure_pct = analytics.Snapshot().current_risk_pct;

      // Recovery observation only
      r.recovery_active = false;
      r.recovery_status = "Idle";
      if(recovery != NULL)
        {
         const SGmRecoverySnapshot rs = recovery.LastSnapshot();
         if(rs.own_positions > 0 || rs.own_pendings > 0)
           {
            // Soft flag: own book activity present (not strategy interference)
            r.recovery_status = StringFormat("Observed P=%d Pend=%d",
                                             rs.own_positions, rs.own_pendings);
           }
         if(analytics != NULL)
           {
            const SGmAnalyticsSnapshot a = analytics.Snapshot();
            if(a.recovery_trades > 0)
              {
               r.recovery_active = true;
               r.recovery_status = StringFormat("Recovery stats=%d", a.recovery_trades);
              }
           }
        }

      // Capital Protection Score — informational composite
      double score = 100.0;
      score -= MathMin(40.0, r.current_dd_pct * 3.0);
      score -= MathMin(20.0, r.daily_dd_pct * 4.0);
      score -= MathMin(15.0, r.weekly_dd_pct * 2.0);
      score -= MathMin(10.0, r.monthly_dd_pct * 1.5);
      score -= MathMin(15.0, r.margin_usage_pct * 0.15);
      score -= MathMin(10.0, r.risk_exposure_pct * 1.5);
      if(r.recovery_active)
         score -= 5.0;
      score = 0.55 * score + 0.45 * r.equity_stability;
      r.capital_protection_score = GmAssistClamp(score);
     }
  };

#endif // GM_CCAPITAL_PROTECTION_ANALYZER_MQH
//+------------------------------------------------------------------+
