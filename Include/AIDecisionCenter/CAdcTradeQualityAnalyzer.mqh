//+------------------------------------------------------------------+
//|                                 CAdcTradeQualityAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CADC_TRADE_QUALITY_ANALYZER_MQH
#define GM_CADC_TRADE_QUALITY_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmAIDecisionCenterResult.mqh"
#include "../PortfolioAnalytics/SGmPortfolioAnalyticsResult.mqh"
#include "../TradeJournal/SGmTradeJournalPlatformResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmAdcTradeQualityAnalyzer
  {
private:
   CGmLogger *m_logger;
   double     m_score;

   double Clamp100(const double v) const
     {
      if(v < 0.0) return 0.0;
      if(v > 100.0) return 100.0;
      return v;
     }

public:
                     CGmAdcTradeQualityAnalyzer(void)
                       : m_logger(NULL), m_score(0.0) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_score = 0.0;
     }

   double Score(void) const { return m_score; }

   void Evaluate(const SGmPortfolioAnalyticsResult &epa,
                 const SGmTradeJournalPlatformResult &etj,
                 SGmAIDecisionCenterResult &out)
     {
      double s = 48.0;
      s += MathMin(12.0, epa.win_rate * 0.12);           // Entry accuracy proxy
      s += MathMin(10.0, etj.execution_score * 0.10);    // Exit / fill proxy
      s += MathMin(8.0, (30.0 - MathMin(30.0, epa.max_drawdown_pct)) * 0.25); // SL efficiency
      s += MathMin(8.0, epa.risk_reward_avg * 4.0);      // TP / RR
      s += MathMin(6.0, etj.avg_atr > 0.0 ? 6.0 : 2.0);  // ATR efficiency
      s += MathMin(8.0, epa.risk_stability * 0.08);      // Risk efficiency

      m_score = Clamp100(s);
      out.trade_quality_score = m_score;
      out.trade_quality_grade = GmAdcGradeFromScore(m_score);
      out.execution_grade = GmAdcGradeFromScore(etj.execution_score > 0.0
                                                ? etj.execution_score
                                                : m_score * 0.95);

      out.quality_report = StringFormat(
         "=== TRADE QUALITY ANALYZER ===\r\n"
         "Entry/Exit Accuracy=Proxy | SL=30pip Catalog | TP=ATR-14 Catalog\r\n"
         "ATR Efficiency | Risk Efficiency | Timing | Spread/Slippage=Observe\r\n"
         "News Environment=Catalog | QualityScore=%.0f | Grade=%s | ExecGrade=%s\r\n",
         m_score, GmAdcGradeName(out.trade_quality_grade),
         GmAdcGradeName(out.execution_grade));

      if(m_logger != NULL)
         m_logger.Info("Quality Analysis Completed | Grade=" +
                       GmAdcGradeName(out.trade_quality_grade), "ADC");
     }
  };

#endif // GM_CADC_TRADE_QUALITY_ANALYZER_MQH
//+------------------------------------------------------------------+
