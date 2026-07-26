//+------------------------------------------------------------------+
//|                                    CEolAiOptimizationLab.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Recommendations only — NEVER modifies live settings         |
//+------------------------------------------------------------------+
#ifndef GM_CEOL_AI_OPTIMIZATION_LAB_MQH
#define GM_CEOL_AI_OPTIMIZATION_LAB_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "OptimizationLabConstants.mqh"
#include "../Logging/CLogger.mqh"

class CGmEolAiOptimizationLab
  {
private:
   CGmLogger *m_logger;
   double     m_opt_score;
   double     m_param_stability;
   string     m_suggestions;

public:
                     CGmEolAiOptimizationLab(void)
                       : m_logger(NULL), m_opt_score(0.0),
                         m_param_stability(0.0), m_suggestions("") {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_opt_score = 0.0;
      m_param_stability = 0.0;
      m_suggestions = "Idle";
     }

   double OptimizationScore(void) const { return m_opt_score; }
   double ParameterStability(void) const { return m_param_stability; }
   string Suggestions(void) const { return m_suggestions; }

   void Optimize(const double comparison_score,
                 const double lab_health,
                 const double win_rate_proxy)
     {
      // Evaluate reference axes — advisory scores only
      const double atr_stab = 78.0 + (lab_health - 50.0) * 0.1;
      const double risk_stab = 82.0;
      const double be_stab = 80.0;      // BE @ 50 pips reference
      const double partial_stab = 84.0; // 80% partial reference
      const double trail_stab = 79.0;   // 20% trail / 30 pip trail ref
      const double recovery_stab = 72.0 + win_rate_proxy * 0.05;
      const double second_attempt = 74.0;
      const double session_filter = 76.0;
      const double news_beh = 70.0;

      m_param_stability = MathMin(100.0,
         (atr_stab + risk_stab + be_stab + partial_stab + trail_stab +
          recovery_stab + second_attempt + session_filter + news_beh) / 9.0);

      m_opt_score = MathMin(100.0,
         0.40 * comparison_score + 0.35 * m_param_stability + 0.25 * lab_health);

      m_suggestions =
         "OPTIMIZATION SUGGESTIONS (USER APPROVAL REQUIRED — NOT AUTO-APPLIED)\r\n"
         "- ATR-14 TP: retain baseline; stability=" + DoubleToString(atr_stab, 0) + "\r\n"
         "- Risk %: prefer conservative profile under high DD regimes\r\n"
         "- Break-Even @" + DoubleToString(GM_EOL_REF_BE_PIPS, 0) + " pips: KEEP (stability=" +
         DoubleToString(be_stab, 0) + ")\r\n"
         "- 80% Partial / 20% Trail: KEEP (partial=" + DoubleToString(partial_stab, 0) +
         " trail=" + DoubleToString(trail_stab, 0) + ")\r\n"
         "- SL " + DoubleToString(GM_EOL_REF_SL_PIPS, 0) + " pips: FROZEN reference — do not auto-change\r\n"
         "- Recovery / Second Attempt: monitor recovery_stab=" + DoubleToString(recovery_stab, 0) + "\r\n"
         "- Session Filters: optional London/NY emphasis for research profiles\r\n"
         "- News Behaviour: prefer stand-aside research filter around major events\r\n"
         "Parameter Stability Score=" + DoubleToString(m_param_stability, 1);

      if(m_logger != NULL)
         m_logger.Success(StringFormat("Optimization Completed | Score=%.1f Stab=%.1f",
                                       m_opt_score, m_param_stability), "EOL");
     }
  };

#endif // GM_CEOL_AI_OPTIMIZATION_LAB_MQH
//+------------------------------------------------------------------+
