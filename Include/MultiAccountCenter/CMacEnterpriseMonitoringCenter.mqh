//+------------------------------------------------------------------+
//|                               CMacEnterpriseMonitoringCenter.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CMAC_ENTERPRISE_MONITORING_CENTER_MQH
#define GM_CMAC_ENTERPRISE_MONITORING_CENTER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMultiAccountCenterResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmMacEnterpriseMonitoringCenter
  {
private:
   CGmLogger *m_logger;

   double Clamp100(const double v) const
     {
      if(v < 0.0) return 0.0;
      if(v > 100.0) return 100.0;
      return v;
     }

public:
                     CGmMacEnterpriseMonitoringCenter(void) : m_logger(NULL) {}

   void Init(CGmLogger *logger) { m_logger = logger; }

   void Build(SGmMultiAccountCenterResult &out)
     {
      double eh = 45.0;
      eh += MathMin(20.0, out.account_health * 0.2);
      eh += MathMin(15.0, out.capital_allocation_score * 0.15);
      eh += MathMin(10.0, out.portfolio_balance_score * 0.1);
      eh += (out.accounts_licensed > 0 ? 10.0 : 0.0);
      out.enterprise_health = Clamp100(eh);

      out.monitoring_summary = StringFormat(
         "=== ENTERPRISE MONITORING CENTER ===\r\n"
         "Connected=%d Disconnected=%d Offline=%d Warning=%d\r\n"
         "Live=%d Demo=%d Healthy=%d | Licensed=%d Excluded=%d\r\n"
         "EnterpriseHealth=%.0f | Conn=%s\r\n",
         out.connected_count, out.disconnected_count, out.offline_count, out.warning_count,
         out.live_count, out.demo_count, out.healthy_count,
         out.accounts_licensed, out.accounts_excluded_unlicensed,
         out.enterprise_health, GmMacConnName(out.connection_status));

      out.institutional_summary = StringFormat(
         "=== INSTITUTIONAL MULTI-ACCOUNT SUMMARY ===\r\n"
         "Cluster=%s | Health=%.0f Alloc=%.0f Balance=%.0f Enterprise=%.0f\r\n"
         "Ranks: Account=%d Perf=%d | POLICY=MONITORING ONLY — NO REMOTE TRADING\r\n",
         GmMacClusterName(out.primary_cluster), out.account_health,
         out.capital_allocation_score, out.portfolio_balance_score, out.enterprise_health,
         out.primary_rank, out.performance_rank);
     }
  };

#endif // GM_CMAC_ENTERPRISE_MONITORING_CENTER_MQH
//+------------------------------------------------------------------+
