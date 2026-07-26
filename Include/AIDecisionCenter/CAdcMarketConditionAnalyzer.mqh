//+------------------------------------------------------------------+
//|                              CAdcMarketConditionAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CADC_MARKET_CONDITION_ANALYZER_MQH
#define GM_CADC_MARKET_CONDITION_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmAIDecisionCenterResult.mqh"
#include "../PortfolioAnalytics/SGmPortfolioAnalyticsResult.mqh"
#include "../TradeJournal/SGmTradeJournalPlatformResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmAdcMarketConditionAnalyzer
  {
private:
   CGmLogger *m_logger;
   double     m_adaptability;

   double Clamp100(const double v) const
     {
      if(v < 0.0) return 0.0;
      if(v > 100.0) return 100.0;
      return v;
     }

   ENUM_GM_ADC_MARKET_CLASS Classify(const SGmPortfolioAnalyticsResult &epa,
                                     const SGmTradeJournalPlatformResult &etj) const
     {
      if(epa.risk_stability < 40.0 && epa.max_drawdown_pct > 15.0)
         return GM_ADC_MKT_HIGH_VOL;
      if(epa.risk_stability > 75.0 && epa.max_drawdown_pct < 5.0)
         return GM_ADC_MKT_LOW_VOL;
      if(epa.win_rate >= 58.0 && epa.profit_factor >= 1.4)
         return GM_ADC_MKT_TRENDING;
      if(etj.best_session == "London" || StringFind(etj.best_session, "London") >= 0)
         return GM_ADC_MKT_LONDON;
      if(etj.best_session == "NewYork" || StringFind(etj.best_session, "York") >= 0)
         return GM_ADC_MKT_NEWYORK;
      if(etj.best_session == "Asian" || StringFind(etj.best_session, "Asia") >= 0)
         return GM_ADC_MKT_ASIAN;
      if(epa.recovery_performance > 70.0 && epa.max_drawdown_pct > 10.0)
         return GM_ADC_MKT_WEEKEND_GAP;
      return GM_ADC_MKT_RANGING;
     }

public:
                     CGmAdcMarketConditionAnalyzer(void)
                       : m_logger(NULL), m_adaptability(0.0) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_adaptability = 0.0;
     }

   double Adaptability(void) const { return m_adaptability; }

   void Analyze(const SGmPortfolioAnalyticsResult &epa,
                const SGmTradeJournalPlatformResult &etj,
                SGmAIDecisionCenterResult &out)
     {
      out.market_class = Classify(epa, etj);

      double a = 55.0;
      a += MathMin(15.0, epa.portfolio_health * 0.12);
      a += MathMin(10.0, epa.recovery_performance * 0.1);
      a += MathMin(10.0, etj.discipline_score * 0.1);
      a += (out.market_class == GM_ADC_MKT_TRENDING ? 8.0 : 4.0);
      m_adaptability = Clamp100(a);
      out.market_adaptability = m_adaptability;

      out.market_report = StringFormat(
         "=== MARKET CONDITION ANALYZER ===\r\n"
         "Class=%s | Adaptability=%.0f\r\n"
         "Sessions Catalog: Asian/London/NewYork/News/WeekendGap\r\n"
         "Trend/Range/HighVol/LowVol classification from GM analytics\r\n",
         GmAdcMarketName(out.market_class), m_adaptability);

      if(m_logger != NULL)
         m_logger.Info("Market Classified | " + GmAdcMarketName(out.market_class), "ADC");
     }
  };

#endif // GM_CADC_MARKET_CONDITION_ANALYZER_MQH
//+------------------------------------------------------------------+
