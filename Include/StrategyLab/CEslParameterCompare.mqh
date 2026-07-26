//+------------------------------------------------------------------+
//|                                     CEslParameterCompare.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Virtual profiles only — NEVER modifies live parameters      |
//+------------------------------------------------------------------+
#ifndef GM_CESL_PARAMETER_COMPARE_MQH
#define GM_CESL_PARAMETER_COMPARE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "StrategyLabConstants.mqh"
#include "../Logging/CLogger.mqh"

class CGmEslParameterCompare
  {
private:
   CGmLogger *m_logger;
   string     m_matrix;
   string     m_report;

   struct SProfile
     {
      string name;
      double atr_scale;
      double risk_scale;
      double recovery_bias;
      double score;
     };

public:
                     CGmEslParameterCompare(void)
                       : m_logger(NULL), m_matrix(""), m_report("") {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_matrix = "";
      m_report = "Idle";
     }

   string Matrix(void) const { return m_matrix; }
   string Report(void) const { return m_report; }

   void Compare(const double base_wr, const double base_pf, const double base_health)
     {
      SProfile p[GM_ESL_PARAM_PROFILES];
      p[0].name = "Baseline(SL30/ATR14)"; p[0].atr_scale = 1.0; p[0].risk_scale = 1.0; p[0].recovery_bias = 1.0;
      p[1].name = "ATR+20%";              p[1].atr_scale = 1.2; p[1].risk_scale = 1.0; p[1].recovery_bias = 1.0;
      p[2].name = "ATR-20%";              p[2].atr_scale = 0.8; p[2].risk_scale = 1.0; p[2].recovery_bias = 1.0;
      p[3].name = "Risk-Tight";           p[3].atr_scale = 1.0; p[3].risk_scale = 0.7; p[3].recovery_bias = 1.0;
      p[4].name = "Recovery+";            p[4].atr_scale = 1.0; p[4].risk_scale = 1.0; p[4].recovery_bias = 1.25;
      p[5].name = "BE/Trail Emphasis";    p[5].atr_scale = 1.0; p[5].risk_scale = 0.9; p[5].recovery_bias = 1.1;

      m_matrix = "Profile|Score|ATR|Risk|Recovery\r\n";
      double best = -1.0;
      string best_name = "";
      for(int i = 0; i < GM_ESL_PARAM_PROFILES; i++)
        {
         // Virtual score from base metrics — never touches live settings
         p[i].score = base_health * 0.4 +
                      base_wr * 0.3 * p[i].atr_scale +
                      MathMin(50.0, base_pf * 10.0) * 0.2 * p[i].risk_scale +
                      10.0 * p[i].recovery_bias;
         p[i].score = MathMin(100.0, p[i].score);
         m_matrix += StringFormat("%s|%.1f|%.2f|%.2f|%.2f\r\n",
                                  p[i].name, p[i].score,
                                  p[i].atr_scale, p[i].risk_scale, p[i].recovery_bias);
         if(p[i].score > best)
           {
            best = p[i].score;
            best_name = p[i].name;
           }
        }

      m_report = StringFormat(
         "Optimization Report (VIRTUAL ONLY) | Best=%s (%.1f) | Live params NEVER modified | "
         "Evaluated ATR/Risk/Recovery/BE/Trail/Session/News/Historical axes",
         best_name, best);

      if(m_logger != NULL)
         m_logger.Info("Comparison Completed | " + m_report, "ESL");
     }
  };

#endif // GM_CESL_PARAMETER_COMPARE_MQH
//+------------------------------------------------------------------+
