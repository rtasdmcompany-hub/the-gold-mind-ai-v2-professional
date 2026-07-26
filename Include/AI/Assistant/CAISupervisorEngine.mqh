//+------------------------------------------------------------------+
//|                                       CAISupervisorEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     Phase 4 Sprint 1 — Enterprise AI Supervisor (NON-EXECUTION) |
//+------------------------------------------------------------------+
#ifndef GM_CAI_SUPERVISOR_ENGINE_MQH
#define GM_CAI_SUPERVISOR_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "AssistantAIConstants.mqh"
#include "SGmAssistantResult.mqh"
#include "CCapitalProtectionAnalyzer.mqh"
#include "CTradeEnvironmentMonitor.mqh"
#include "CSmartWarningEngine.mqh"
#include "CSystemHealthSupervisor.mqh"
#include "CSupervisorDatabase.mqh"
#include "CFutureEnterpriseInterfaces.mqh"
#include "../Trend/CAITrendEngine.mqh"
#include "../Volatility/CAIVolatilityEngine.mqh"
#include "../News/CAINewsEngine.mqh"
#include "../Confidence/CAIConfidenceEngine.mqh"
#include "../Learning/CAILearningEngine.mqh"
#include "../AIValidation/CAIValidationEngine.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Analytics/CAnalyticsEngine.mqh"
#include "../../Recovery/CRecoveryBase.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../SGmAISnapshot.mqh"

/// @file CAISupervisorEngine.mqh
/// @brief Enterprise AI Assistant Supervisor — observes Core/AI stack, never mutates.

