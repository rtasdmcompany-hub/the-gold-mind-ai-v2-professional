//+------------------------------------------------------------------+
//|                               CAIMultiAccountSupervisor.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Observes local + peer foundation slots — NEVER controls     |
//+------------------------------------------------------------------+
#ifndef GM_CAI_MULTI_ACCOUNT_SUPERVISOR_MQH
#define GM_CAI_MULTI_ACCOUNT_SUPERVISOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmEnterpriseResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../Intelligence/SGmIntelligenceResult.mqh"
#include "../../MultiInstance/SGmGlobalMonitorSnapshot.mqh"

class CGmAIMultiAccountSupervisor
  {
public:
   void Analyze(const SGmEnterpriseAccountProfile &profile,
                const SGmAssistantResult &sup,
                const SGmIntelligenceResult &intel,
                const SGmGlobalMonitorSnapshot &mi,
                SGmEnterpriseResult &r)
     {
      r.local_profile = profile;
      r.local_equity = (sup.valid ? 0.0 : 0.0);
      if(AccountInfoDouble(ACCOUNT_EQUITY) > 0.0)
         r.local_equity = AccountInfoDouble(ACCOUNT_EQUITY);

      r.local_dd_pct = sup.valid ? MathMax(sup.current_dd_pct, MathMax(sup.daily_dd_pct, 0.0)) : 0.0;
      r.local_margin_usage = (sup.valid ? sup.margin_usage_pct : 0.0);
      r.local_recovery = (sup.valid ? sup.recovery_status : "Idle");
      r.local_env = intel.valid ? intel.market_score_condition : "—";

      // Local health classification
      if(!profile.valid || !TerminalInfoInteger(TERMINAL_CONNECTED))
         r.local_health = GM_ENT_ACCT_CRITICAL;
      else if(r.local_dd_pct >= 10.0 || (sup.valid && sup.system_health_score < 50.0))
         r.local_health = GM_ENT_ACCT_CRITICAL;
      else if(r.local_dd_pct >= 5.0 || (sup.valid && (sup.warning_count >= 2 ||
              sup.system_health_score < 70.0)))
         r.local_health = GM_ENT_ACCT_WARNING;
      else
         r.local_health = GM_ENT_ACCT_HEALTHY;

      // Peer foundation from MultiInstance snapshot (read-only)
      int peers = 0;
      if(mi.valid)
         peers = MathMax(0, mi.total_instances - 1);

      r.accounts_monitored = 1 + peers;
      r.healthy_accounts = 0;
      r.warning_accounts = 0;
      r.critical_accounts = 0;

      if(r.local_health == GM_ENT_ACCT_HEALTHY) r.healthy_accounts++;
      else if(r.local_health == GM_ENT_ACCT_WARNING) r.warning_accounts++;
      else r.critical_accounts++;

      // Soft peer distribution for foundation visibility
      if(peers > 0)
        {
         const int peer_warn = (mi.valid && mi.global_health < 70.0) ? MathMax(1, peers / 5) : 0;
         const int peer_crit = (mi.valid && mi.global_health < 45.0) ? 1 : 0;
         const int peer_ok = MathMax(0, peers - peer_warn - peer_crit);
         r.healthy_accounts += peer_ok;
         r.warning_accounts += peer_warn;
         r.critical_accounts += peer_crit;
        }

      r.multi_account_report = StringFormat(
                                  "Enterprise Account Overview:\r\nAccounts Monitored: %d\r\nHealthy Accounts: %d\r\nWarning Accounts: %d\r\nCritical Accounts: %d\r\nLocal=%s | %s\r\n",
                                  r.accounts_monitored,
                                  r.healthy_accounts,
                                  r.warning_accounts,
                                  r.critical_accounts,
                                  GmEntAcctHealthName(r.local_health),
                                  GM_ENT_ANALYSIS_ONLY);
     }
  };

#endif // GM_CAI_MULTI_ACCOUNT_SUPERVISOR_MQH
//+------------------------------------------------------------------+
