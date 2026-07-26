//+------------------------------------------------------------------+
//|                              SGmMultiAccountCenterResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_MULTI_ACCOUNT_CENTER_RESULT_MQH
#define GM_SGM_MULTI_ACCOUNT_CENTER_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "MultiAccountCenterConstants.mqh"

struct SGmMultiAccountCenterResult
  {
   datetime           stamped_at;
   ENUM_GM_MAC_QUEUE  queue_status;
   ENUM_GM_MAC_CLUSTER primary_cluster;
   ENUM_GM_MAC_CONN   connection_status;

   int                accounts_registered;
   int                accounts_licensed;
   int                accounts_excluded_unlicensed;
   int                connected_count;
   int                disconnected_count;
   int                live_count;
   int                demo_count;
   int                healthy_count;
   int                warning_count;
   int                offline_count;

   double             account_health;
   double             capital_allocation_score;
   double             portfolio_balance_score;
   double             enterprise_health;

   double             total_capital;
   double             used_margin;
   double             free_margin;
   double             equity;
   double             balance;
   double             daily_growth_pct;
   double             monthly_growth_pct;

   int                primary_rank;
   int                performance_rank;

   string             account_list;
   string             cluster_overview;
   string             capital_report;
   string             comparison_report;
   string             ranking_report;
   string             monitoring_summary;
   string             institutional_summary;
   string             security_status;
   string             audit_trail;
   string             export_status;
   string             center_status;
   string             insight;

   bool               may_execute;
   bool               may_modify_risk;
   bool               may_interrupt_trading;
   bool               may_trade_remote;
   bool               valid;

   void Reset(void)
     {
      stamped_at = 0;
      queue_status = GM_MAC_Q_IDLE;
      primary_cluster = GM_MAC_CL_PRODUCTION;
      connection_status = GM_MAC_CONN_OFFLINE;
      accounts_registered = accounts_licensed = accounts_excluded_unlicensed = 0;
      connected_count = disconnected_count = live_count = demo_count = 0;
      healthy_count = warning_count = offline_count = 0;
      account_health = capital_allocation_score = portfolio_balance_score = enterprise_health = 0.0;
      total_capital = used_margin = free_margin = equity = balance = 0.0;
      daily_growth_pct = monthly_growth_pct = 0.0;
      primary_rank = performance_rank = 0;
      account_list = cluster_overview = capital_report = comparison_report = "";
      ranking_report = monitoring_summary = institutional_summary = "";
      security_status = audit_trail = "";
      export_status = "Architecture Ready";
      center_status = insight = "";
      may_execute = false;
      may_modify_risk = false;
      may_interrupt_trading = false;
      may_trade_remote = false;
      valid = false;
     }
  };

#endif // GM_SGM_MULTI_ACCOUNT_CENTER_RESULT_MQH
//+------------------------------------------------------------------+
