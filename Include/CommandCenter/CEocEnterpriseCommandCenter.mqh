//+------------------------------------------------------------------+
//|                              CEocEnterpriseCommandCenter.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEOC_ENTERPRISE_COMMAND_CENTER_MQH
#define GM_CEOC_ENTERPRISE_COMMAND_CENTER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmCommandCenterResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmEocEnterpriseCommandCenter
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
                     CGmEocEnterpriseCommandCenter(void)
                       : m_logger(NULL), m_health(0.0) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_health = 0.0;
      if(m_logger != NULL)
         m_logger.Success("Operations Started | Enterprise Command Center", "EOC");
     }

   double Health(void) const { return m_health; }

   void Build(const double cloud_score,
              const double infra_score,
              const double license_health,
              const double api_health,
              const double backup_score,
              const double notify_ok,
              const double mac_health,
              const double adc_conf,
              const bool trading_ready,
              const bool ai_ready,
              SGmCommandCenterResult &out)
     {
      out.trading_engine_status = trading_ready ? "RUNNING (Core Authority)" : "STANDBY";
      out.ai_engine_status = ai_ready ? "ACTIVE (Advisory)" : "OFF";
      out.cloud_status = StringFormat("Score=%.0f", cloud_score);
      out.api_status = StringFormat("Health=%.0f", api_health);
      out.license_status = StringFormat("Health=%.0f", license_health);
      out.database_status = "Local File DB Catalog OK";
      out.notify_status = StringFormat("OK=%.0f", notify_ok);
      out.backup_status = StringFormat("BCP=%.0f", backup_score);
      out.infrastructure_health = Clamp100(infra_score);

      double h = 35.0;
      h += MathMin(12.0, cloud_score * 0.12);
      h += MathMin(12.0, infra_score * 0.12);
      h += MathMin(10.0, license_health * 0.10);
      h += MathMin(8.0, api_health * 0.08);
      h += MathMin(8.0, backup_score * 0.08);
      h += MathMin(5.0, notify_ok * 0.05);
      h += MathMin(5.0, mac_health * 0.05);
      h += MathMin(5.0, adc_conf * 0.05);
      if(trading_ready) h += 5.0;
      m_health = Clamp100(h);
      out.enterprise_health = m_health;
      out.enterprise_status = StringFormat("ENTERPRISE HEALTH=%.0f | MONITOR-ONLY", m_health);

      if(m_logger != NULL)
         m_logger.Info(StringFormat("Health Calculated | Enterprise=%.0f Infra=%.0f",
                                    m_health, out.infrastructure_health), "EOC");
     }
  };

#endif // GM_CEOC_ENTERPRISE_COMMAND_CENTER_MQH
//+------------------------------------------------------------------+
