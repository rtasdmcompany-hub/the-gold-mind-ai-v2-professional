//+------------------------------------------------------------------+
//|                                       CBacktestFramework.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CBACKTEST_FRAMEWORK_MQH
#define GM_CBACKTEST_FRAMEWORK_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../Validation/SGmValidationResult.mqh"
#include "../Validation/ValidationConstants.mqh"
#include "../Logging/CLogger.mqh"
#include "../Core/CFileManager.mqh"

/// @file CBacktestFramework.mqh
/// @brief Collects strategy performance metrics from deal history (read-only).

class CGmBacktestFramework
  {
private:
   CGmLogger         *m_logger;
   CGmFileManager    *m_files;
   string             m_symbol;
   long               m_magic;
   SGmBacktestMetrics m_metrics;

public:
                     CGmBacktestFramework(void)
                       : m_logger(NULL), m_files(NULL), m_symbol(""), m_magic(0)
     {
      m_metrics.Reset();
     }

                    ~CGmBacktestFramework(void) { m_logger = NULL; m_files = NULL; }

   void Init(CGmLogger *logger,
             CGmFileManager *files,
             const string symbol,
             const long magic)
     {
      m_logger = logger;
      m_files = files;
      m_symbol = symbol;
      m_magic = magic;
      m_metrics.Reset();
      if(m_logger != NULL)
         m_logger.Info("Backtest Framework ready (read-only metrics)", "Backtest");
     }

   SGmBacktestMetrics Metrics(void) const { return m_metrics; }

   bool Collect(void)
     {
      m_metrics.Reset();

      if(!HistorySelect(0, TimeCurrent()))
        {
         if(m_logger != NULL)
            m_logger.Warning("HistorySelect failed — backtest metrics empty", "Backtest");
         return false;
        }

      double equity_curve = AccountInfoDouble(ACCOUNT_BALANCE);
      double peak = equity_curve;
      double max_dd = 0.0;
      double sum_win = 0.0;
      double sum_loss = 0.0;

      const int deals = HistoryDealsTotal();
      for(int i = 0; i < deals; i++)
        {
         const ulong deal = HistoryDealGetTicket(i);
         if(deal == 0)
            continue;
         if((long)HistoryDealGetInteger(deal, DEAL_MAGIC) != m_magic)
            continue;
         if(HistoryDealGetString(deal, DEAL_SYMBOL) != m_symbol)
            continue;

         const long entry = HistoryDealGetInteger(deal, DEAL_ENTRY);
         if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY)
            continue;

         const double pnl = HistoryDealGetDouble(deal, DEAL_PROFIT)
                            + HistoryDealGetDouble(deal, DEAL_SWAP)
                            + HistoryDealGetDouble(deal, DEAL_COMMISSION);
         m_metrics.total_trades++;
         equity_curve += pnl;
         if(equity_curve > peak)
            peak = equity_curve;
         if(peak > 0.0)
           {
            const double dd = ((peak - equity_curve) / peak) * 100.0;
            if(dd > max_dd)
               max_dd = dd;
           }

         if(pnl >= 0.0)
           {
            m_metrics.winning_trades++;
            sum_win += pnl;
            m_metrics.gross_profit += pnl;
           }
         else
           {
            m_metrics.losing_trades++;
            sum_loss += -pnl;
            m_metrics.gross_loss += -pnl;
           }
        }

      m_metrics.net_profit = m_metrics.gross_profit - m_metrics.gross_loss;
      m_metrics.max_drawdown = max_dd;
      if(m_metrics.total_trades > 0)
         m_metrics.win_rate = (100.0 * (double)m_metrics.winning_trades) / (double)m_metrics.total_trades;
      if(m_metrics.winning_trades > 0)
         m_metrics.average_win = sum_win / (double)m_metrics.winning_trades;
      if(m_metrics.losing_trades > 0)
         m_metrics.average_loss = sum_loss / (double)m_metrics.losing_trades;
      if(m_metrics.average_loss > 0.0)
         m_metrics.risk_reward = m_metrics.average_win / m_metrics.average_loss;
      if(m_metrics.gross_loss > 0.0)
         m_metrics.profit_factor = m_metrics.gross_profit / m_metrics.gross_loss;
      else if(m_metrics.gross_profit > 0.0)
         m_metrics.profit_factor = 999.0;
      if(m_metrics.max_drawdown > 0.0)
        {
         // Recovery factor using absolute DD% as proxy when equity peak unknown precisely
         const double dd_money_proxy = MathMax(1.0, AccountInfoDouble(ACCOUNT_BALANCE) * (m_metrics.max_drawdown / 100.0));
         m_metrics.recovery_factor = m_metrics.net_profit / dd_money_proxy;
        }
      if(m_metrics.total_trades > 0)
         m_metrics.expectancy = m_metrics.net_profit / (double)m_metrics.total_trades;
      m_metrics.valid = true;

      if(m_logger != NULL)
         m_logger.Success(StringFormat("Backtest metrics | trades=%d WR=%.1f%% PF=%.2f Net=%.2f MaxDD=%.2f%% Exp=%.2f",
                                       m_metrics.total_trades, m_metrics.win_rate,
                                       m_metrics.profit_factor, m_metrics.net_profit,
                                       m_metrics.max_drawdown, m_metrics.expectancy),
                          "Backtest");

      if(m_files != NULL)
        {
         string sym = m_symbol;
         StringReplace(sym, ".", "_");
         m_files.WriteText(StringFormat("%s%I64d_%s.txt", GM_VAL_BACKTEST_PREFIX, m_magic, sym),
                           Dump());
        }
      return true;
     }

   string Dump(void) const
     {
      return StringFormat(
         "# GM BACKTEST METRICS\r\n"
         "TotalTrades=%d\r\n"
         "WinningTrades=%d\r\n"
         "LosingTrades=%d\r\n"
         "WinRate=%.2f\r\n"
         "ProfitFactor=%.4f\r\n"
         "MaximumDrawdown=%.4f\r\n"
         "AverageWin=%.2f\r\n"
         "AverageLoss=%.2f\r\n"
         "RiskRewardRatio=%.4f\r\n"
         "NetProfit=%.2f\r\n"
         "RecoveryFactor=%.4f\r\n"
         "Expectancy=%.4f\r\n",
         m_metrics.total_trades,
         m_metrics.winning_trades,
         m_metrics.losing_trades,
         m_metrics.win_rate,
         m_metrics.profit_factor,
         m_metrics.max_drawdown,
         m_metrics.average_win,
         m_metrics.average_loss,
         m_metrics.risk_reward,
         m_metrics.net_profit,
         m_metrics.recovery_factor,
         m_metrics.expectancy);
     }
  };

#endif // GM_CBACKTEST_FRAMEWORK_MQH
//+------------------------------------------------------------------+
