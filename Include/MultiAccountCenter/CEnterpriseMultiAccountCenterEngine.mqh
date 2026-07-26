//+------------------------------------------------------------------+
//|                      CEnterpriseMultiAccountCenterEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 7 Sprint 8 — Multi-Account / Clusters / Capital       |
//|     MONITORING ONLY — NEVER places or modifies trades           |
//+------------------------------------------------------------------+
#ifndef GM_CENTERPRISE_MULTI_ACCOUNT_CENTER_ENGINE_MQH
#define GM_CENTERPRISE_MULTI_ACCOUNT_CENTER_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "MultiAccountCenterConstants.mqh"
#include "SGmMultiAccountCenterResult.mqh"
#include "CMacMultiAccountEngine.mqh"
#include "CMacAccountClusterManager.mqh"
#include "CMacCapitalAllocationAnalyzer.mqh"
#include "CMacAccountPerformanceComparison.mqh"
#include "CMacEnterpriseMonitoringCenter.mqh"
#include "CMacSecurityLayer.mqh"
#include "CMacTaskQueue.mqh"
#include "CMacExportCenter.mqh"
#include "CMacMultiAccountDatabase.mqh"
#include "../PortfolioAnalytics/CEnterprisePortfolioAnalyticsEngine.mqh"
#include "../TradeJournal/CEnterpriseTradeJournalEngine.mqh"
#include "../Cloud/Identity/CEnterpriseIdentityEngine.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"
#include "../AI/SGmAISnapshot.mqh"

