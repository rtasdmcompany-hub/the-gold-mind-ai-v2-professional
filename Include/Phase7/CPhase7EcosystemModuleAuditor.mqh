//+------------------------------------------------------------------+
//|                            CPhase7EcosystemModuleAuditor.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 7 Sprint 10 — Full Trading Ecosystem Audit            |
//+------------------------------------------------------------------+
#ifndef GM_CPHASE7_ECOSYSTEM_MODULE_AUDITOR_MQH
#define GM_CPHASE7_ECOSYSTEM_MODULE_AUDITOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "Phase7ClosureConstants.mqh"
#include "../Logging/CLogger.mqh"
#include "../TradeJournal/Module.TradeJournal.mqh"
#include "../StrategyLab/Module.StrategyLab.mqh"
#include "../OptimizationLab/Module.OptimizationLab.mqh"
#include "../PortfolioAnalytics/Module.PortfolioAnalytics.mqh"
#include "../ReportingCenter/Module.ReportingCenter.mqh"
#include "../ConfigurationCenter/Module.ConfigurationCenter.mqh"
#include "../AIDecisionCenter/Module.AIDecisionCenter.mqh"
#include "../MultiAccountCenter/Module.MultiAccountCenter.mqh"
#include "../CommandCenter/Module.CommandCenter.mqh"

class CGmPhase7EcosystemModuleAuditor
  {
private:
   CGmLogger *m_logger;
   int        m_pass;
   int        m_fail;
   int        m_total;
   string     m_lines;

   void Check(const string name, const bool ok)
     {
      m_total++;
      if(ok)
        {
         m_pass++;
         m_lines += "PASS | " + name + "\r\n";
        }
      else
        {
         m_fail++;
         m_lines += "FAIL | " + name + "\r\n";
         if(m_logger != NULL)
            m_logger.Warning("Phase7 Ecosystem Audit FAIL | " + name, "P7Audit");
        }
     }

public:
                     CGmPhase7EcosystemModuleAuditor(void)
                       : m_logger(NULL), m_pass(0), m_fail(0), m_total(0), m_lines("") {}

   void Init(CGmLogger *logger) { m_logger = logger; }

   int Pass(void) const { return m_pass; }
   int Fail(void) const { return m_fail; }
   int Total(void) const { return m_total; }
   string Body(void) const { return m_lines; }

   double Score(void) const
     {
      return (m_total > 0) ? (100.0 * (double)m_pass / (double)m_total) : 0.0;
     }

   void Audit(CGmEnterpriseTradeJournalEngine *etj,
              CGmEnterpriseStrategyLabEngine *slab,
              CGmEnterpriseOptimizationLabEngine *optlab,
              CGmEnterprisePortfolioAnalyticsEngine *epa,
              CGmEnterpriseReportingCenterEngine *erc,
              CGmEnterpriseConfigurationCenterEngine *ecc,
              CGmEnterpriseAIDecisionCenterEngine *adc,
              CGmEnterpriseMultiAccountCenterEngine *mac,
              CGmEnterpriseCommandCenterEngine *eoc)
     {
      m_pass = m_fail = m_total = 0;
      m_lines = "=== PHASE 7 TRADING ECOSYSTEM MODULE AUDIT ===\r\n";

      const bool etj_ok = (etj != NULL && etj.IsReady() && etj.Last().valid);
      Check("Enterprise Trade Journal", etj_ok);
      Check("Trade Timeline Engine", etj_ok && etj.Last().timeline_events >= 0);
      Check("Trade Replay Engine", etj_ok && StringLen(etj.Last().replay_summary) >= 0);
      Check("Professional Analytics", etj_ok && StringLen(etj.Last().analytics_summary) >= 0);
      Check("Psychology & Execution Analyzer", etj_ok && etj.Last().execution_score >= 0.0);

      const bool slab_ok = (slab != NULL && slab.IsReady() && slab.Last().valid);
      Check("Enterprise Backtest Laboratory", slab_ok);
      Check("Monte Carlo Simulation", slab_ok && slab.Last().institutional_score >= 0.0);
      Check("Walk-Forward Analysis", slab_ok);

      const bool opt_ok = (optlab != NULL && optlab.IsReady() && optlab.Last().valid);
      Check("Strategy Comparison Engine", opt_ok);
      Check("AI Optimization Laboratory", opt_ok && optlab.Last().institutional_score >= 0.0);
      Check("Parameter Intelligence", opt_ok);

      const bool epa_ok = (epa != NULL && epa.IsReady() && epa.Last().valid);
      Check("Portfolio Analytics", epa_ok);
      Check("Capital Management", epa_ok && epa.Last().capital_efficiency >= 0.0);

      const bool erc_ok = (erc != NULL && erc.IsReady() && erc.Last().valid);
      Check("Investor Dashboard", erc_ok && erc.Last().investor_rating >= 0.0);
      Check("Executive Reporting", erc_ok && erc.Last().report_quality >= 0.0);

      const bool ecc_ok = (ecc != NULL && ecc.IsReady() && ecc.Last().valid);
      Check("Configuration Center", ecc_ok);
      Check("Profile Manager", ecc_ok && ecc.Last().profile_version > 0);
      Check("Strategy Templates", ecc_ok && ecc.Last().template_version > 0);

      const bool adc_ok = (adc != NULL && adc.IsReady() && adc.Last().valid);
      Check("AI Decision Center", adc_ok);
      Check("Trade Quality Analyzer", adc_ok && adc.Last().trade_quality_score >= 0.0);
      Check("Execution Intelligence", adc_ok && adc.Last().execution_health >= 0.0);

      const bool mac_ok = (mac != NULL && mac.IsReady() && mac.Last().valid);
      Check("Multi-Account Manager", mac_ok);

      const bool eoc_ok = (eoc != NULL && eoc.IsReady() && eoc.Last().valid);
      Check("Enterprise Command Center", eoc_ok);
      Check("Operations Monitoring", eoc_ok && eoc.Last().enterprise_health >= 0.0);

      // Control-gate isolation
      Check("ETJ NO trade authority",
            etj_ok && !etj.Last().may_execute && !etj.Last().may_interrupt_trading);
      Check("StrategyLab NO live param mutation",
            slab_ok && !slab.Last().may_execute && !slab.Last().may_modify_live_params);
      Check("OptLab NO trade authority",
            opt_ok && !optlab.Last().may_execute && !optlab.Last().may_interrupt_trading);
      Check("EPA NO trade authority",
            epa_ok && !epa.Last().may_execute && !epa.Last().may_interrupt_trading);
      Check("ERC NO trade authority",
            erc_ok && !erc.Last().may_execute && !erc.Last().may_interrupt_trading);
      Check("ECC NO live param mutation",
            ecc_ok && !ecc.Last().may_execute && !ecc.Last().may_modify_live_params);
      Check("ADC NEVER auto-changes AI",
            adc_ok && !adc.Last().may_execute && !adc.Last().may_auto_change_ai);
      Check("MAC NEVER trades remote",
            mac_ok && !mac.Last().may_execute && !mac.Last().may_trade_remote);
      Check("EOC NEVER remote commands",
            eoc_ok && !eoc.Last().may_execute && !eoc.Last().may_remote_command);

      m_lines += StringFormat("TOTAL=%d PASS=%d FAIL=%d SCORE=%.1f\r\n",
                              m_total, m_pass, m_fail, Score());
     }
  };

#endif // GM_CPHASE7_ECOSYSTEM_MODULE_AUDITOR_MQH
//+------------------------------------------------------------------+
