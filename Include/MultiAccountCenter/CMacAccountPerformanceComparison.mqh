//+------------------------------------------------------------------+
//|                            CMacAccountPerformanceComparison.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CMAC_ACCOUNT_PERFORMANCE_COMPARISON_MQH
#define GM_CMAC_ACCOUNT_PERFORMANCE_COMPARISON_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMultiAccountCenterResult.mqh"
#include "../PortfolioAnalytics/SGmPortfolioAnalyticsResult.mqh"
#include "../TradeJournal/SGmTradeJournalPlatformResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmMacAccountPerformanceComparison
  {
private:
   CGmLogger *m_logger;

public:
                     CGmMacAccountPerformanceComparison(void) : m_logger(NULL) {}

   void Init(CGmLogger *logger) { m_logger = logger; }

   void Compare(const bool licensed,
                const SGmPortfolioAnalyticsResult &epa,
                const SGmTradeJournalPlatformResult &etj,
                SGmMultiAccountCenterResult &out)
     {
      if(!licensed)
        {
         out.primary_rank = out.performance_rank = 0;
         out.comparison_report = "Comparison suppressed — unlicensed\r\n";
         out.ranking_report = "Rankings unavailable — unlicensed\r\n";
         return;
        }

      // Single local licensed account = rank 1 within this terminal registry
      out.primary_rank = 1;
      out.performance_rank = 1;

      out.comparison_report = StringFormat(
         "=== ACCOUNT PERFORMANCE COMPARISON ===\r\n"
         "WR=%.1f%% PF=%.2f Recovery=%.2f DD=%.1f%% Growth=%.1f%%\r\n"
         "Trades=%d AvgWin=%.2f AvgLoss=%.2f RiskStab=%.0f ExecQ=%.0f\r\n"
         "Multi-account peer compare = Architecture Ready (local primary)\r\n",
         epa.win_rate, epa.profit_factor, epa.recovery_factor, epa.max_drawdown_pct,
         epa.capital_growth_pct, epa.trades_closed, etj.avg_win, etj.avg_loss,
         epa.risk_stability, etj.execution_score);

      out.ranking_report = StringFormat(
         "=== ACCOUNT / PERFORMANCE RANKING ===\r\n"
         "AccountRank=%d | PerformanceRank=%d | Health=%.0f\r\n",
         out.primary_rank, out.performance_rank, out.account_health);

      if(m_logger != NULL)
         m_logger.Info("Performance Ranking Updated | Rank=1 (local licensed)", "MAC");
     }
  };

#endif // GM_CMAC_ACCOUNT_PERFORMANCE_COMPARISON_MQH
//+------------------------------------------------------------------+
