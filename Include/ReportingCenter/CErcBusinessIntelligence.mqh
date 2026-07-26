//+------------------------------------------------------------------+
//|                              CErcBusinessIntelligence.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CERC_BUSINESS_INTELLIGENCE_MQH
#define GM_CERC_BUSINESS_INTELLIGENCE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmReportingCenterResult.mqh"
#include "../PortfolioAnalytics/SGmPortfolioAnalyticsResult.mqh"
#include "../TradeJournal/SGmTradeJournalPlatformResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmErcBusinessIntelligence
  {
private:
   CGmLogger *m_logger;

   double Clamp100(const double v) const
     {
      if(v < 0.0) return 0.0;
      if(v > 100.0) return 100.0;
      return v;
     }

public:
                     CGmErcBusinessIntelligence(void) : m_logger(NULL) {}

   void Init(CGmLogger *logger) { m_logger = logger; }

   void Analyze(const SGmPortfolioAnalyticsResult &epa,
                const SGmTradeJournalPlatformResult &etj,
                SGmReportingCenterResult &out)
     {
      const double growth_trend = Clamp100(50.0 + epa.capital_growth_pct * 0.8);
      const double perf_trend = Clamp100(40.0 + epa.win_rate * 0.4 + epa.profit_factor * 8.0);
      const double freq_score = Clamp100(30.0 + epa.trade_frequency * 40.0);
      const double risk_trend = epa.risk_stability;
      const double recovery_trend = Clamp100(epa.recovery_performance);
      const double session_score = Clamp100(50.0 + epa.session_pnl / MathMax(1.0, MathAbs(epa.monthly_pnl) + 1.0) * 20.0);
      const double news_proxy = Clamp100(55.0 + etj.execution_score * 0.2);
      const double seasonal = Clamp100(50.0 + epa.quarterly_pnl / MathMax(1.0, MathAbs(epa.yearly_pnl) + 1.0) * 25.0);

      out.bi_score = Clamp100(
         0.18 * growth_trend + 0.18 * perf_trend + 0.10 * freq_score +
         0.14 * risk_trend + 0.12 * recovery_trend + 0.10 * session_score +
         0.08 * news_proxy + 0.10 * seasonal);

      // Simple forecast: blend recent momentum
      out.performance_forecast = Clamp100(
         0.45 * out.bi_score +
         0.30 * (50.0 + epa.monthly_pnl / MathMax(1.0, MathAbs(epa.yearly_pnl) + 1.0) * 30.0) +
         0.25 * epa.portfolio_health);

      out.bi_report = StringFormat(
         "BUSINESS INTELLIGENCE | Score=%.0f Forecast=%.0f | Growth=%.0f Perf=%.0f Freq=%.0f "
         "Risk=%.0f Recovery=%.0f Session=%.0f News=%.0f Seasonal=%.0f",
         out.bi_score, out.performance_forecast, growth_trend, perf_trend, freq_score,
         risk_trend, recovery_trend, session_score, news_proxy, seasonal);

      if(m_logger != NULL)
         m_logger.Success("Business Analysis Completed | BI=" +
                          DoubleToString(out.bi_score, 0), "ERC");
     }
  };

#endif // GM_CERC_BUSINESS_INTELLIGENCE_MQH
//+------------------------------------------------------------------+
