//+------------------------------------------------------------------+
//|                         CAIRecoveryIntelligenceEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 5 Sprint 4 — Recovery Intelligence Facade             |
//+------------------------------------------------------------------+
#ifndef GM_CAI_RECOVERY_INTELLIGENCE_ENGINE_MQH
#define GM_CAI_RECOVERY_INTELLIGENCE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "RecoveryIntelligenceConstants.mqh"
#include "SGmRecoveryIntelligenceResult.mqh"
#include "CAIRecoveryIntelligenceCore.mqh"
#include "CHedgeIntelligenceEngine.mqh"
#include "CLossMinimizationAnalyzer.mqh"
#include "CSecondAttemptAnalyzer.mqh"
#include "CRecoveryPatternEngine.mqh"
#include "CFutureRecoveryIntelligenceInterfaces.mqh"
#include "CRecoveryIntelligenceDatabase.mqh"
#include "CRecoveryIntelligenceScheduler.mqh"
#include "../Assistant/CAISupervisorEngine.mqh"
#include "../Trend/CAITrendEngine.mqh"
#include "../Volatility/CAIVolatilityEngine.mqh"
#include "../NewsIntelligence/CAINewsIntelligenceEngine.mqh"
#include "../../Analytics/CAnalyticsEngine.mqh"
#include "../../Recovery/CRecoveryBase.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../SGmAISnapshot.mqh"

