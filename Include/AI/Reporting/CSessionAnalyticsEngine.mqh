//+------------------------------------------------------------------+
//|                                    CSessionAnalyticsEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CSESSION_ANALYTICS_ENGINE_MQH
#define GM_CSESSION_ANALYTICS_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmReportingResult.mqh"
#include "../Intelligence/SGmIntelligenceResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Analytics/CAnalyticsEngine.mqh"
#include "../Market/MarketAnalysisConstants.mqh"

class CGmSessionAnalyticsEngine
  {
public:
   void Analyze(CGmPhase2Bridge *bridge,
                CGmAnalyticsEngine *analytics,
                const SGmIntelligenceResult &intel,
                const SGmAssistantResult &sup,
                SGmReportingResult &r)
     {
      r.session_end = TimeCurrent();
      r.session_start = r.session_end - 4 * 3600; // H4 observational window
      if(bridge != NULL)
         r.session_id = bridge.SessionId();

      r.session_market = intel.valid ? GmMktConditionName(intel.market_condition) : "Unknown";
      r.session_environment = intel.valid ? intel.market_score_condition : "—";
      r.session_volatility = intel.valid ? intel.volatility_state
                                         : (sup.valid ? 50.0 : 0.0);
      r.session_spread = sup.valid ? sup.spread_points : 0.0;
      r.session_recovery = (sup.valid && StringLen(sup.recovery_status) > 0)
                           ? sup.recovery_status : "None observed";
      r.session_drawdown = sup.valid
                           ? MathMax(sup.current_dd_pct, MathMax(sup.daily_dd_pct, 0.0))
                           : 0.0;

      r.session_outcome = "In Progress / Observational";
      if(analytics != NULL)
        {
         const SGmAnalyticsSnapshot a = analytics.Snapshot();
         if(a.session_win_rate >= 60.0)
            r.session_outcome = "Historically Favorable Bias";
         else if(a.session_win_rate > 0.0 && a.session_win_rate < 40.0)
            r.session_outcome = "Historically Challenging Bias";
         else if(a.completed_sessions > 0)
            r.session_outcome = "Mixed Historical Bias";
        }

      r.session_report = StringFormat(
                            "=== SESSION INTELLIGENCE REPORT ===\r\nSessionID=%I64u\r\nStart=%s\r\nEnd=%s\r\nMarket=%s\r\nEnvironment=%s\r\nVolatility=%.0f\r\nSpread=%.0f\r\nRecovery=%s\r\nDrawdown=%.1f%%\r\nOutcome=%s\r\n%s\r\n",
                            r.session_id,
                            TimeToString(r.session_start, TIME_DATE | TIME_MINUTES),
                            TimeToString(r.session_end, TIME_DATE | TIME_MINUTES),
                            r.session_market,
                            r.session_environment,
                            r.session_volatility,
                            r.session_spread,
                            r.session_recovery,
                            r.session_drawdown,
                            r.session_outcome,
                            GM_RPT_ADVISORY);
     }
  };

#endif // GM_CSESSION_ANALYTICS_ENGINE_MQH
//+------------------------------------------------------------------+
