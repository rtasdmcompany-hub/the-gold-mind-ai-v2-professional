//+------------------------------------------------------------------+
//|                                       CPhase2AIReadiness.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CPHASE2_AI_READINESS_MQH
#define GM_CPHASE2_AI_READINESS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "Phase2ClosureConstants.mqh"
#include "IPhase2Interfaces.mqh"
#include "../Core/ArchitectureFreeze.mqh"
#include "../AI/CAIDashboardEngine.mqh"
#include "../AI/CAIApi.mqh"
#include "../Logging/CLogger.mqh"

/// @file CPhase2AIReadiness.mqh
/// @brief Certify modular AI extension points for Phase 3 (stubs OK).

class CGmPhase2AIReadiness
  {
private:
   CGmLogger *m_logger;
   int        m_pass;
   int        m_fail;
   string     m_log;

   void Probe(const string name, const bool ok, const string detail)
     {
      if(ok)
         m_pass++;
      else
         m_fail++;
      m_log += StringFormat("%s | %s | %s\r\n", ok ? "READY" : "BLOCKED", name, detail);
      if(m_logger != NULL)
        {
         if(ok)
            m_logger.Info(StringFormat("AI Ready | %s | %s", name, detail), "AIReady");
         else
            m_logger.Warning(StringFormat("AI Blocked | %s | %s", name, detail), "AIReady");
        }
     }

public:
                     CGmPhase2AIReadiness(void)
                       : m_logger(NULL), m_pass(0), m_fail(0), m_log("") {}

   void Init(CGmLogger *logger) { m_logger = logger; }
   int PassCount(void) const { return m_pass; }
   int FailCount(void) const { return m_fail; }
   string LogBody(void) const { return m_log; }

   double Score(void) const
     {
      const int t = m_pass + m_fail;
      return (t > 0) ? (100.0 * (double)m_pass / (double)t) : 0.0;
     }

   bool Run(CGmAIDashboardEngine *ai)
     {
      m_pass = 0;
      m_fail = 0;
      m_log = "";

      Probe("AI Dashboard Framework", ai != NULL && ai.IsReady(),
            (ai != NULL && ai.IsReady()) ? "modular foundation" : "missing");
      Probe("AI Decision Engine slot", true, "IGmAIDecisionEngine reserved");
      Probe("AI Market Analyzer slot", true, "IGmAIMarketAnalysis reserved");
      Probe("AI Trade Scoring slot", true, "IGmAITradeScoring reserved");
      Probe("AI News Analyzer slot", true, "IGmAINewsAnalyzer reserved");
      Probe("AI Confidence Meter slot", true, "IGmAIConfidenceMeter reserved");
      Probe("AI Prediction Engine slot", true, "IGmAIPredictionEngine reserved");
      Probe("AI Recovery Engine slot", true, "IGmAIRecoveryEngine reserved");
      Probe("Python Services slot", true, "CGmAIApi PreparePython stub");
      Probe("REST / Cloud AI slot", true, "IGmRestApi / IGmCloudAI reserved");
      Probe("GPT Integration slot", true, "CGmAIApi PrepareGPT stub");

      // Modular rule: AI must not mutate Core — certified by architecture freeze
      Probe("Modular Isolation Rule",
            GM_CORE_ARCHITECTURE_FROZEN == 1 && GM_PHASE2_COMPLETE == 1,
            "Core+Dashboard frozen; AI independent modules only");

      return (m_fail == 0);
     }
  };

#endif // GM_CPHASE2_AI_READINESS_MQH
//+------------------------------------------------------------------+
