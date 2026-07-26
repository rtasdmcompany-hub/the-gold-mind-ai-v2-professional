//+------------------------------------------------------------------+
//|                                 CExposureIntelligenceEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEXPOSURE_INTELLIGENCE_ENGINE_MQH
#define GM_CEXPOSURE_INTELLIGENCE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmRiskIntelligenceResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../Intelligence/SGmIntelligenceResult.mqh"
#include "../../Analytics/SGmAnalyticsSnapshot.mqh"

class CGmExposureIntelligenceEngine
  {
public:
   void Analyze(const SGmAssistantResult &sup,
                const SGmIntelligenceResult &intel,
                const SGmAnalyticsSnapshot &an,
                SGmRiskIntelligenceResult &r)
     {
      const int open_trades = (an.valid ? an.running_trades : 0);
      const int pendings = (an.valid ? an.pending_orders : 0);
      const double float_loss = (an.valid ? MathAbs(an.floating_loss) : 0.0);
      const double risk_exp = (sup.valid ? MathMax(sup.risk_exposure_pct, 0.0) : 0.0);
      const double margin_use = (sup.valid ? MathMax(sup.margin_usage_pct, 0.0) : 0.0);
      const bool recovery = (sup.valid && (sup.recovery_active ||
                             StringFind(sup.recovery_status, "Recovery") >= 0));

      double score = 92.0;
      score -= MathMin(25.0, risk_exp * 1.8);
      score -= MathMin(18.0, margin_use * 0.25);
      score -= MathMin(12.0, (double)open_trades * 2.0);
      score -= MathMin(8.0, (double)pendings * 1.5);
      if(float_loss > 0.0 && AccountInfoDouble(ACCOUNT_EQUITY) > 0.0)
         score -= MathMin(15.0, 100.0 * float_loss / AccountInfoDouble(ACCOUNT_EQUITY));
      if(recovery)
         score -= 10.0;
      if(intel.valid && intel.market_score < 55.0)
         score -= 6.0;

      r.exposure_score = GmRiskIntClamp(score);
      if(r.exposure_score >= 80.0)
         r.exposure_status = "Healthy";
      else if(r.exposure_score >= 65.0)
         r.exposure_status = "Stable";
      else if(r.exposure_score >= 50.0)
         r.exposure_status = "Watch";
      else
         r.exposure_status = "Elevated";

      r.exposure_report = StringFormat(
                             "Exposure Health Score:\r\nExposure Score:\r\n%.0f/100\r\n\r\nStatus:\r\n%s\r\n\r\nOpen=%d Pending=%d RiskExp=%.1f%% MarginUse=%.0f%% Recovery=%s\r\n%s\r\n",
                             r.exposure_score,
                             r.exposure_status,
                             open_trades,
                             pendings,
                             risk_exp,
                             margin_use,
                             (recovery ? "Yes" : "No"),
                             GM_RISKINT_ANALYSIS_ONLY);
     }
  };

#endif // GM_CEXPOSURE_INTELLIGENCE_ENGINE_MQH
//+------------------------------------------------------------------+
