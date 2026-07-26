//+------------------------------------------------------------------+
//|                                   SGmStrategyLabResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_STRATEGY_LAB_RESULT_MQH
#define GM_SGM_STRATEGY_LAB_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "StrategyLabConstants.mqh"

struct SGmStrategyLabResult
  {
   datetime            stamped_at;
   ENUM_GM_ESL_MODE    mode;
   ENUM_GM_ESL_QUEUE   queue_status;

   int                 bars_covered;
   int                 simulated_trades;
   int                 mc_runs;
   int                 wfa_folds;
   int                 active_gm_trades;
   bool                sims_paused;

   double              backtest_health;
   double              mc_confidence;
   double              walk_forward_efficiency;
   double              robustness_score;
   double              institutional_score;
   double              simulation_health;
   double              historical_coverage_pct;

   double              max_drawdown_pct;
   double              recovery_factor;
   double              profit_factor;
   double              expected_return;
   double              win_rate;
   double              loss_rate;
   double              expectancy;
   double              risk_of_ruin;
   double              consistency;

   string              backtest_summary;
   string              monte_carlo_summary;
   string              walk_forward_summary;
   string              comparison_matrix;
   string              optimization_report;
   string              validation_status;
   string              probability_report;
   string              export_status;
   string              center_status;
   string              insight;

   bool                may_execute;
   bool                may_modify_risk;
   bool                may_interrupt_trading;
   bool                may_modify_live_params;
   bool                valid;

   void Reset(void)
     {
      stamped_at = 0;
      mode = GM_ESL_MODE_IDLE;
      queue_status = GM_ESL_Q_IDLE;
      bars_covered = simulated_trades = mc_runs = wfa_folds = 0;
      active_gm_trades = 0;
      sims_paused = false;
      backtest_health = mc_confidence = walk_forward_efficiency = 0.0;
      robustness_score = institutional_score = simulation_health = 0.0;
      historical_coverage_pct = 0.0;
      max_drawdown_pct = recovery_factor = profit_factor = 0.0;
      expected_return = win_rate = loss_rate = expectancy = 0.0;
      risk_of_ruin = consistency = 0.0;
      backtest_summary = monte_carlo_summary = walk_forward_summary = "";
      comparison_matrix = optimization_report = validation_status = "";
      probability_report = export_status = "Architecture Ready";
      center_status = insight = "";
      may_execute = false;
      may_modify_risk = false;
      may_interrupt_trading = false;
      may_modify_live_params = false;
      valid = false;
     }
  };

struct SGmEslSimTrade
  {
   datetime open_time;
   int      side;          // 1 buy / -1 sell
   int      level;         // 1..3
   double   entry;
   double   sl;
   double   tp;
   double   atr;
   double   pnl_r;         // R-multiple
   bool     win;
   bool     recovery;
   string   scenario;
  };

#endif // GM_SGM_STRATEGY_LAB_RESULT_MQH
//+------------------------------------------------------------------+
