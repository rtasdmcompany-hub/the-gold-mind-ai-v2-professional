//+------------------------------------------------------------------+
//|                                 CAccountComparisonEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CACCOUNT_COMPARISON_ENGINE_MQH
#define GM_CACCOUNT_COMPARISON_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmEnterpriseResult.mqh"
#include "../Intelligence/SGmIntelligenceResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../Intelligence/IntelligenceAIConstants.mqh"

class CGmAccountComparisonEngine
  {
public:
   void Analyze(const SGmEnterpriseResult &partial,
                const SGmIntelligenceResult &intel,
                const SGmAssistantResult &sup,
                SGmEnterpriseResult &r)
     {
      if(partial.local_health == GM_ENT_ACCT_HEALTHY &&
         (intel.valid ? intel.ai_confidence >= 75.0 : true) &&
         partial.local_dd_pct < 3.0)
         r.local_rank = GM_ENT_RANK_EXCELLENT;
      else if(partial.local_health == GM_ENT_ACCT_HEALTHY)
         r.local_rank = GM_ENT_RANK_STABLE;
      else if(partial.local_health == GM_ENT_ACCT_WARNING)
         r.local_rank = GM_ENT_RANK_MODERATE;
      else
         r.local_rank = GM_ENT_RANK_MONITOR;

      r.risk_overview = StringFormat("LocalRisk=%s | Cap=%.0f | DD=%.1f%% | Advis=%s",
                                     GmEntAcctHealthName(partial.local_health),
                                     sup.valid ? sup.capital_protection_score : 0.0,
                                     partial.local_dd_pct,
                                     intel.valid ? GmRiskAdvName(intel.risk_advisory) : "—");

      r.performance_map = StringFormat("Local=%s | MktScore=%.0f | Strat=%.0f | FleetMix H/W/C=%d/%d/%d",
                                       GmEntRankName(r.local_rank),
                                       intel.valid ? intel.market_score : 0.0,
                                       intel.valid ? intel.strategy_performance_score : 0.0,
                                       partial.healthy_accounts,
                                       partial.warning_accounts,
                                       partial.critical_accounts);

      r.comparison_report = StringFormat(
                               "=== ENTERPRISE COMPARISON REPORT ===\r\nAccount Performance Ranking:\r\nLocal Account: %s\r\n%s\r\n%s\r\nPeerSlots=%d (foundation observation)\r\n%s\r\n",
                               GmEntRankName(r.local_rank),
                               r.risk_overview,
                               r.performance_map,
                               MathMax(0, partial.accounts_monitored - 1),
                               GM_ENT_ANALYSIS_ONLY);
     }
  };

#endif // GM_CACCOUNT_COMPARISON_ENGINE_MQH
//+------------------------------------------------------------------+
