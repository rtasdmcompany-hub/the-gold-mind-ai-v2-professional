//+------------------------------------------------------------------+
//|                                    CPhase5AIModuleAuditor.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 5 Sprint 10 — Full AI Market Intelligence Audit       |
//+------------------------------------------------------------------+
#ifndef GM_CPHASE5_AI_MODULE_AUDITOR_MQH
#define GM_CPHASE5_AI_MODULE_AUDITOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "Phase5ClosureConstants.mqh"
#include "../AI/Core/CAICoreEngine.mqh"
#include "../Logging/CLogger.mqh"

class CGmPhase5AIModuleAuditor
  {
private:
   CGmLogger *m_logger;
   int        m_pass;
   int        m_fail;
   int        m_total;
   string     m_lines;

   void Check(const string name, const bool ok)
     {
      m_total++;
      if(ok)
        {
         m_pass++;
         m_lines += "PASS | " + name + "\r\n";
        }
      else
        {
         m_fail++;
         m_lines += "FAIL | " + name + "\r\n";
         if(m_logger != NULL)
            m_logger.Warning("Phase5 AI Audit FAIL | " + name, "P5Audit");
        }
     }

public:
                     CGmPhase5AIModuleAuditor(void)
                       : m_logger(NULL), m_pass(0), m_fail(0), m_total(0), m_lines("") {}

   void Init(CGmLogger *logger) { m_logger = logger; }

   int Pass(void) const { return m_pass; }
   int Fail(void) const { return m_fail; }
   int Total(void) const { return m_total; }
   string Body(void) const { return m_lines; }

   double Score(void) const
     {
      return (m_total > 0) ? (100.0 * (double)m_pass / (double)m_total) : 0.0;
     }

   void Audit(CGmAICoreEngine *core)
     {
      m_pass = m_fail = m_total = 0;
      m_lines = "=== PHASE 5 AI MODULE AUDIT ===\r\n";

      const bool core_ok = (core != NULL && core.IsReady());
      Check("AI Core Engine", core_ok);

      // Phase 3 foundation
      Check("Market Analysis Engine",
            core_ok && core.MarketAnalyzer() != NULL && core.MarketAnalyzer().IsReady());
      Check("Trend Detection Engine",
            core_ok && core.TrendEngine() != NULL && core.TrendEngine().IsReady());
      Check("ATR / Volatility Engine",
            core_ok && core.VolatilityEngine() != NULL && core.VolatilityEngine().IsReady());
      Check("News Analysis Engine (Phase3)",
            core_ok && core.NewsEngine() != NULL && core.NewsEngine().IsReady());
      Check("Confidence Engine",
            core_ok && core.ConfidenceEngine() != NULL && core.ConfidenceEngine().IsReady());
      Check("Learning Engine (Phase3)",
            core_ok && core.LearningEngine() != NULL && core.LearningEngine().IsReady());
      Check("Decision / XAI Engine",
            core_ok && core.DecisionSupportEngine() != NULL && core.DecisionSupportEngine().IsReady());
      Check("AI Validation Engine",
            core_ok && core.AIValidationEngine() != NULL && core.AIValidationEngine().IsReady());

      // Phase 4 assistant stack (subset for Phase5 certification continuity)
      Check("AI Supervisor / Assistant",
            core_ok && core.SupervisorEngine() != NULL && core.SupervisorEngine().IsReady());
      Check("Decision Intelligence",
            core_ok && core.DecisionIntelligenceEngine() != NULL && core.DecisionIntelligenceEngine().IsReady());
      Check("Learning Memory",
            core_ok && core.LearningMemoryEngine() != NULL && core.LearningMemoryEngine().IsReady());
      Check("Master Control",
            core_ok && core.MasterControlEngine() != NULL && core.MasterControlEngine().IsReady());

      // Phase 5 Market Intelligence Platform
      Check("Market Intelligence Engine",
            core_ok && core.MarketIntelligenceEngine() != NULL && core.MarketIntelligenceEngine().IsReady());
      Check("Order Flow Intelligence",
            core_ok && core.OrderFlowIntelligenceEngine() != NULL && core.OrderFlowIntelligenceEngine().IsReady());
      Check("Session / Market Energy (Order Flow)",
            core_ok && core.OrderFlowIntelligenceEngine() != NULL && core.OrderFlowIntelligenceEngine().IsReady());
      Check("News Intelligence Engine",
            core_ok && core.NewsIntelligenceEngine() != NULL && core.NewsIntelligenceEngine().IsReady());
      Check("Recovery Intelligence Engine",
            core_ok && core.RecoveryIntelligenceEngine() != NULL && core.RecoveryIntelligenceEngine().IsReady());
      Check("Hedge / Recovery Intelligence Layer",
            core_ok && core.RecoveryIntelligenceEngine() != NULL && core.RecoveryIntelligenceEngine().IsReady());
      Check("Multi-Timeframe Intelligence",
            core_ok && core.MultiTimeframeEngine() != NULL && core.MultiTimeframeEngine().IsReady());
      Check("Portfolio Intelligence",
            core_ok && core.PortfolioIntelligenceEngine() != NULL && core.PortfolioIntelligenceEngine().IsReady());
      Check("Predictive Intelligence",
            core_ok && core.PredictiveIntelligenceEngine() != NULL && core.PredictiveIntelligenceEngine().IsReady());
      Check("Execution Supervisor",
            core_ok && core.ExecutionSupervisorEngine() != NULL && core.ExecutionSupervisorEngine().IsReady());
      Check("Self-Learning Platform",
            core_ok && core.SelfLearningPlatformEngine() != NULL && core.SelfLearningPlatformEngine().IsReady());
      Check("Knowledge Evolution / Recommendation",
            core_ok && core.SelfLearningPlatformEngine() != NULL && core.SelfLearningPlatformEngine().IsReady());

      // Safety: future layers inactive
      Check("Future Autonomy Interfaces INACTIVE",
            core_ok && core.DecisionSupportEngine() != NULL &&
            core.DecisionSupportEngine().AutonomyLayer() != NULL &&
            !core.DecisionSupportEngine().AutonomyLayer().AnyActivated());
      Check("Future Predictive Interfaces INACTIVE",
            core_ok && core.PredictiveIntelligenceEngine() != NULL &&
            core.PredictiveIntelligenceEngine().FutureLayer() != NULL &&
            !core.PredictiveIntelligenceEngine().FutureLayer().AnyActivated());
      Check("Future Self-Learning Interfaces INACTIVE",
            core_ok && core.SelfLearningPlatformEngine() != NULL &&
            core.SelfLearningPlatformEngine().FutureLayer() != NULL &&
            !core.SelfLearningPlatformEngine().FutureLayer().AnyActivated());
      Check("Future Execution Supervisor Interfaces INACTIVE",
            core_ok && core.ExecutionSupervisorEngine() != NULL &&
            core.ExecutionSupervisorEngine().FutureLayer() != NULL &&
            !core.ExecutionSupervisorEngine().FutureLayer().AnyActivated());

      m_lines += StringFormat("TOTAL=%d PASS=%d FAIL=%d SCORE=%.1f\r\n",
                              m_total, m_pass, m_fail, Score());
     }
  };

#endif // GM_CPHASE5_AI_MODULE_AUDITOR_MQH
//+------------------------------------------------------------------+
