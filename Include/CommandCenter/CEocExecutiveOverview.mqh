//+------------------------------------------------------------------+
//|                                       CEocExecutiveOverview.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEOC_EXECUTIVE_OVERVIEW_MQH
#define GM_CEOC_EXECUTIVE_OVERVIEW_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmCommandCenterResult.mqh"
#include "../PortfolioAnalytics/SGmPortfolioAnalyticsResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmEocExecutiveOverview
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
                     CGmEocExecutiveOverview(void) : m_logger(NULL) {}

   void Init(CGmLogger *logger) { m_logger = logger; }

   void Generate(const SGmPortfolioAnalyticsResult &epa,
                 SGmCommandCenterResult &out)
     {
      const bool connected = (bool)TerminalInfoInteger(TERMINAL_CONNECTED);
      out.system_availability = Clamp100(connected ? 98.0 - (double)out.critical_alerts * 10.0
                                                    : 40.0);

      out.daily_ops_summary = StringFormat(
         "=== DAILY OPERATIONS ===\r\n"
         "OpenAI=%d Pending=%d DailyPnL=%.2f Enterprise=%.0f Alerts=%d\r\n",
         out.open_ai_trades, out.pending_orders, epa.daily_pnl,
         out.enterprise_health, out.alert_count);

      out.weekly_ops_summary = StringFormat(
         "=== WEEKLY OPERATIONS ===\r\n"
         "WeeklyPnL=%.2f Perf=%.0f Infra=%.0f Availability=%.0f\r\n",
         epa.weekly_pnl, out.overall_performance, out.infrastructure_health,
         out.system_availability);

      out.monthly_ops_summary = StringFormat(
         "=== MONTHLY OPERATIONS ===\r\n"
         "MonthlyPnL=%.2f Growth=%.1f%% DD=%.1f%% PortfolioHealth=%.0f\r\n",
         epa.monthly_pnl, epa.capital_growth_pct, epa.max_drawdown_pct, epa.portfolio_health);

      out.availability_report = StringFormat(
         "=== SYSTEM AVAILABILITY ===\r\n"
         "Availability=%.0f%% | Terminal=%s | Critical=%d Warning=%d\r\n",
         out.system_availability, connected ? "ONLINE" : "OFFLINE",
         out.critical_alerts, out.warning_alerts);

      out.executive_summary = StringFormat(
         "=== EXECUTIVE OVERVIEW ===\r\n"
         "Enterprise=%.0f Perf=%.0f Availability=%.0f Infra=%.0f\r\n"
         "Trading=%s | AI=%s | Cloud=%s | License=%s\r\n"
         "Risk Overview DD=%.1f%% | Growth=%.1f%% | POLICY=MONITOR-ONLY\r\n"
         "%s%s%s%s",
         out.enterprise_health, out.overall_performance, out.system_availability,
         out.infrastructure_health,
         out.trading_engine_status, out.ai_engine_status, out.cloud_status, out.license_status,
         epa.max_drawdown_pct, epa.capital_growth_pct,
         out.daily_ops_summary, out.weekly_ops_summary,
         out.monthly_ops_summary, out.availability_report);

      if(m_logger != NULL)
         m_logger.Info("Executive Report Generated | Summary ready", "EOC");
     }
  };

#endif // GM_CEOC_EXECUTIVE_OVERVIEW_MQH
//+------------------------------------------------------------------+
