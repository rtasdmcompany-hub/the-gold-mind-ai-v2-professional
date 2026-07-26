//+------------------------------------------------------------------+
//|                                    CPortfolioRiskEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CPORTFOLIO_RISK_ENGINE_MQH
#define GM_CPORTFOLIO_RISK_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmPortfolioIntelligenceResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../RiskIntelligence/SGmRiskIntelligenceResult.mqh"
#include "../RecoveryIntelligence/SGmRecoveryIntelligenceResult.mqh"
#include "../../Analytics/SGmAnalyticsSnapshot.mqh"

class CGmPortfolioRiskEngine
  {
public:
   void Analyze(const SGmAssistantResult &sup,
                const SGmAnalyticsSnapshot &a,
                const SGmRiskIntelligenceResult &risk,
                const SGmRecoveryIntelligenceResult &ri,
                const SGmPortfolioIntelligenceResult &partial,
                SGmPortfolioIntelligenceResult &r)
     {
      r.long_exposure = GmPiClamp((double)a.buy_open * 18.0 +
                                  (a.buy_trades > 0 ? 10.0 : 0.0));
      r.short_exposure = GmPiClamp((double)a.sell_open * 18.0 +
                                   (a.sell_trades > 0 ? 10.0 : 0.0));
      r.recovery_exposure = GmPiClamp(
                               (double)a.recovery_trades * 15.0 +
                               (partial.recovery_active ? 25.0 : 0.0) +
                               (ri.valid ? (100.0 - ri.recovery_health_index) * 0.25 : 0.0));
      r.total_exposure = GmPiClamp(
                            0.40 * r.long_exposure +
                            0.40 * r.short_exposure +
                            0.20 * r.recovery_exposure +
                            partial.portfolio_exposure * 0.15);

      r.drawdown_distribution = GmPiClamp(
                                   MathMax(a.current_dd_pct, a.daily_dd_pct) * 1.2 +
                                   MathMax(a.weekly_dd_pct, a.monthly_dd_pct) * 0.4);
      r.margin_risk = GmPiClamp(
                         partial.capital_usage_pct * 0.7 +
                         (sup.valid ? MathAbs(sup.margin_usage_pct) * 0.3 : 0.0));

      r.portfolio_risk_score = GmPiClamp(
                                  0.30 * r.total_exposure +
                                  0.25 * r.drawdown_distribution +
                                  0.20 * r.margin_risk +
                                  0.15 * r.recovery_exposure +
                                  0.10 * (risk.valid ? risk.exposure_score : 40.0));

      r.capital_protection_rating = GmPiClamp(
                                       0.35 * (sup.valid ? sup.capital_protection_score : 55.0) +
                                       0.25 * (100.0 - r.portfolio_risk_score * 0.7) +
                                       0.20 * partial.portfolio_stability_score +
                                       0.20 * (ri.valid ? ri.capital_protection_rating : 55.0));

      r.risk_report = StringFormat(
                         "Portfolio Risk Engine:\r\nRisk=%.0f CapProtect=%.0f\r\nTotal=%.0f Long=%.0f Short=%.0f RecExp=%.0f\r\nDDDist=%.0f MarginRisk=%.0f\r\n%s\r\n",
                         r.portfolio_risk_score, r.capital_protection_rating,
                         r.total_exposure, r.long_exposure, r.short_exposure, r.recovery_exposure,
                         r.drawdown_distribution, r.margin_risk, GM_PI_ADVISORY);
     }
  };

#endif // GM_CPORTFOLIO_RISK_ENGINE_MQH
//+------------------------------------------------------------------+
