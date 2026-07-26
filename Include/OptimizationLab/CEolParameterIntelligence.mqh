//+------------------------------------------------------------------+
//|                               CEolParameterIntelligence.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEOL_PARAMETER_INTELLIGENCE_MQH
#define GM_CEOL_PARAMETER_INTELLIGENCE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../Logging/CLogger.mqh"

class CGmEolParameterIntelligence
  {
private:
   CGmLogger *m_logger;
   double     m_confidence;
   string     m_report;

   double Clamp100(const double v) const
     {
      if(v < 0.0) return 0.0;
      if(v > 100.0) return 100.0;
      return v;
     }

public:
                     CGmEolParameterIntelligence(void)
                       : m_logger(NULL), m_confidence(0.0), m_report("") {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_confidence = 0.0;
      m_report = "Idle";
     }

   double Confidence(void) const { return m_confidence; }
   string Report(void) const { return m_report; }

   void Analyze(const double param_stability,
                const double market_adaptability,
                const double lab_robust,
                const double max_dd_proxy)
     {
      const double sensitivity = Clamp100(100.0 - MathAbs(param_stability - 75.0) * 0.8);
      const double hist_consistency = Clamp100(0.6 * param_stability + 0.4 * lab_robust);
      const double risk_stability = Clamp100(100.0 - max_dd_proxy * 0.9);
      const double recovery_eff = Clamp100(55.0 + lab_robust * 0.35);
      const double dd_behaviour = risk_stability;

      m_confidence = Clamp100(
         0.22 * sensitivity +
         0.22 * param_stability +
         0.18 * hist_consistency +
         0.15 * market_adaptability +
         0.13 * risk_stability +
         0.10 * recovery_eff);

      m_report = StringFormat(
         "Parameter Intelligence | Confidence=%.1f | Sensitivity=%.0f Stability=%.0f "
         "Consistency=%.0f Adaptability=%.0f RiskStab=%.0f RecoveryEff=%.0f DD=%.0f",
         m_confidence, sensitivity, param_stability, hist_consistency,
         market_adaptability, risk_stability, recovery_eff, dd_behaviour);

      if(m_logger != NULL)
         m_logger.Info(m_report, "EOL");
     }
  };

#endif // GM_CEOL_PARAMETER_INTELLIGENCE_MQH
//+------------------------------------------------------------------+