class CGmAISupervisorEngine
  {
private:
   CGmLogger                 *m_logger;
   CGmPhase2Bridge           *m_bridge;
   CGmAnalyticsEngine        *m_analytics;
   CGmRecoveryBase           *m_recovery;
   CGmAITrendEngine          *m_trend;
   CGmAIVolatilityEngine     *m_vol;
   CGmAINewsEngine           *m_news;
   CGmAIConfidenceEngine     *m_conf;
   CGmAILearningEngine       *m_learn;
   CGmAIValidationEngine     *m_aival;
   bool                       m_dashboard_ok;

   CGmCapitalProtectionAnalyzer m_capital;
   CGmTradeEnvironmentMonitor   m_env;
   CGmSmartWarningEngine        m_warn;
   CGmSystemHealthSupervisor    m_health;
   CGmSupervisorDatabase        m_db;
   CGmFutureEnterpriseLayer     m_enterprise;

   SGmAssistantResult        m_last;
   long                      m_magic;
   ulong                     m_last_ms;
   bool                      m_ready;

public:
                     CGmAISupervisorEngine(void)
                       : m_logger(NULL), m_bridge(NULL), m_analytics(NULL),
                         m_recovery(NULL), m_trend(NULL), m_vol(NULL), m_news(NULL),
                         m_conf(NULL), m_learn(NULL), m_aival(NULL),
                         m_dashboard_ok(true), m_magic(0), m_last_ms(0), m_ready(false)
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
      m_last.Reset();
      m_last_ms = 0;
      m_ready = true;
      if(m_logger != NULL)
        {
         m_logger.Success("Supervisor Started | " + GM_ASSIST_VERSION +
                          " | " + GM_ASSIST_ANALYSIS_ONLY, "AISup");
         m_logger.Info("POLICY | " + GM_ASSIST_ADVISORY +
                       " | Core Trading remains sole execution authority", "AISup");
         m_logger.Info(m_enterprise.Banner(), "AISup");
        }
      return true;
     }

   void BindSources(CGmAITrendEngine *trend,
                    CGmAIVolatilityEngine *vol,
                    CGmAINewsEngine *news,
                    CGmAIConfidenceEngine *conf,
                    CGmAILearningEngine *learn,
                    CGmAIValidationEngine *aival)
     {
      m_trend = trend;
      m_vol = vol;
      m_news = news;
      m_conf = conf;
      m_learn = learn;
      m_aival = aival;
      if(m_logger != NULL)
         m_logger.Info("Supervisor sources bound | Trend+Vol+News+Conf+Learn+Validation",
                       "AISup");
     }

   void SetDashboardOk(const bool ok) { m_dashboard_ok = ok; }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmAssistantResult Last(void) const { return m_last; }
   CGmFutureEnterpriseLayer *EnterpriseLayer(void) const
     {
      return (CGmFutureEnterpriseLayer*)GetPointer(m_enterprise);
     }

   bool Analyze(void)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_ASSIST_THROTTLE_MS && m_last.valid)
         return true;
      m_last_ms = now;

      SGmAssistantResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.status = GM_ASSIST_STATUS_RUNNING;
      r.may_execute = false;
      r.may_modify_risk = false;
      r.advisory_status = GM_ASSIST_ADVISORY;

      if(m_bridge != NULL)
        {
         r.symbol = m_bridge.Symbol();
         r.session_id = m_bridge.SessionId();
        }
      if(StringLen(r.symbol) == 0)
        {
         r.status = GM_ASSIST_STATUS_ERROR;
         if(m_logger != NULL)
            m_logger.Warning("Supervisor aborted | no symbol", "AISup");
         return false;
        }

      SGmTrendAnalysisResult trend;
      SGmVolatilityAnalysisResult vol;
      SGmNewsAnalysisResult news;
      SGmConfidenceAnalysisResult conf;
      SGmLearningAnalysisResult learn;
      trend.Reset(); vol.Reset(); news.Reset(); conf.Reset(); learn.Reset();
      if(m_trend != NULL && m_trend.IsReady()) trend = m_trend.Last();
      if(m_vol != NULL && m_vol.IsReady()) vol = m_vol.Last();
      if(m_news != NULL && m_news.IsReady()) news = m_news.Last();
      if(m_conf != NULL && m_conf.IsReady()) conf = m_conf.Last();
      if(m_learn != NULL && m_learn.IsReady()) learn = m_learn.Last();

      m_capital.Analyze(m_bridge, m_analytics, m_recovery, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Capital Protection Updated | score=%.0f dd=%.1f%%",
                                    r.capital_protection_score, r.current_dd_pct), "AISup");

      m_env.Analyze(m_bridge, trend, vol, news, conf, learn, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Environment Updated | grade=%s score=%.0f",
                                    GmEnvGradeName(r.environment_grade),
                                    r.environment_score), "AISup");

      m_health.Analyze(m_bridge, m_analytics, m_learn, m_aival, m_dashboard_ok, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Health Updated | system=%.0f ea=%.0f",
                                    r.system_health_score, r.ea_health), "AISup");

      m_warn.Analyze(trend, vol, news, conf, r);
      if(r.warning_count > 0 && m_logger != NULL)
         m_logger.Warning("Warning Generated | " + r.warning_center, "AISup");

      r.overall_health_score = GmAssistClamp(
                                  0.35 * r.capital_protection_score +
                                  0.30 * r.environment_score +
                                  0.25 * r.system_health_score +
                                  0.10 * (r.warning_count == 0 ? 100.0
                                                               : GmAssistClamp(100.0 - r.warning_count * 8.0)));

      r.supervisor_status = (r.warning_count > 0) ? "SUPERVISING+WARN" : "SUPERVISING";
      r.status = (r.warning_count > 0) ? GM_ASSIST_STATUS_WARNING : GM_ASSIST_STATUS_READY;
      r.insight = StringFormat("%s | cap=%.0f env=%s health=%.0f overall=%.0f | %s | %s",
                               r.supervisor_status,
                               r.capital_protection_score,
                               GmEnvGradeName(r.environment_grade),
                               r.system_health_score,
                               r.overall_health_score,
                               r.warning_center,
                               GM_ASSIST_ANALYSIS_ONLY);
      r.valid = true;

      m_db.Record(r);
      m_last = r;

      if(m_logger != NULL)
        {
         m_logger.Info("Dashboard Updated | Supervisor widgets", "AISup");
         m_logger.Debug(StringFormat("Performance | warn=%d mem=%I64uMB ping=%d",
                                     r.warning_count, r.memory_used_mb, r.terminal_ping_ms),
                        "AISup");
        }
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = m_last.supervisor_status;
      s.ai_engine = "GoldMind AI Supervisor";
      s.current_mode = "AI_SUPERVISOR";
      s.confidence_pct = m_last.overall_health_score;
      s.confidence_status = StringFormat("%.0f%%", m_last.capital_protection_score);

      // Sprint 1 widget pack (last-wins over Validation)
      s.w_trend_detector = StringFormat("%.0f", m_last.capital_protection_score); // Capital Protection
      s.future_ai_score = StringFormat("Grade %s", GmEnvGradeName(m_last.environment_grade));
      s.w_recovery_ai = StringFormat("%.1f%%", m_last.risk_exposure_pct);         // Risk Exposure
      s.prediction_status = StringFormat("%.0f", m_last.system_health_score);     // System Health
      s.learning_status = m_last.supervisor_status;                               // AI Supervisor Status
      s.w_volatility_scanner = m_last.warning_center;                             // Warning Center
      s.w_market_analyzer = m_last.market_health;                                 // Market Health
      s.w_news_analyzer = m_last.recovery_status;                                 // Recovery Status
      s.w_trade_confidence = m_last.advisory_status;                              // AI Advisory Status
      s.ai_version = StringFormat("%.0f", m_last.overall_health_score);           // Overall Health
      s.decision_status = GM_ASSIST_ADVISORY;
      if(m_last.atr_environment > 0.0 && m_vol != NULL && m_vol.IsReady() && m_vol.Last().valid)
         s.atr14 = m_vol.Last().atr14;
     }
  };

#endif // GM_CAI_SUPERVISOR_ENGINE_MQH
//+------------------------------------------------------------------+
