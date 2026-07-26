//+------------------------------------------------------------------+
//|                        CEnterpriseOptimizationLabEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 7 Sprint 3 — Strategy Optimization & Comparison       |
//|     RESEARCH ONLY — NEVER auto-applies live parameters          |
//+------------------------------------------------------------------+
#ifndef GM_CENTERPRISE_OPTIMIZATION_LAB_ENGINE_MQH
#define GM_CENTERPRISE_OPTIMIZATION_LAB_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "OptimizationLabConstants.mqh"
#include "SGmOptimizationLabResult.mqh"
#include "CEolStrategyCompare.mqh"
#include "CEolAiOptimizationLab.mqh"
#include "CEolParameterIntelligence.mqh"
#include "CEolMultiDatasetValidation.mqh"
#include "CEolRecommendationEngine.mqh"
#include "CEolTaskQueue.mqh"
#include "CEolExportCenter.mqh"
#include "CEolOptimizationDatabase.mqh"
#include "../StrategyLab/CEnterpriseStrategyLabEngine.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"
#include "../AI/SGmAISnapshot.mqh"

class CGmEnterpriseOptimizationLabEngine
  {
private:
   CGmLogger                         *m_logger;
   CGmEnterpriseStrategyLabEngine    *m_slab; // observe-only bind
   CGmEolStrategyCompare              m_compare;
   CGmEolAiOptimizationLab            m_optlab;
   CGmEolParameterIntelligence        m_param;
   CGmEolMultiDatasetValidation       m_datasets;
   CGmEolRecommendationEngine         m_reco;
   CGmEolTaskQueue                    m_queue;
   CGmEolExportCenter                 m_export;
   CGmEolOptimizationDatabase         m_db;
   SGmOptimizationLabResult           m_last;
   int                                m_active_gm_trades;
   ulong                              m_last_ms;
   bool                               m_ready;
   bool                               m_exported;

public:
                     CGmEnterpriseOptimizationLabEngine(void)
                       : m_logger(NULL), m_slab(NULL), m_active_gm_trades(0),
                         m_last_ms(0), m_ready(false), m_exported(false)
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
      m_compare.Init(logger);
      m_optlab.Init(logger);
      m_param.Init(logger);
      m_datasets.Init(logger);
      m_reco.Init(logger);
      m_queue.Reset();
      m_export.Init(logger, files, m_db.Prefix());
      m_last.Reset();
      m_ready = true;
      m_exported = false;
      if(m_logger != NULL)
        {
         m_logger.Success("Optimization Lab Started | " + GM_EOL_VERSION, "EOL");
         m_logger.Info("POLICY | " + GM_EOL_POLICY, "EOL");
         m_logger.Info("SAFE | " + GM_EOL_SAFE, "EOL");
        }
      return true;
     }

   // Observe-only — reads Last() scores; never modifies Strategy Lab
   void BindStrategyLab(CGmEnterpriseStrategyLabEngine *slab) { m_slab = slab; }

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
   SGmOptimizationLabResult Last(void) const { return m_last; }
   bool MayInterruptTrading(void) const { return false; }
   bool MayAutoApplyParams(void) const { return false; }

   bool Process(const bool force = false)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(!force && m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_EOL_THROTTLE_MS)
         return true;
      m_last_ms = now;

      if(!m_queue.MayRunHeavy(m_active_gm_trades))
        {
         if(m_last.valid)
           {
            m_last.opt_paused = true;
            m_last.active_gm_trades = m_active_gm_trades;
            m_last.queue_status = GM_EOL_Q_PAUSED;
            m_last.center_status = "OPTIMIZATION PAUSED — LIVE GM TRADES ACTIVE";
            m_last.insight = StringFormat("Paused | ActiveGM=%d | Cached recommendations",
                                          m_active_gm_trades);
            if(m_logger != NULL)
               m_logger.Info("Optimization paused | active GM trades=" +
                             IntegerToString(m_active_gm_trades), "EOL");
           }
         return true;
        }

      if(!force && m_queue.PreferCache((ulong)GM_EOL_THROTTLE_MS) && m_last.valid)
        {
         m_last.queue_status = GM_EOL_Q_CACHED;
         m_last.opt_paused = false;
         return true;
        }

      m_queue.MarkRunning();

      double lab_health = 65.0;
      double lab_robust = 65.0;
      double lab_inst = 65.0;
      double win_proxy = 55.0;
      double dd_proxy = 20.0;
      if(m_slab != NULL && m_slab.IsReady() && m_slab.Last().valid)
        {
         lab_health = m_slab.Last().backtest_health;
         lab_robust = m_slab.Last().robustness_score;
         lab_inst = m_slab.Last().institutional_score;
         win_proxy = m_slab.Last().win_rate;
         dd_proxy = m_slab.Last().max_drawdown_pct;
        }

      m_compare.Compare(lab_health, lab_robust, lab_inst);
      m_optlab.Optimize(m_compare.ComparisonScore(), lab_health, win_proxy);
      m_datasets.Validate(lab_health);
      m_param.Analyze(m_optlab.ParameterStability(),
                      m_datasets.Adaptability(),
                      lab_robust,
                      dd_proxy);
      m_reco.Recommend(GetPointer(m_compare), GetPointer(m_datasets),
                       m_optlab.OptimizationScore(), m_param.Confidence());

      SGmOptimizationLabResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.profiles_compared = m_compare.Count();
      r.datasets_validated = m_datasets.Validated();
      r.active_gm_trades = m_active_gm_trades;
      r.opt_paused = false;
      r.comparison_score = m_compare.ComparisonScore();
      r.optimization_score = m_optlab.OptimizationScore();
      r.parameter_stability = m_optlab.ParameterStability();
      r.parameter_confidence = m_param.Confidence();
      r.market_adaptability = m_datasets.Adaptability();
      r.institutional_score = m_reco.Institutional();
      r.historical_rank_top = 0.0;
      SGmEolProfileScore top;
      if(m_compare.GetAt(0, top))
         r.historical_rank_top = top.rank_score;

      r.best_profile = m_reco.Best();
      r.safest_profile = m_reco.Safest();
      r.lowest_dd_profile = m_reco.LowestDd();
      r.best_recovery_profile = m_reco.BestRecovery();
      r.best_news_profile = m_reco.BestNews();
      r.best_session_profile = m_reco.BestSession();

      r.comparison_summary = m_compare.Summary();
      r.ranking_summary = m_compare.Ranking();
      r.optimization_suggestions = m_optlab.Suggestions();
      r.parameter_report = m_param.Report();
      r.adaptability_report = m_datasets.Report();
      r.recommendation_report = m_reco.Report();
      r.validation_status = (r.institutional_score >= 70.0)
         ? "PASS — Recommendations ready for user review"
         : ((r.institutional_score >= 55.0) ? "REVIEW" : "HOLD");

      r.may_execute = false;
      r.may_modify_risk = false;
      r.may_interrupt_trading = false;
      r.may_auto_apply_params = false;
      r.center_status = "STRATEGY OPTIMIZATION CENTER — RESEARCH ONLY";
      r.insight = StringFormat(
         "Compare=%.0f Opt=%.0f Stab=%.0f Conf=%.0f Adapt=%.0f Inst=%.0f | Best=%s | %s",
         r.comparison_score, r.optimization_score, r.parameter_stability,
         r.parameter_confidence, r.market_adaptability, r.institutional_score,
         r.best_profile, r.validation_status);
      r.valid = true;

      if(!m_exported || force)
        {
         m_export.Export(r);
         m_exported = true;
        }
      r.export_status = m_export.Status();
      r.queue_status = GM_EOL_Q_CACHED;

      m_last = r;
      m_db.Persist(r);
      m_queue.MarkCached();

      if(m_logger != NULL)
         m_logger.Info("Historical Ranking Updated | Top=" + r.best_profile, "EOL");
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = "Strategy Optimization Center";
      s.ai_engine = "GoldMind Enterprise Optimization Lab";
      s.current_mode = m_last.opt_paused ? "EOL_PAUSED" : "EOL_RESEARCH_ONLY";
      s.confidence_pct = m_last.institutional_score;
      s.confidence_status = StringFormat("%.0f", m_last.parameter_confidence);

      s.w_trend_detector = m_last.comparison_summary;                        // Comparison Results
      s.future_ai_score = StringFormat("%.0f", m_last.optimization_score);   // Optimization Score
      s.w_recovery_ai = StringFormat("%.0f", m_last.parameter_stability);    // Parameter Stability
      s.prediction_status = m_last.best_profile;                             // AI Recommendations
      s.learning_status = StringFormat("%.0f", m_last.historical_rank_top);  // Historical Ranking
      s.w_volatility_scanner = StringFormat("%.0f", m_last.market_adaptability); // Adaptability
      s.w_market_analyzer = m_last.validation_status;                        // Validation Status
      s.w_news_analyzer = GmEolQueueName(m_last.queue_status);                // Optimization Queue
      s.w_trade_confidence = StringFormat("Inst %.0f", m_last.institutional_score);
      s.ai_version = StringFormat("Safe=%s", m_last.safest_profile);
      s.decision_status = "RECOMMEND ONLY — USER APPROVAL REQUIRED";
      s.valid = true;
     }
  };

#endif // GM_CENTERPRISE_OPTIMIZATION_LAB_ENGINE_MQH
//+------------------------------------------------------------------+