class CGmAIRecoveryIntelligenceEngine
  {
private:
   CGmLogger             *m_logger;
   CGmPhase2Bridge       *m_bridge;
   CGmAnalyticsEngine    *m_analytics;
   CGmRecoveryBase       *m_recovery;
   CGmAISupervisorEngine *m_supervisor;
   CGmAITrendEngine      *m_trend;
   CGmAIVolatilityEngine *m_vol;
   CGmAINewsIntelligenceEngine *m_newsintel;

   CGmAIRecoveryIntelligenceCore      m_core;
   CGmHedgeIntelligenceEngine         m_hedge;
   CGmLossMinimizationAnalyzer        m_loss;
   CGmSecondAttemptAnalyzer           m_second;
   CGmRecoveryPatternEngine           m_pattern;
   CGmFutureRecoveryIntelligenceLayer m_future;
   CGmRecoveryIntelligenceDatabase    m_db;
   CGmRecoveryIntelligenceScheduler   m_sched;

   SGmRecoveryIntelligenceResult m_last;
   long                          m_magic;
   bool                          m_ready;

   string BuildRecommendation(const SGmRecoveryIntelligenceResult &r) const
     {
      string rec = "Observe recovery metrics; Gold Mind second-attempt logic remains authoritative.";
      if(r.recovery_health == GM_RI_HEALTH_CRITICAL)
         rec = "Recovery health critical — advisory focus on drawdown stability; do not mutate trades.";
      else if(r.recovery_health == GM_RI_HEALTH_WEAK)
         rec = "Weak recovery environment — monitor second-attempt stats and loss control closely.";
      else if(r.hedge_effectiveness >= 70.0 && r.loss_control_score >= 65.0)
         rec = "Hedge efficiency and loss control look constructive; continue observation only.";
      else if(r.primary_pattern == GM_RI_PAT_BEST)
         rec = "Best recovery conditions detected historically — intelligence only, no execution.";
      else if(r.primary_pattern == GM_RI_PAT_WORST)
         rec = "Worst recovery conditions pattern — elevate monitoring, never override strategy.";
      return rec + " | " + GM_RI_ADVISORY;
     }

public:
                     CGmAIRecoveryIntelligenceEngine(void)
                       : m_logger(NULL), m_bridge(NULL), m_analytics(NULL),
                         m_recovery(NULL), m_supervisor(NULL), m_trend(NULL),
                         m_vol(NULL), m_newsintel(NULL), m_magic(0), m_ready(false)
     {
      m_last.Reset();
     }

   bool Init(CGmLogger *logger,
             CGmFileManager *files,
             CGmPhase2Bridge *bridge,
             CGmAnalyticsEngine *analytics,
             CGmRecoveryBase *recovery,
             const long magic,
             const string symbol)
     {
      m_logger = logger;
      m_bridge = bridge;
      m_analytics = analytics;
      m_recovery = recovery;
      m_magic = magic;
      m_db.Init(logger, files, magic, symbol);
      m_sched.Reset();
      m_last.Reset();
      m_ready = true;
      if(m_logger != NULL)
        {
         m_logger.Success("Recovery Intelligence Started | " + GM_RI_VERSION +
                          " | " + GM_RI_ANALYSIS_ONLY, "AIRI");
         m_logger.Info("POLICY | " + GM_RI_ADVISORY, "AIRI");
         m_logger.Info("CONTEXT | " + GM_RI_GOLDMIND_CONTEXT, "AIRI");
         m_logger.Info(m_future.Banner(), "AIRI");
        }
      return true;
     }

   void BindSources(CGmAISupervisorEngine *supervisor,
                    CGmAITrendEngine *trend,
                    CGmAIVolatilityEngine *vol,
                    CGmAINewsIntelligenceEngine *newsintel)
     {
      m_supervisor = supervisor;
      m_trend = trend;
      m_vol = vol;
      m_newsintel = newsintel;
      if(m_logger != NULL)
         m_logger.Info("Recovery Intelligence sources bound | Supervisor+Trend+Vol+NewsIntel", "AIRI");
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmRecoveryIntelligenceResult Last(void) const { return m_last; }
   CGmFutureRecoveryIntelligenceLayer *FutureLayer(void) { return GetPointer(m_future); }

   bool Analyze(void)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      m_sched.Signal();
      if(!m_sched.ShouldRun(now, GM_RI_THROTTLE_MS))
        {
         if(m_last.valid && m_sched.CacheValid(now))
           {
            m_last.from_cache = true;
            m_last.status = GM_RI_STATUS_CACHED;
            return true;
           }
         return m_last.valid;
        }

      m_sched.Begin(now);

      SGmRecoveryIntelligenceResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.status = GM_RI_STATUS_RUNNING;
      r.may_execute = false;
      r.may_modify_risk = false;
      r.advisory_status = GM_RI_ADVISORY;

      if(m_bridge != NULL)
        {
         r.symbol = m_bridge.Symbol();
         r.session_id = m_bridge.SessionId();
        }
      if(StringLen(r.symbol) == 0)
        {
         r.status = GM_RI_STATUS_ERROR;
         m_sched.Complete(now);
         return false;
        }

      SGmAssistantResult sup;
      SGmAnalyticsSnapshot a;
      SGmTrendAnalysisResult trend;
      SGmVolatilityAnalysisResult vol;
      SGmNewsIntelligenceResult ni;
      sup.Reset();
      a.Reset();
      trend.Reset(); vol.Reset(); ni.Reset();

      if(m_supervisor != NULL && m_supervisor.IsReady())
         sup = m_supervisor.Last();
      if(m_analytics != NULL)
         a = m_analytics.Snapshot();
      if(m_trend != NULL && m_trend.IsReady())
         trend = m_trend.Last();
      if(m_vol != NULL && m_vol.IsReady())
         vol = m_vol.Last();
      if(m_newsintel != NULL && m_newsintel.IsReady())
         ni = m_newsintel.Last();

      m_core.Analyze(sup, a, m_recovery, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Recovery Analysis Updated | Score=%.0f Health=%s",
                                    r.recovery_intelligence_score,
                                    GmRiHealthName(r.recovery_health)), "AIRI");

      m_hedge.Analyze(sup, a, r, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Hedge Analysis Completed | Eff=%.0f",
                                    r.hedge_effectiveness), "AIRI");

      m_loss.Analyze(sup, a, r, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Loss Statistics Updated | Ctrl=%.0f Cap=%.0f",
                                    r.loss_control_score, r.capital_protection_rating), "AIRI");

      m_second.Analyze(a, r, r);
      m_pattern.Analyze(trend, vol, ni, r, r);
      if(m_logger != NULL)
         m_logger.Info("Recovery Pattern Generated | " + GmRiPatternName(r.primary_pattern), "AIRI");

      r.ai_recovery_recommendation = BuildRecommendation(r);
      r.center_status = "RECOVERY INTEL READY";
      r.status = GM_RI_STATUS_READY;
      r.insight = StringFormat("%s | Score=%.0f Success=%.0f Hedge=%.0f LossCtrl=%.0f | %s",
                               r.center_status,
                               r.recovery_intelligence_score,
                               r.recovery_success_rate,
                               r.hedge_effectiveness,
                               r.loss_control_score,
                               GM_RI_ADVISORY);
      r.valid = true;

      m_db.Record(r);
      m_last = r;
      m_sched.Complete(GetTickCount());

      if(m_logger != NULL)
         m_logger.Info("Dashboard Updated | Recovery Intelligence pending=" +
                       IntegerToString(m_sched.Pending()), "AIRI");
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = StringFormat("%s | %.0f", m_last.center_status,
                                 m_last.recovery_intelligence_score);
      s.ai_engine = "GoldMind AI Recovery Intelligence";
      s.current_mode = "AI_RECOVERY_INTEL";
      s.confidence_pct = m_last.recovery_confidence;
      s.confidence_status = StringFormat("%.0f", m_last.recovery_confidence);

      // Phase 5 Sprint 4 widgets (last-wins)
      s.w_trend_detector = StringFormat("%s (%.0f)",
                                        GmRiHealthName(m_last.recovery_health),
                                        m_last.recovery_health_index);           // Recovery Health
      s.future_ai_score = StringFormat("%.0f%%", m_last.recovery_success_rate);  // Recovery Success %
      s.w_recovery_ai = StringFormat("%.0f", m_last.hedge_effectiveness);        // Hedge Efficiency
      s.prediction_status = StringFormat("%.0f", m_last.loss_control_score);     // Loss Control Score
      s.learning_status = StringFormat("%.0f", m_last.capital_protection_rating); // Capital Protection
      s.w_volatility_scanner = StringFormat("2nd=%.0f%% Fail=%.0f%%",
                                            m_last.second_attempt_success,
                                            m_last.final_failure_rate);          // Second Attempt Stats
      s.w_market_analyzer = GmRiPatternName(m_last.primary_pattern);             // Recovery Pattern
      s.w_news_analyzer = StringFormat("%.0f%%", m_last.historical_recovery_pct); // Historical Recovery
      s.w_trade_confidence = StringFormat("%.0f", m_last.recovery_confidence);   // Recovery Confidence
      s.ai_version = m_last.ai_recovery_recommendation;                          // AI Recovery Recommendation
      s.decision_status = GM_RI_ADVISORY;
     }
  };

#endif // GM_CAI_RECOVERY_INTELLIGENCE_ENGINE_MQH
//+------------------------------------------------------------------+
