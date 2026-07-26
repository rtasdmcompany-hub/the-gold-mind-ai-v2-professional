//+------------------------------------------------------------------+
//|                                       CErcReportEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CERC_REPORT_ENGINE_MQH
#define GM_CERC_REPORT_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmReportingCenterResult.mqh"
#include "../PortfolioAnalytics/SGmPortfolioAnalyticsResult.mqh"
#include "../TradeJournal/SGmTradeJournalPlatformResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmErcReportEngine
  {
private:
   CGmLogger *m_logger;
   int        m_count;
   double     m_quality;

   double Clamp100(const double v) const
     {
      if(v < 0.0) return 0.0;
      if(v > 100.0) return 100.0;
      return v;
     }

public:
                     CGmErcReportEngine(void)
                       : m_logger(NULL), m_count(0), m_quality(0.0) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_count = 0;
      m_quality = 0.0;
     }

   int Count(void) const { return m_count; }
   double Quality(void) const { return m_quality; }

   void Generate(const SGmPortfolioAnalyticsResult &epa,
                 const SGmTradeJournalPlatformResult &etj,
                 SGmReportingCenterResult &out)
     {
      m_count = 10;

      out.daily_report = StringFormat(
         "=== DAILY REPORT ===\r\nPnL=%.2f | Health=%.0f | TradesToday=%d\r\n",
         epa.daily_pnl, epa.portfolio_health, etj.trades_today);

      out.weekly_report = StringFormat(
         "=== WEEKLY REPORT ===\r\nPnL=%.2f | WR=%.1f%% | PF=%.2f\r\n",
         epa.weekly_pnl, epa.win_rate, epa.profit_factor);

      out.monthly_report = StringFormat(
         "=== MONTHLY REPORT ===\r\nPnL=%.2f | DD=%.1f%% | Sharpe=%.2f | Grade=%s\r\n",
         epa.monthly_pnl, epa.max_drawdown_pct, epa.sharpe_ratio,
         GmEpaGradeName(epa.performance_grade));

      out.quarterly_report = StringFormat(
         "=== QUARTERLY REPORT ===\r\nPnL=%.2f | CapitalGrowth=%.1f%% | RiskStab=%.0f\r\n",
         epa.quarterly_pnl, epa.capital_growth_pct, epa.risk_stability);

      out.yearly_report = StringFormat(
         "=== YEARLY REPORT ===\r\nPnL=%.2f | EquityGrowth=%.1f%% | Recovery=%.1f\r\n",
         epa.yearly_pnl, epa.equity_growth_pct, epa.recovery_performance);

      out.session_report = StringFormat(
         "=== SESSION PERFORMANCE ===\r\nSessionPnL=%.2f | Best=%s | Worst=%s\r\n",
         epa.session_pnl, etj.best_session, etj.worst_session);

      out.growth_report = StringFormat(
         "=== ACCOUNT GROWTH ===\r\nCapital=%.1f%% Equity=%.1f%% Balance=%.1f%% Eff=%.0f\r\n",
         epa.capital_growth_pct, epa.equity_growth_pct, epa.balance_growth_pct,
         epa.capital_efficiency);

      out.risk_report = StringFormat(
         "=== RISK REPORT ===\r\n%s\r\n", epa.risk_report);

      out.recovery_report = StringFormat(
         "=== RECOVERY REPORT ===\r\nRF=%.2f RecoveryPerf=%.1f RecoveryRate=%.1f%%\r\n",
         epa.recovery_factor, epa.recovery_performance, etj.recovery_rate);

      out.executive_summary = StringFormat(
         "=== EXECUTIVE SUMMARY ===\r\n"
         "Portfolio Health=%.0f | Grade=%s | Net YTD=%.2f | MaxDD=%.1f%% | PF=%.2f | Sharpe=%.2f\r\n"
         "Journal Trades=%d Open=%d | ExecScore=%.0f | GM trades ONLY\r\n",
         epa.portfolio_health, GmEpaGradeName(epa.performance_grade),
         epa.yearly_pnl, epa.max_drawdown_pct, epa.profit_factor, epa.sharpe_ratio,
         etj.trades_total, etj.trades_open, etj.execution_score);

      out.latest_reports = "Daily|Weekly|Monthly|Quarterly|Yearly|Session|Growth|Risk|Recovery|Executive";
      out.reports_generated = m_count;

      m_quality = Clamp100(
         40.0 +
         (epa.valid ? 20.0 : 0.0) +
         (etj.valid ? 15.0 : 0.0) +
         MathMin(15.0, (double)epa.trades_closed * 0.5) +
         MathMin(10.0, epa.portfolio_health * 0.1));

      if(m_logger != NULL)
         m_logger.Success(StringFormat("Report Generated | count=%d quality=%.0f",
                                       m_count, m_quality), "ERC");
     }
  };

#endif // GM_CERC_REPORT_ENGINE_MQH
//+------------------------------------------------------------------+
