//+------------------------------------------------------------------+
//|                                 CErcExecutiveReportCenter.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CERC_EXECUTIVE_REPORT_CENTER_MQH
#define GM_CERC_EXECUTIVE_REPORT_CENTER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmReportingCenterResult.mqh"
#include "../PortfolioAnalytics/SGmPortfolioAnalyticsResult.mqh"
#include "../TradeJournal/SGmTradeJournalPlatformResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmErcExecutiveReportCenter
  {
private:
   CGmLogger *m_logger;

public:
                     CGmErcExecutiveReportCenter(void) : m_logger(NULL) {}

   void Init(CGmLogger *logger) { m_logger = logger; }

   void Compose(const SGmPortfolioAnalyticsResult &epa,
                const SGmTradeJournalPlatformResult &etj,
                SGmReportingCenterResult &out)
     {
      out.recommendations =
         "RECOMMENDATIONS (informational — no live changes)\r\n"
         "- Maintain Gold Mind Core as sole execution authority\r\n"
         "- Review MaxDD vs Risk Stability monthly\r\n"
         "- Use Investor Rating for capital allocation discussions\r\n"
         "- Correlate Session/News BI with journal best/worst sessions\r\n"
         "- Export Investor/Executive packages for stakeholders\r\n";

      // Extend executive summary already started by report engine
      out.executive_summary +=
         "--- PERFORMANCE ANALYSIS ---\r\n" + epa.performance_report + "\r\n"
         "--- RISK ANALYSIS ---\r\n" + epa.risk_report + "\r\n"
         "--- RECOVERY ANALYSIS ---\r\n" + out.recovery_report + "\r\n"
         "--- AI / JOURNAL STATISTICS ---\r\n" +
         StringFormat("Trades=%d Open=%d Today=%d Exec=%.0f Disc=%.0f Comp=%.0f\r\n",
                      etj.trades_total, etj.trades_open, etj.trades_today,
                      etj.execution_score, etj.discipline_score, etj.compliance_score) +
         "--- PORTFOLIO STATISTICS ---\r\n" + epa.capital_report + "\r\n"
         "--- TRADE STATISTICS ---\r\n" +
         StringFormat("Freq=%.2f/day Hold=%.0fs StreakW=%d StreakL=%d\r\n",
                      epa.trade_frequency, epa.avg_holding_sec,
                      epa.winning_streak, epa.losing_streak) +
         "--- INSTITUTIONAL SUMMARY ---\r\n" +
         StringFormat("BI=%.0f Forecast=%.0f InvestorRating=%.0f ReportQuality=%.0f\r\n",
                      out.bi_score, out.performance_forecast,
                      out.investor_rating, out.report_quality) +
         out.recommendations;

      if(m_logger != NULL)
         m_logger.Success("Executive Summary Created", "ERC");
     }
  };

#endif // GM_CERC_EXECUTIVE_REPORT_CENTER_MQH
//+------------------------------------------------------------------+
