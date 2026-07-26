//+------------------------------------------------------------------+
//|                                     CAdcLearningReports.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Recommendations ONLY — never auto-modify live AI logic      |
//+------------------------------------------------------------------+
#ifndef GM_CADC_LEARNING_REPORTS_MQH
#define GM_CADC_LEARNING_REPORTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmAIDecisionCenterResult.mqh"
#include "../PortfolioAnalytics/SGmPortfolioAnalyticsResult.mqh"
#include "../TradeJournal/SGmTradeJournalPlatformResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmAdcLearningReports
  {
private:
   CGmLogger *m_logger;

public:
                     CGmAdcLearningReports(void) : m_logger(NULL) {}

   void Init(CGmLogger *logger) { m_logger = logger; }

   void Generate(const SGmPortfolioAnalyticsResult &epa,
                 const SGmTradeJournalPlatformResult &etj,
                 SGmAIDecisionCenterResult &out)
     {
      out.daily_ai_report = StringFormat(
         "=== DAILY AI REPORT ===\r\n"
         "TodayPnL=%.2f | TradesToday=%d | DecisionConf=%.0f | Quality=%.0f\r\n",
         etj.today_pnl, etj.trades_today, out.decision_confidence, out.trade_quality_score);

      out.weekly_ai_report = StringFormat(
         "=== WEEKLY AI REPORT ===\r\n"
         "WeeklyPnL=%.2f | WR=%.1f%% | ExecHealth=%.0f | Adapt=%.0f\r\n",
         epa.weekly_pnl, epa.win_rate, out.execution_health, out.market_adaptability);

      out.monthly_ai_report = StringFormat(
         "=== MONTHLY AI REPORT ===\r\n"
         "MonthlyPnL=%.2f | DD=%.1f%% | BrokerQ=%.0f | Grade=%s\r\n",
         epa.monthly_pnl, epa.max_drawdown_pct, out.broker_quality,
         GmAdcGradeName(out.trade_quality_grade));

      out.recommendations =
         "RECOMMENDATIONS (ADVISORY — USER APPROVAL REQUIRED):\r\n"
         "1. Review H4 pending level selection vs session performance.\r\n"
         "2. Compare ATR-14 TP efficiency against historical fills.\r\n"
         "3. Audit BE / 80% partial / 20% trail outcomes on losing streaks.\r\n"
         "4. Monitor broker fill quality before any template change.\r\n"
         "5. NEVER auto-apply — Core Trading remains sole authority.\r\n";

      out.institutional_summary = StringFormat(
         "=== INSTITUTIONAL AI SUMMARY ===\r\n"
         "DecisionConf=%.0f DecisionQual=%.0f TradeQual=%.0f (%s)\r\n"
         "ExecHealth=%.0f BrokerQ=%.0f Market=%s Adapt=%.0f\r\n"
         "Trades=%d Decisions=%d | POLICY=ADVISORY ONLY\r\n"
         "%s",
         out.decision_confidence, out.decision_quality, out.trade_quality_score,
         GmAdcGradeName(out.trade_quality_grade),
         out.execution_health, out.broker_quality,
         GmAdcMarketName(out.market_class), out.market_adaptability,
         out.trades_analyzed, out.decisions_recorded,
         out.recommendations);

      if(m_logger != NULL)
         m_logger.Info("AI Report Generated | Institutional summary ready", "ADC");
     }
  };

#endif // GM_CADC_LEARNING_REPORTS_MQH
//+------------------------------------------------------------------+