class CGmEnterpriseMultiAccountCenterEngine
  {
private:
   CGmLogger                             *m_logger;
   CGmEnterprisePortfolioAnalyticsEngine *m_epa;
   CGmEnterpriseTradeJournalEngine       *m_etj;
   CGmEnterpriseIdentityEngine           *m_identity;
   CGmMacMultiAccountEngine               m_accounts;
   CGmMacAccountClusterManager            m_clusters;
   CGmMacCapitalAllocationAnalyzer        m_capital;
   CGmMacAccountPerformanceComparison     m_compare;
   CGmMacEnterpriseMonitoringCenter       m_monitor;
   CGmMacSecurityLayer                    m_security;
   CGmMacTaskQueue                        m_queue;
   CGmMacExportCenter                     m_export;
   CGmMacMultiAccountDatabase             m_db;
   SGmMultiAccountCenterResult            m_last;
   ulong                                  m_last_ms;
   bool                                   m_ready;
   bool                                   m_exported;

public:
                     CGmEnterpriseMultiAccountCenterEngine(void)
                       : m_logger(NULL), m_epa(NULL), m_etj(NULL), m_identity(NULL),
                         m_last_ms(0), m_ready(false), m_exported(false)
     {
      m_last.Reset();
     }

   bool Init(CGmLogger *logger,
             CGmFileManager *files,
             const long magic,
             const string symbol)
     {
      m_logger = logger;
      m_db.Init(logger, files, magic, symbol);
      m_accounts.Init(logger);
      m_clusters.Init(logger);
      m_capital.Init(logger);
      m_compare.Init(logger);
      m_monitor.Init(logger);
      m_security.Init(logger);
      m_queue.Reset();
      m_export.Init(logger, files, m_db.Prefix());
      m_last.Reset();
      m_ready = true;
      m_exported = false;
      if(m_logger != NULL)
        {
         m_logger.Success("Multi-Account Center Started | " + GM_MAC_VERSION, "MAC");
         m_logger.Info("POLICY | " + GM_MAC_POLICY, "MAC");
         m_logger.Info("SAFE | " + GM_MAC_SAFE, "MAC");
        }
      return true;
     }

   void BindPortfolio(CGmEnterprisePortfolioAnalyticsEngine *epa) { m_epa = epa; }
   void BindTradeJournal(CGmEnterpriseTradeJournalEngine *etj) { m_etj = etj; }
   void BindIdentity(CGmEnterpriseIdentityEngine *identity) { m_identity = identity; }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmMultiAccountCenterResult Last(void) const { return m_last; }
   bool MayInterruptTrading(void) const { return false; }
   bool MayTradeRemote(void) const { return false; }

   bool Process(const bool force = false)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(!force && m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_MAC_THROTTLE_MS)
         return true;
      m_last_ms = now;

      if(!force && m_queue.PreferCache((ulong)GM_MAC_THROTTLE_MS) && m_last.valid)
        {
         m_last.queue_status = GM_MAC_Q_CACHED;
         return true;
        }

      m_queue.MarkRunning();

      double license_health = 0.0;
      if(m_identity != NULL && m_identity.IsReady() && m_identity.Last().valid)
         license_health = m_identity.Last().license_health;
      else
         license_health = 75.0; // local bootstrap when identity not yet scored

      SGmPortfolioAnalyticsResult epa;
      SGmTradeJournalPlatformResult etj;
      epa.Reset();
      etj.Reset();
      if(m_epa != NULL && m_epa.IsReady() && m_epa.Last().valid)
         epa = m_epa.Last();
      if(m_etj != NULL && m_etj.IsReady() && m_etj.Last().valid)
         etj = m_etj.Last();

      SGmMultiAccountCenterResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();

      m_accounts.RegisterLocal(license_health);
      m_accounts.ApplyToResult(r);
      m_clusters.ApplyToResult(r);
      m_capital.Analyze(m_accounts.IsLicensed(), epa, r);
      m_compare.Compare(m_accounts.IsLicensed(), epa, etj, r);
      m_monitor.Build(r);
      m_security.ApplyToResult(r);

      r.may_execute = false;
      r.may_modify_risk = false;
      r.may_interrupt_trading = false;
      r.may_trade_remote = false;
      r.center_status = "MULTI-ACCOUNT CENTER — MONITORING ONLY";
      r.insight = StringFormat(
         "Health=%.0f Enterprise=%.0f Licensed=%d Excluded=%d | Alloc=%.0f Rank=%d | %s",
         r.account_health, r.enterprise_health, r.accounts_licensed,
         r.accounts_excluded_unlicensed, r.capital_allocation_score,
         r.performance_rank, GmMacConnName(r.connection_status));
      r.valid = true;

      if(!m_exported || force)
        {
         m_export.Export(r);
         m_exported = true;
         m_queue.MarkExported();
        }
      else
         m_queue.MarkCached();

      r.export_status = m_export.Status();
      r.queue_status = m_queue.Status();

      m_last = r;
      m_db.Persist(r);
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = "Multi-Account Center";
      s.ai_engine = "GoldMind Enterprise Multi-Account Manager";
      s.current_mode = "MAC_MONITOR_ONLY";
      s.confidence_pct = m_last.enterprise_health;
      s.confidence_status = StringFormat("%.0f", m_last.account_health);

      s.w_trend_detector = StringFormat("Licensed=%d", m_last.accounts_licensed); // Account List
      s.future_ai_score = GmMacClusterName(m_last.primary_cluster);               // Cluster Overview
      s.w_recovery_ai = StringFormat("Alloc %.0f", m_last.capital_allocation_score); // Capital
      s.prediction_status = StringFormat("Rank %d", m_last.performance_rank);     // Performance
      s.learning_status = StringFormat("%.0f", m_last.account_health);            // Health Score
      s.w_volatility_scanner = GmMacConnName(m_last.connection_status);           // Connection
      s.w_market_analyzer = StringFormat("RiskStab proxy Balance=%.0f",
                                         m_last.portfolio_balance_score);         // Risk Dist
      s.w_news_analyzer = StringFormat("Enterprise %.0f", m_last.enterprise_health);
      s.w_trade_confidence = StringFormat("Live=%d Demo=%d",
                                          m_last.live_count, m_last.demo_count);
      s.ai_version = StringFormat("EH=%.0f AH=%.0f",
                                  m_last.enterprise_health, m_last.account_health);
      s.decision_status = "MONITORING ONLY — CORE EXECUTION AUTHORITY";
      s.valid = true;
     }
  };

#endif // GM_CENTERPRISE_MULTI_ACCOUNT_CENTER_ENGINE_MQH
//+------------------------------------------------------------------+
