//+------------------------------------------------------------------+
//|                                      CEocGlobalAlertCenter.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEOC_GLOBAL_ALERT_CENTER_MQH
#define GM_CEOC_GLOBAL_ALERT_CENTER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmCommandCenterResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmEocGlobalAlertCenter
  {
private:
   CGmLogger *m_logger;
   string     m_history;

public:
                     CGmEocGlobalAlertCenter(void)
                       : m_logger(NULL), m_history("") {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_history = "";
     }

   void Append(const ENUM_GM_EOC_ALERT kind, const string msg)
     {
      const string line = TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) +
                          " | " + GmEocAlertName(kind) + " | " + msg;
      if(m_history == "")
         m_history = line;
      else
         m_history = line + "\r\n" + m_history;
      if(StringLen(m_history) > 2500)
         m_history = StringSubstr(m_history, 0, 2200);
      if(m_logger != NULL)
         m_logger.Info("Alert Generated | " + GmEocAlertName(kind) + " | " + msg, "EOC");
     }

   void Evaluate(const double license_health,
                 const double infra_score,
                 const double performance,
                 const bool terminal_connected,
                 SGmCommandCenterResult &out)
     {
      out.critical_alerts = 0;
      out.warning_alerts = 0;
      out.alert_count = 0;

      if(!terminal_connected)
        {
         Append(GM_EOC_ALERT_CRITICAL, "MT5 terminal disconnected");
         out.critical_alerts++;
        }
      if(license_health < 50.0)
        {
         Append(GM_EOC_ALERT_LICENSE, "License health below threshold");
         out.warning_alerts++;
        }
      if(infra_score < 55.0)
        {
         Append(GM_EOC_ALERT_INFRA, "Infrastructure health degraded");
         out.warning_alerts++;
        }
      if(performance < 60.0)
        {
         Append(GM_EOC_ALERT_PERF, "Performance score below target");
         out.warning_alerts++;
        }
      if(out.critical_alerts == 0 && out.warning_alerts == 0)
         Append(GM_EOC_ALERT_INFO, "All enterprise monitors nominal");

      out.alert_count = out.critical_alerts + out.warning_alerts;
      out.alert_center = StringFormat(
         "=== GLOBAL ALERT CENTER ===\r\n"
         "Critical=%d Warning=%d TotalRaised=%d\r\n"
         "Types: Critical/Warning/Info/License/Cloud/DB/Infra/Perf/Security\r\n"
         "--- HISTORY ---\r\n%s\r\n",
         out.critical_alerts, out.warning_alerts, out.alert_count, m_history);
     }
  };

#endif // GM_CEOC_GLOBAL_ALERT_CENTER_MQH
//+------------------------------------------------------------------+
