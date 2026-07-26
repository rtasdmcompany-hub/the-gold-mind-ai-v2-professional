//+------------------------------------------------------------------+
//|                                  CEccConfigurationEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CECC_CONFIGURATION_ENGINE_MQH
#define GM_CECC_CONFIGURATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmConfigurationCenterResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmEccConfigurationEngine
  {
private:
   CGmLogger *m_logger;
   double     m_health;

   double Clamp100(const double v) const
     {
      if(v < 0.0) return 0.0;
      if(v > 100.0) return 100.0;
      return v;
     }

public:
                     CGmEccConfigurationEngine(void)
                       : m_logger(NULL), m_health(0.0) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_health = 0.0;
     }

   double Health(void) const { return m_health; }

   void Build(SGmConfigurationCenterResult &out)
     {
      const int domains = 10;
      double score = 72.0;
      score += (out.profile_version > 0 ? 8.0 : 0.0);
      score += (out.template_version > 0 ? 8.0 : 0.0);
      score += (out.workspace_status != "" ? 6.0 : 0.0);
      score += (out.last_backup != "" ? 6.0 : 0.0);
      if(out.template_locked)
         score -= 5.0;
      m_health = Clamp100(score);

      out.configuration_health = m_health;
      out.config_summary = StringFormat(
         "=== CONFIGURATION ENGINE ===\r\n"
         "Domains=%d | Global/Trading/Dashboard/Notify/AI/Cloud/Security/Display/Language/Theme\r\n"
         "Health=%.0f | Profile=%s v%d | Template=%s v%d\r\n"
         "LiveParamMutations=BLOCKED | TradingAuthority=NONE\r\n",
         domains, m_health, out.profile_name, out.profile_version,
         out.template_name, out.template_version);

      if(m_logger != NULL)
         m_logger.Info("Configuration Updated | Health=" + DoubleToString(m_health, 0), "ECC");
     }
  };

#endif // GM_CECC_CONFIGURATION_ENGINE_MQH
//+------------------------------------------------------------------+
