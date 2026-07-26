//+------------------------------------------------------------------+
//|                                 CErcVisualizationEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CERC_VISUALIZATION_ENGINE_MQH
#define GM_CERC_VISUALIZATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmReportingCenterResult.mqh"
#include "../PortfolioAnalytics/SGmPortfolioAnalyticsResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmErcVisualizationEngine
  {
private:
   CGmLogger *m_logger;

public:
                     CGmErcVisualizationEngine(void) : m_logger(NULL) {}

   void Init(CGmLogger *logger) { m_logger = logger; }

   void Build(const SGmPortfolioAnalyticsResult &epa, SGmReportingCenterResult &out)
     {
      out.visualization_catalog =
         "VISUALIZATION CATALOG (metadata — dashboard/export consumers)\r\n"
         "Equity Chart: " + epa.equity_curve_summary + "\r\n"
         "Balance Chart: " + epa.balance_curve_summary + "\r\n"
         "Drawdown Chart: " + epa.drawdown_curve_summary + "\r\n"
         "Monthly Heatmap: " + epa.monthly_heatmap + "\r\n"
         "Growth Timeline: " + epa.growth_curve_summary + "\r\n"
         "Recovery Timeline: " + epa.recovery_curve_summary + "\r\n"
         "Performance Timeline: " + epa.performance_timeline + "\r\n"
         "Profit Distribution: WR=" + DoubleToString(epa.win_rate, 1) +
         "% PF=" + DoubleToString(epa.profit_factor, 2) + "\r\n"
         "Loss Distribution: MaxConsecL=" + IntegerToString(epa.max_consec_losses) + "\r\n"
         "Risk Distribution: VaR=" + DoubleToString(epa.value_at_risk, 2) +
         " DD=" + DoubleToString(epa.max_drawdown_pct, 1) + "%\r\n";

      if(m_logger != NULL)
         m_logger.Info("Visualization Updated | catalog ready", "ERC");
     }
  };

#endif // GM_CERC_VISUALIZATION_ENGINE_MQH
//+------------------------------------------------------------------+
