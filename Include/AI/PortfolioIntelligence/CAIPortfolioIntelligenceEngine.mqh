//+------------------------------------------------------------------+
//|                         CAIPortfolioIntelligenceEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 5 Sprint 6 — Portfolio Intelligence Facade            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_PORTFOLIO_INTELLIGENCE_ENGINE_MQH
#define GM_CAI_PORTFOLIO_INTELLIGENCE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "PortfolioIntelligenceConstants.mqh"
#include "SGmPortfolioIntelligenceResult.mqh"
#include "CMultiSymbolFramework.mqh"
#include "CAIPortfolioIntelligenceCore.mqh"
#include "CPortfolioCorrelationEngine.mqh"
#include "CCapitalAllocationAnalyzer.mqh"
#include "CPortfolioRiskEngine.mqh"
#include "CFuturePortfolioIntelligenceInterfaces.mqh"
#include "CPortfolioIntelligenceDatabase.mqh"
#include "CPortfolioIntelligenceScheduler.mqh"
#include "../Assistant/CAISupervisorEngine.mqh"
#include "../Trend/CAITrendEngine.mqh"
#include "../OrderFlow/CAIOrderFlowIntelligenceEngine.mqh"
#include "../RecoveryIntelligence/CAIRecoveryIntelligenceEngine.mqh"
#include "../RiskIntelligence/CAIRiskIntelligenceEngine.mqh"
#include "../Enterprise/CAIEnterpriseMonitoringEngine.mqh"
#include "../../Analytics/CAnalyticsEngine.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../SGmAISnapshot.mqh"

