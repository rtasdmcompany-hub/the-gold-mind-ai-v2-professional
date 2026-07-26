//+------------------------------------------------------------------+
//|                                    CPhase3AIModuleAuditor.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CPHASE3_AI_MODULE_AUDITOR_MQH
#define GM_CPHASE3_AI_MODULE_AUDITOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "Phase3ClosureConstants.mqh"
#include "../AI/Core/CAICoreEngine.mqh"
#include "../Logging/CLogger.mqh"

/// @brief Audits presence/readiness of Phase 3 AI modules (advisory stack).
class CGmPhase3AIModuleAuditor
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
            m_logger.Warning("AI Audit FAIL | " + name, "P3Audit");
        }
     }

public:
                     CGmPhase3AIModuleAuditor(void)
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
      m_lines = "=== PHASE 3 AI MODULE AUDIT ===\r\n";

      const bool core_ok = (core != NULL && core.IsReady());
      Check("AI Core Engine", core_ok);
      Check("AI Manager", core_ok);
      Check("AI Controller", core_ok);
      Check("AI Data Bus", core_ok);
      Check("AI State Manager", core_ok);
      Check("AI Configuration", core_ok);

      Check("AI Market Analysis Engine",
            core_ok && core.MarketAnalyzer() != NULL && core.MarketAnalyzer().IsReady());
      Check("AI Trend Engine",
            core_ok && core.TrendEngine() != NULL && core.TrendEngine().IsReady());
      Check("AI ATR / Volatility Engine",
            core_ok && core.VolatilityEngine() != NULL && core.VolatilityEngine().IsReady());
      Check("AI News Intelligence Engine",
            core_ok && core.NewsEngine() != NULL && core.NewsEngine().IsReady());
      Check("AI Trade Confidence Engine",
            core_ok && core.ConfidenceEngine() != NULL && core.ConfidenceEngine().IsReady());
      Check("AI Learning Engine",
            core_ok && core.LearningEngine() != NULL && core.LearningEngine().IsReady());
      Check("Pattern Recognition Engine",
            core_ok && core.LearningEngine() != NULL && core.LearningEngine().IsReady());
      Check("Decision Support Engine",
            core_ok && core.DecisionSupportEngine() != NULL && core.DecisionSupportEngine().IsReady());
      Check("Explainable AI (XAI)",
            core_ok && core.DecisionSupportEngine() != NULL && core.DecisionSupportEngine().IsReady());
      Check("Validation Engine",
            core_ok && core.AIValidationEngine() != NULL && core.AIValidationEngine().IsReady());
      Check("Certification Engine",
            core_ok && core.AIValidationEngine() != NULL && core.AIValidationEngine().IsReady());
      Check("Reporting Engine",
            core_ok && core.AIValidationEngine() != NULL && core.AIValidationEngine().IsReady());
      Check("AI Dashboard Integration", core_ok);
      Check("Future Autonomy Interfaces (inactive)",
            core_ok && core.DecisionSupportEngine() != NULL &&
            core.DecisionSupportEngine().AutonomyLayer() != NULL &&
            !core.DecisionSupportEngine().AutonomyLayer().AnyActivated());

      m_lines += StringFormat("TOTAL=%d PASS=%d FAIL=%d SCORE=%.1f\r\n",
                              m_total, m_pass, m_fail, Score());
     }
  };

#endif // GM_CPHASE3_AI_MODULE_AUDITOR_MQH
//+------------------------------------------------------------------+
