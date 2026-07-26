//+------------------------------------------------------------------+
//|                            CAIRiskIntelligenceEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 4 Sprint 7 — Risk Intelligence Facade                 |
//+------------------------------------------------------------------+
#ifndef GM_CAI_RISK_INTELLIGENCE_ENGINE_MQH
#define GM_CAI_RISK_INTELLIGENCE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "RiskIntelligenceConstants.mqh"
#include "SGmRiskIntelligenceResult.mqh"
#include "CAdvancedCapitalProtectionEngine.mqh"
#include "CPredictiveRiskAnalysisEngine.mqh"
#include "CExposureIntelligenceEngine.mqh"
#include "CDrawdownIntelligenceAnalyzer.mqh"
#include "CMarginSafetyMonitor.mqh"
#include "CAIRiskAlertFramework.mqh"
#include "CRiskIntelligenceDatabase.mqh"
#include "CRiskIntelligenceScheduler.mqh"
#include "../Assistant/CAISupervisorEngine.mqh"
#include "../Intelligence/CAIDecisionIntelligenceEngine.mqh"
#include "../Enterprise/CAIEnterpriseMonitoringEngine.mqh"
#include "../../Analytics/CAnalyticsEngine.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../SGmAISnapshot.mqh"

class CGmAIRiskIntelligenceEngine
  {
private:
   CGmLogger             *m_logger;
   CGmPhase2Bridge       *m_bridge;
   CGmAnalyticsEngine    *m_analytics;
   CGmAISupervisorEngine *m_supervisor;
   CGmAIDecisionIntelligenceEngine *m_intel;
   CGmAIEnterpriseMonitoringEngine *m_entmon;

   CGmAdvancedCapitalProtectionEngine m_capital;
   CGmPredictiveRiskAnalysisEngine    m_predict;
   CGmExposureIntelligenceEngine      m_exposure;
   CGmDrawdownIntelligenceAnalyzer    m_drawdown;
   CGmMarginSafetyMonitor             m_margin;
   CGmAIRiskAlertFramework            m_alerts;
   CGmRiskIntelligenceDatabase        m_db;
   CGmRiskIntelligenceScheduler       m_sched;

   SGmRiskIntelligenceResult m_last;
   long                      m_magic;
   bool                      m_ready;

public:
                     CGmAIRiskIntelligenceEngine(void)
                       : m_logger(NULL), m_bridge(NULL), m_analytics(NULL),
                         m_supervisor(NULL), m_intel(NULL), m_entmon(NULL),
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
         m_logger.Success("Risk Intelligence Started | " + GM_RISKINT_VERSION +
                          " | " + GM_RISKINT_ANALYSIS_ONLY, "AIRisk");
         m_logger.Info("POLICY | " + GM_RISKINT_ADVISORY, "AIRisk");
        }
      return true;
     }

   void BindSources(CGmAISupervisorEngine *supervisor,
                    CGmAIDecisionIntelligenceEngine *intel,
                    CGmAIEnterpriseMonitoringEngine *entmon = NULL)
     {
      m_supervisor = supervisor;
      m_intel = intel;
      m_entmon = entmon;
      if(m_logger != NULL)
         m_logger.Info("Risk Intelligence sources bound | Supervisor+Intel+Enterprise",
                       "AIRisk");
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmRiskIntelligenceResult Last(void) const { return m_last; }

   bool Analyze(void)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      m_sched.Signal();
      if(!m_sched.ShouldRun(now, GM_RISKINT_THROTTLE_MS))
        {
         if(m_last.valid && m_sched.CacheValid(now))
           {
            m_last.from_cache = true;
            m_last.status = GM_RISKINT_STATUS_CACHED;
            return true;
           }
         return m_last.valid;
        }

      m_sched.Begin(now);

      SGmRiskIntelligenceResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.status = GM_RISKINT_STATUS_RUNNING;
      r.may_execute = false;
      r.may_modify_risk = false;
      r.advisory_status = GM_RISKINT_ADVISORY;
      r.account_id = IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN));

      if(m_bridge != NULL)
        {
         r.symbol = m_bridge.Symbol();
         r.session_id = m_bridge.SessionId();
        }
      if(StringLen(r.symbol) == 0)
        {
         r.status = GM_RISKINT_STATUS_ERROR;
         m_sched.Complete(now);
         return false;
        }

      SGmAssistantResult sup;
      SGmIntelligenceResult intel;
      SGmAnalyticsSnapshot an;
      sup.Reset();
      intel.Reset();
      an.Reset();
      if(m_supervisor != NULL && m_supervisor.IsReady())
         sup = m_supervisor.Last();
      if(m_intel != NULL && m_intel.IsReady())
         intel = m_intel.Last();
      if(m_analytics != NULL)
         an = m_analytics.Snapshot();

      m_drawdown.Analyze(sup, an, r);
      if(m_logger != NULL)
         m_logger.Info("Drawdown Report Generated | " + r.dd_range_status, "AIRisk");

      m_capital.Analyze(sup, an, r);
      if(m_logger != NULL)
         m_logger.Info("Capital Analysis Completed | " + GmCapStatusName(r.capital_status),
                       "AIRisk");

      m_exposure.Analyze(sup, intel, an, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Exposure Analysis Updated | %.0f/100 %s",
                                    r.exposure_score, r.exposure_status), "AIRisk");

      m_margin.Analyze(sup, r);
      if(m_logger != NULL)
         m_logger.Info("Margin Safety Checked | " + GmMarginGradeName(r.margin_grade),
                       "AIRisk");

      m_predict.Analyze(sup, intel, r, r);

      m_alerts.Analyze(sup, r);
      if(m_logger != NULL && r.alert_count > 0)
         m_logger.Info("Risk Alert Created | " + r.alert_summary, "AIRisk");

      r.confidence = GmRiskIntClamp(
                        0.35 * r.capital_protection_score +
                        0.25 * r.exposure_score +
                        0.20 * (100.0 - r.risk_probability) +
                        0.20 * (r.margin_grade == GM_MARGIN_GRADE_A ? 100.0
                                : (r.margin_grade == GM_MARGIN_GRADE_B ? 85.0
                                : (r.margin_grade == GM_MARGIN_GRADE_C ? 65.0
                                : (r.margin_grade == GM_MARGIN_GRADE_D ? 40.0 : 20.0)))));

      if(m_entmon != NULL && m_entmon.IsReady() && m_entmon.Last().valid)
         r.confidence = GmRiskIntClamp(0.88 * r.confidence +
                                       0.12 * m_entmon.Last().fleet_health_score);

      r.center_status = "RISK CENTER READY";
      r.status = GM_RISKINT_STATUS_READY;
      r.insight = StringFormat("%s | Cap=%.0f Pred=%.0f%% Exp=%.0f Margin=%s Alerts=%d | %s",
                               r.center_status,
                               r.capital_protection_score,
                               r.risk_probability,
                               r.exposure_score,
                               GmMarginGradeName(r.margin_grade),
                               r.alert_count,
                               GM_RISKINT_ANALYSIS_ONLY);
      r.valid = true;

      m_db.Record(r);
      m_last = r;
      m_sched.Complete(GetTickCount());

      if(m_logger != NULL)
         m_logger.Info("Risk Dashboard Updated | pending=" +
                       IntegerToString(m_sched.Pending()), "AIRisk");
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = m_last.center_status;
      s.ai_engine = "GoldMind AI Risk Intelligence Center";
      s.current_mode = "AI_RISK_CENTER";
      s.confidence_pct = m_last.confidence;
      s.confidence_status = StringFormat("%.0f", m_last.confidence);

      // AI Risk Intelligence Center widgets (last-wins)
      s.w_trend_detector = StringFormat("%.0f | %s",
                                        m_last.capital_protection_score,
                                        GmCapStatusName(m_last.capital_status)); // Capital Protection
      s.future_ai_score = StringFormat("%.0f%% | %s",
                                       m_last.risk_probability,
                                       GmRiskLevelName(m_last.risk_level));      // Predictive Risk
      s.w_recovery_ai = StringFormat("%.0f/100 | %s",
                                     m_last.exposure_score,
                                     m_last.exposure_status);                    // Exposure Health
      s.prediction_status = StringFormat("%s | Rec=%s",
                                         m_last.dd_range_status,
                                         m_last.recovery_probability);           // Drawdown Analysis
      s.learning_status = GmMarginGradeName(m_last.margin_grade);                // Margin Safety
      s.w_volatility_scanner = m_last.risk_trend;                                // Risk Trend
      s.w_market_analyzer = m_last.recovery_pressure;                            // Recovery Pressure
      s.w_news_analyzer = m_last.historical_comparison;                          // Historical Risk Comparison
      s.w_trade_confidence = m_last.risk_explanation;                            // AI Risk Explanation
      s.ai_version = m_last.alert_summary;
      s.decision_status = GM_RISKINT_ADVISORY;
     }
  };

#endif // GM_CAI_RISK_INTELLIGENCE_ENGINE_MQH
//+------------------------------------------------------------------+
