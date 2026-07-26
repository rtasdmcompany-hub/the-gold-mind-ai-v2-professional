//+------------------------------------------------------------------+
//|                            CEnterpriseStrategyLabEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 7 Sprint 2 — Strategy Validation Laboratory           |
//|     RESEARCH ONLY — NEVER interferes with live trading          |
//+------------------------------------------------------------------+
#ifndef GM_CENTERPRISE_STRATEGY_LAB_ENGINE_MQH
#define GM_CENTERPRISE_STRATEGY_LAB_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "StrategyLabConstants.mqh"
#include "SGmStrategyLabResult.mqh"
#include "CEslBacktestEngine.mqh"
#include "CEslMonteCarloEngine.mqh"
#include "CEslWalkForwardEngine.mqh"
#include "CEslParameterCompare.mqh"
#include "CEslRobustnessEngine.mqh"
#include "CEslTaskQueue.mqh"
#include "CEslExportCenter.mqh"
#include "CEslValidationDatabase.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"
#include "../AI/SGmAISnapshot.mqh"

class CGmEnterpriseStrategyLabEngine
  {
private:
   CGmLogger                   *m_logger;
   CGmEslBacktestEngine         m_backtest;
   CGmEslMonteCarloEngine       m_mc;
   CGmEslWalkForwardEngine      m_wfa;
   CGmEslParameterCompare       m_compare;
   CGmEslRobustnessEngine       m_robust;
   CGmEslTaskQueue              m_queue;
   CGmEslExportCenter           m_export;
   CGmEslValidationDatabase     m_db;
   SGmStrategyLabResult         m_last;
   int                          m_active_gm_trades;
   ulong                        m_last_ms;
   bool                         m_ready;
   bool                         m_exported;
   int                          m_scenario_rotate;

public:
                     CGmEnterpriseStrategyLabEngine(void)
                       : m_logger(NULL), m_active_gm_trades(0), m_last_ms(0),
                         m_ready(false), m_exported(false), m_scenario_rotate(0)
     {
      m_last.Reset();
     }

   bool Init(CGmLogger *logger,
             CGmFileManager *files,
             const long magic,
             const string symbol)
     {
      m_logger = logger;
      m_db.Init(logger, files, magic, symbol);
      m_backtest.Init(logger, symbol);
      m_mc.Init(logger);
      m_wfa.Init(logger);
      m_compare.Init(logger);
      m_robust.Init(logger);
      m_queue.Reset();
      m_export.Init(logger, files, m_db.Prefix());
      m_last.Reset();
      m_ready = true;
      m_exported = false;
      if(m_logger != NULL)
        {
         m_logger.Success("Strategy Lab Started | " + GM_ESL_VERSION, "ESL");
         m_logger.Info("POLICY | " + GM_ESL_POLICY, "ESL");
         m_logger.Info("SAFE | " + GM_ESL_SAFE, "ESL");
        }
      return true;
     }

   void SetActiveGmTrades(const int count)
     {
      m_active_gm_trades = MathMax(0, count);
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmStrategyLabResult Last(void) const { return m_last; }
   bool MayInterruptTrading(void) const { return false; }

   bool Process(const bool force = false)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(!force && m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_ESL_THROTTLE_MS)
         return true;
      m_last_ms = now;

      // Pause heavy sims while live GM trades are open — serve cache if available
      if(!m_queue.MayRunHeavy(m_active_gm_trades))
        {
         if(m_last.valid)
           {
            m_last.sims_paused = true;
            m_last.active_gm_trades = m_active_gm_trades;
            m_last.mode = GM_ESL_MODE_PAUSED;
            m_last.queue_status = GM_ESL_Q_PAUSED;
            m_last.center_status = "STRATEGY LAB PAUSED — LIVE GM TRADES ACTIVE";
            m_last.insight = StringFormat("Paused | ActiveGM=%d | Cached results served",
                                          m_active_gm_trades);
            if(m_logger != NULL)
               m_logger.Info("Heavy simulations paused | active GM trades=" +
                             IntegerToString(m_active_gm_trades), "ESL");
           }
         return true;
        }

      if(!force && m_queue.PreferCache((ulong)GM_ESL_THROTTLE_MS) && m_last.valid)
        {
         m_last.queue_status = GM_ESL_Q_CACHED;
         m_last.sims_paused = false;
         return true;
        }

      m_queue.MarkRunning();

      // Rotate scenario lightly for coverage
      ENUM_GM_ESL_SCENARIO sc = GM_ESL_SC_HISTORICAL;
      switch(m_scenario_rotate % 7)
        {
         case 1: sc = GM_ESL_SC_HIGH_VOL; break;
         case 2: sc = GM_ESL_SC_LOW_VOL; break;
         case 3: sc = GM_ESL_SC_SESSION; break;
         case 4: sc = GM_ESL_SC_NEWS; break;
         case 5: sc = GM_ESL_SC_RECOVERY; break;
         case 6: sc = GM_ESL_SC_HEDGE; break;
        }
      m_scenario_rotate++;

      m_backtest.Run(sc);

      const int mc_runs = (m_active_gm_trades > 0) ? GM_ESL_MC_RUNS_LIGHT : GM_ESL_MC_RUNS_FULL;
      m_mc.Run(GetPointer(m_backtest), mc_runs);
      m_wfa.Run(GetPointer(m_backtest));

      SGmStrategyLabResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.mode = GM_ESL_MODE_ROBUSTNESS;
      r.bars_covered = m_backtest.BarsCovered();
      r.simulated_trades = m_backtest.TradeCount();
      r.mc_runs = m_mc.Runs();
      r.wfa_folds = m_wfa.Folds();
      r.active_gm_trades = m_active_gm_trades;
      r.sims_paused = false;
      r.backtest_health = m_backtest.Health();
      r.backtest_summary = m_backtest.Summary();
      r.mc_confidence = m_mc.Confidence();
      r.monte_carlo_summary = m_mc.Summary();
      r.probability_report = m_mc.ProbabilityReport();
      r.walk_forward_efficiency = m_wfa.Efficiency();
      r.walk_forward_summary = m_wfa.Summary();

      m_robust.Validate(GetPointer(m_backtest), r.mc_confidence, m_wfa.Robustness(), r);
      r.robustness_score = MathMax(r.robustness_score, m_wfa.Robustness());

      m_compare.Compare(r.win_rate, r.profit_factor, r.backtest_health);
      r.comparison_matrix = m_compare.Matrix();
      r.optimization_report = m_compare.Report();

      r.historical_coverage_pct = MathMin(100.0,
         100.0 * (double)r.bars_covered / (double)GM_ESL_BARS_MAX);
      r.simulation_health = MathMin(100.0,
         0.35 * r.backtest_health + 0.30 * r.mc_confidence +
         0.20 * r.robustness_score + 0.15 * MathMin(100.0, r.walk_forward_efficiency));

      r.may_execute = false;
      r.may_modify_risk = false;
      r.may_interrupt_trading = false;
      r.may_modify_live_params = false;
      r.center_status = "STRATEGY LABORATORY — RESEARCH ONLY";
      r.insight = StringFormat(
         "%s | BT=%.0f MC=%.0f WFE=%.0f Robust=%.0f Inst=%.0f | %s",
         GmEslScenarioName(sc), r.backtest_health, r.mc_confidence,
         r.walk_forward_efficiency, r.robustness_score, r.institutional_score,
         r.validation_status);
      r.valid = true;

      if(!m_exported || force)
        {
         m_export.Export(r);
         m_exported = true;
        }
      r.export_status = m_export.Status();
      r.queue_status = GM_ESL_Q_CACHED;

      m_last = r;
      m_db.Persist(r);
      m_queue.MarkCached();
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = "Strategy Laboratory";
      s.ai_engine = "GoldMind Enterprise Strategy Lab";
      s.current_mode = m_last.sims_paused ? "ESL_PAUSED" : "ESL_RESEARCH_ONLY";
      s.confidence_pct = m_last.institutional_score;
      s.confidence_status = StringFormat("%.0f%%", m_last.historical_coverage_pct);

      s.w_trend_detector = StringFormat("%.0f | %s",
                                        m_last.backtest_health,
                                        m_last.validation_status);           // Backtest Results
      s.future_ai_score = StringFormat("%.0f", m_last.mc_confidence);        // Monte Carlo
      s.w_recovery_ai = StringFormat("%.0f", m_last.walk_forward_efficiency); // Walk-Forward
      s.prediction_status = StringFormat("%.0f", m_last.robustness_score);   // Robustness
      s.learning_status = StringFormat("%.0f", m_last.simulation_health);    // Simulation Health
      s.w_volatility_scanner = m_last.optimization_report;                   // Optimization
      s.w_market_analyzer = m_last.validation_status;                        // Validation Status
      s.w_news_analyzer = StringFormat("%.0f%%", m_last.historical_coverage_pct); // Coverage
      s.w_trade_confidence = GmEslQueueName(m_last.queue_status);            // Simulation Queue
      s.ai_version = StringFormat("Inst %.0f | PF %.2f",
                                  m_last.institutional_score, m_last.profit_factor);
      s.decision_status = "RESEARCH ONLY — CORE EXECUTION AUTHORITY";
      s.valid = true;
     }
  };

#endif // GM_CENTERPRISE_STRATEGY_LAB_ENGINE_MQH
//+------------------------------------------------------------------+