class CGmAIPortfolioIntelligenceEngine
  {
private:
   CGmLogger             *m_logger;
   CGmPhase2Bridge       *m_bridge;
   CGmAnalyticsEngine    *m_analytics;
   CGmAISupervisorEngine *m_supervisor;
   CGmAITrendEngine      *m_trend;
   CGmAIOrderFlowIntelligenceEngine *m_orderflow;
   CGmAIRecoveryIntelligenceEngine *m_recintel;
   CGmAIRiskIntelligenceEngine *m_riskintel;
   CGmAIEnterpriseMonitoringEngine *m_entmon;

   CGmMultiSymbolFramework              m_symbols;
   CGmAIPortfolioIntelligenceCore       m_core;
   CGmPortfolioCorrelationEngine        m_corr;
   CGmCapitalAllocationAnalyzer         m_capital;
   CGmPortfolioRiskEngine               m_risk;
   CGmFuturePortfolioIntelligenceLayer  m_future;
   CGmPortfolioIntelligenceDatabase     m_db;
   CGmPortfolioIntelligenceScheduler    m_sched;

   SGmPortfolioIntelligenceResult m_last;
   long                           m_magic;
   bool                           m_ready;

   string BuildRecommendation(const SGmPortfolioIntelligenceResult &r) const
     {
      string rec = "Supervise XAUUSD portfolio health; additional symbols remain DISABLED.";
      if(r.health_class == GM_PI_HEALTH_CRITICAL)
         rec = "Portfolio health critical — advisory monitoring only; never mutate trades or enable symbols.";
      else if(r.portfolio_risk_score >= 70.0)
         rec = "Elevated portfolio risk — review exposure and margin; execution authority remains Core only.";
      else if(r.capital_efficiency_score >= 70.0 && r.portfolio_stability_score >= 65.0)
         rec = "Capital efficiency and stability look constructive under XAUUSD-only policy.";
      else if(r.diversification_score < 30.0)
         rec = "Single-symbol concentration expected (XAUUSD ONLY); multi-symbol remains architectural.";
      return rec + " | " + GM_PI_ADVISORY;
     }

public:
                     CGmAIPortfolioIntelligenceEngine(void)
                       : m_logger(NULL), m_bridge(NULL), m_analytics(NULL),
                         m_supervisor(NULL), m_trend(NULL), m_orderflow(NULL),
                         m_recintel(NULL), m_riskintel(NULL), m_entmon(NULL),
                         m_magic(0), m_ready(false)
     {
      m_last.Reset();
     }

   bool Init(CGmLogger *logger,
             CGmFileManager *files,
             CGmPhase2Bridge *bridge,
             CGmAnalyticsEngine *analytics,
             const long magic,
             const string symbol)
     {
      m_logger = logger;
      m_bridge = bridge;
      m_analytics = analytics;
      m_magic = magic;
      m_db.Init(logger, files, magic, symbol);
      m_sched.Reset();
      m_last.Reset();
      m_ready = true;
      if(m_logger != NULL)
        {
         m_logger.Success("Portfolio Intelligence Started | " + GM_PI_VERSION +
                          " | " + GM_PI_ANALYSIS_ONLY, "AIPI");
         m_logger.Info("POLICY | " + GM_PI_ADVISORY, "AIPI");
         m_logger.Info("LIVE SYMBOL | " + GM_PI_LIVE_SYMBOL + " ONLY", "AIPI");
         m_logger.Info(m_future.Banner(), "AIPI");
        }
      return true;
     }

   void BindSources(CGmAISupervisorEngine *supervisor,
                    CGmAITrendEngine *trend,
                    CGmAIOrderFlowIntelligenceEngine *orderflow,
                    CGmAIRecoveryIntelligenceEngine *recintel,
                    CGmAIRiskIntelligenceEngine *riskintel,
                    CGmAIEnterpriseMonitoringEngine *entmon)
     {
      m_supervisor = supervisor;
      m_trend = trend;
      m_orderflow = orderflow;
      m_recintel = recintel;
      m_riskintel = riskintel;
      m_entmon = entmon;
      if(m_logger != NULL)
         m_logger.Info("Portfolio sources bound | Supervisor+Trend+OF+Rec+Risk+Enterprise", "AIPI");
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmPortfolioIntelligenceResult Last(void) const { return m_last; }
   CGmFuturePortfolioIntelligenceLayer *FutureLayer(void) { return GetPointer(m_future); }

   bool Analyze(void)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      m_sched.Signal();
      if(!m_sched.ShouldRun(now, GM_PI_THROTTLE_MS))
        {
         if(m_last.valid && m_sched.CacheValid(now))
           {
            m_last.from_cache = true;
            m_last.status = GM_PI_STATUS_CACHED;
            return true;
           }
         return m_last.valid;
        }

      m_sched.Begin(now);

      SGmPortfolioIntelligenceResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.status = GM_PI_STATUS_RUNNING;
      r.may_execute = false;
      r.may_enable_symbols = false;
      r.advisory_status = GM_PI_ADVISORY;

      if(m_bridge != NULL)
        {
         r.symbol = m_bridge.Symbol();
         r.session_id = m_bridge.SessionId();
        }
      if(StringLen(r.symbol) == 0)
        {
         r.status = GM_PI_STATUS_ERROR;
         m_sched.Complete(now);
         return false;
        }

      SGmAssistantResult sup;
      SGmAnalyticsSnapshot a;
      SGmTrendAnalysisResult trend;
      SGmOrderFlowResult of;
      SGmRecoveryIntelligenceResult ri;
      SGmRiskIntelligenceResult risk;
      SGmEnterpriseResult ent;
      sup.Reset(); a.Reset(); trend.Reset(); of.Reset();
      ri.Reset(); risk.Reset(); ent.Reset();

      if(m_supervisor != NULL && m_supervisor.IsReady())
         sup = m_supervisor.Last();
      if(m_analytics != NULL)
         a = m_analytics.Snapshot();
      if(m_trend != NULL && m_trend.IsReady())
         trend = m_trend.Last();
      if(m_orderflow != NULL && m_orderflow.IsReady())
         of = m_orderflow.Last();
      if(m_recintel != NULL && m_recintel.IsReady())
         ri = m_recintel.Last();
      if(m_riskintel != NULL && m_riskintel.IsReady())
         risk = m_riskintel.Last();
      if(m_entmon != NULL && m_entmon.IsReady())
         ent = m_entmon.Last();

      m_symbols.Build(r.symbol, r);
      m_core.Analyze(sup, a, ri, ent, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Portfolio Updated | Score=%.0f Health=%s",
                                    r.portfolio_intelligence_score,
                                    GmPiHealthName(r.health_class)), "AIPI");

      m_capital.Analyze(sup, a, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Capital Analysis Updated | Eff=%.0f",
                                    r.capital_efficiency_score), "AIPI");

      m_corr.Analyze(trend, of, r, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Correlation Calculated | Div=%.0f",
                                    r.diversification_score), "AIPI");

      m_risk.Analyze(sup, a, risk, ri, r, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Exposure Updated | Risk=%.0f",
                                    r.portfolio_risk_score), "AIPI");

      r.ai_portfolio_recommendation = BuildRecommendation(r);
      r.center_status = "PORTFOLIO INTEL READY";
      r.status = GM_PI_STATUS_READY;
      r.insight = StringFormat("%s | Live=%s Score=%.0f Health=%.0f Risk=%.0f Eff=%.0f | %s",
                               r.center_status, r.live_symbol,
                               r.portfolio_intelligence_score, r.portfolio_health_index,
                               r.portfolio_risk_score, r.capital_efficiency_score,
                               GM_PI_ADVISORY);
      r.valid = true;

      m_db.Record(r);
      m_last = r;
      m_sched.Complete(GetTickCount());

      if(m_logger != NULL)
         m_logger.Info("Dashboard Refreshed | Portfolio pending=" +
                       IntegerToString(m_sched.Pending()), "AIPI");
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = m_last.center_status;
      s.ai_engine = "GoldMind AI Portfolio Intelligence";
      s.current_mode = "AI_PORTFOLIO_INTEL";
      s.confidence_pct = GmPiClamp(0.4 * m_last.portfolio_intelligence_score +
                                   0.3 * m_last.capital_efficiency_score +
                                   0.3 * m_last.portfolio_stability_score);
      s.confidence_status = StringFormat("%.0f", s.confidence_pct);

      // Phase 5 Sprint 6 widgets (last-wins)
      s.w_trend_detector = StringFormat("%s (%.0f)",
                                        GmPiHealthName(m_last.health_class),
                                        m_last.portfolio_health_index);          // Portfolio Health
      s.future_ai_score = StringFormat("%.0f", m_last.portfolio_intelligence_score); // Portfolio Intelligence
      s.w_recovery_ai = StringFormat("%.0f", m_last.capital_efficiency_score);   // Capital Efficiency
      s.prediction_status = StringFormat("%.0f", m_last.portfolio_risk_score);   // Portfolio Risk
      s.learning_status = StringFormat("%.0f", m_last.diversification_score);    // Diversification
      s.w_volatility_scanner = StringFormat("Port=%.0f Mkt=%.0f",
                                            m_last.portfolio_correlation,
                                            m_last.market_correlation);          // Correlation Matrix
      s.w_market_analyzer = StringFormat("D=%.2f%% W=%.2f%%",
                                         m_last.daily_growth, m_last.weekly_growth); // Growth Stats
      s.w_news_analyzer = StringFormat("T=%.0f L=%.0f S=%.0f R=%.0f",
                                       m_last.total_exposure, m_last.long_exposure,
                                       m_last.short_exposure, m_last.recovery_exposure); // Exposure
      s.w_trade_confidence = StringFormat("%.0f", m_last.portfolio_stability_score); // Stability
      s.ai_version = m_last.ai_portfolio_recommendation;                         // Recommendation
      s.decision_status = GM_PI_ADVISORY;
     }
  };

#endif // GM_CAI_PORTFOLIO_INTELLIGENCE_ENGINE_MQH
//+------------------------------------------------------------------+
