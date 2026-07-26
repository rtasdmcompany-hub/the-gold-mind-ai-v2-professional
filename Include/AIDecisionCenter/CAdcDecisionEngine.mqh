//+------------------------------------------------------------------+
//|                                      CAdcDecisionEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CADC_DECISION_ENGINE_MQH
#define GM_CADC_DECISION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmAIDecisionCenterResult.mqh"
#include "../PortfolioAnalytics/SGmPortfolioAnalyticsResult.mqh"
#include "../TradeJournal/SGmTradeJournalPlatformResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmAdcDecisionEngine
  {
private:
   CGmLogger *m_logger;
   double     m_confidence;
   double     m_quality;
   int        m_count;

   double Clamp100(const double v) const
     {
      if(v < 0.0) return 0.0;
      if(v > 100.0) return 100.0;
      return v;
     }

public:
                     CGmAdcDecisionEngine(void)
                       : m_logger(NULL), m_confidence(0.0), m_quality(0.0), m_count(0) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_confidence = m_quality = 0.0;
      m_count = 0;
     }

   double Confidence(void) const { return m_confidence; }
   double Quality(void) const { return m_quality; }
   int Count(void) const { return m_count; }

   void Analyze(const SGmPortfolioAnalyticsResult &epa,
                const SGmTradeJournalPlatformResult &etj,
                SGmAIDecisionCenterResult &out)
     {
      // Catalog of Gold Mind decision dimensions (observe-only)
      m_count = 10;
      double conf = 55.0;
      conf += MathMin(20.0, epa.win_rate * 0.2);
      conf += MathMin(10.0, etj.discipline_score * 0.1);
      conf += MathMin(10.0, epa.portfolio_health * 0.1);
      conf += (etj.trades_total > 0 ? 5.0 : 0.0);

      double qual = 50.0;
      qual += MathMin(15.0, epa.profit_factor * 8.0);
      qual += MathMin(15.0, (100.0 - epa.max_drawdown_pct) * 0.15);
      qual += MathMin(10.0, etj.compliance_score * 0.1);
      qual += MathMin(10.0, epa.recovery_performance * 0.1);

      m_confidence = Clamp100(conf);
      m_quality = Clamp100(qual);

      out.decision_confidence = m_confidence;
      out.decision_quality = m_quality;
      out.decisions_recorded = m_count;
      out.trades_analyzed = epa.trades_closed > 0 ? epa.trades_closed : etj.trades_total;

      out.decision_report = StringFormat(
         "=== AI DECISION CENTER ===\r\n"
         "WhyTradeCreated=H4 Level Strategy | PendingLevel=3Buy/3Sell Catalog\r\n"
         "ATR14_TP=Analyzed | RiskCalc=Observe | H4Candle=Catalog\r\n"
         "MarketStructure=Observe | Recovery/BE/Partial/Trail=Lifecycle Catalog\r\n"
         "Confidence=%.0f | Quality=%.0f | Decisions=%d | Trades=%d\r\n"
         "AUTHORITY=ADVISORY ONLY — NO LIVE MUTATION\r\n",
         m_confidence, m_quality, m_count, out.trades_analyzed);

      out.decision_history = StringFormat(
         "History | Closed=%d Open=%d Today=%d | WR=%.1f%% PF=%.2f | Recovery=%.1f\r\n",
         epa.trades_closed, etj.trades_open, etj.trades_today,
         epa.win_rate, epa.profit_factor, epa.recovery_performance);

      out.decision_timeline = StringFormat(
         "Timeline | ETJ Events=%d | BestSession=%s | WorstSession=%s\r\n%s",
         etj.timeline_events, etj.best_session, etj.worst_session,
         etj.timeline_summary);

      if(m_logger != NULL)
         m_logger.Info(StringFormat("Decision Recorded | Conf=%.0f Qual=%.0f",
                                    m_confidence, m_quality), "ADC");
     }
  };

#endif // GM_CADC_DECISION_ENGINE_MQH
//+------------------------------------------------------------------+
