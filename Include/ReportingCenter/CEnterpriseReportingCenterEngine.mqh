//+------------------------------------------------------------------+
//|                         CEnterpriseReportingCenterEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 7 Sprint 5 — Reporting / Investor / Executive BI      |
//|     READ-ONLY — NEVER interferes with live trading              |
//+------------------------------------------------------------------+
#ifndef GM_CENTERPRISE_REPORTING_CENTER_ENGINE_MQH
#define GM_CENTERPRISE_REPORTING_CENTER_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ReportingCenterConstants.mqh"
#include "SGmReportingCenterResult.mqh"
#include "CErcReportEngine.mqh"
#include "CErcInvestorDashboard.mqh"
#include "CErcBusinessIntelligence.mqh"
#include "CErcVisualizationEngine.mqh"
#include "CErcExecutiveReportCenter.mqh"
#include "CErcTaskQueue.mqh"
#include "CErcExportCenter.mqh"
#include "CErcReportingDatabase.mqh"
#include "../PortfolioAnalytics/CEnterprisePortfolioAnalyticsEngine.mqh"
#include "../TradeJournal/CEnterpriseTradeJournalEngine.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"
#include "../AI/SGmAISnapshot.mqh"

class CGmEnterpriseReportingCenterEngine
  {
private:
   CGmLogger                              *m_logger;
   CGmEnterprisePortfolioAnalyticsEngine  *m_epa;
   CGmEnterpriseTradeJournalEngine        *m_etj;
   CGmErcReportEngine                      m_reports;
   CGmErcInvestorDashboard                 m_investor;
   CGmErcBusinessIntelligence              m_bi;
   CGmErcVisualizationEngine               m_viz;
   CGmErcExecutiveReportCenter             m_exec;
   CGmErcTaskQueue                         m_queue;
   CGmErcExportCenter                      m_export;
   CGmErcReportingDatabase                 m_db;
   SGmReportingCenterResult                m_last;
   ulong                                   m_last_ms;
   bool                                    m_ready;
   bool                                    m_exported;

public:
                     CGmEnterpriseReportingCenterEngine(void)
                       : m_logger(NULL), m_epa(NULL), m_etj(NULL),
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
      m_reports.Init(logger);
      m_investor.Init(logger);
      m_bi.Init(logger);
      m_viz.Init(logger);
      m_exec.Init(logger);
      m_queue.Reset();
      m_export.Init(logger, files, m_db.Prefix());
      m_last.Reset();
      m_ready = true;
      m_exported = false;
      if(m_logger != NULL)
        {
         m_logger.Success("Reporting Center Started | " + GM_ERC_VERSION, "ERC");
         m_logger.Info("POLICY | " + GM_ERC_POLICY, "ERC");
         m_logger.Info("SAFE | " + GM_ERC_SAFE, "ERC");
        }
      return true;
     }

   void BindPortfolio(CGmEnterprisePortfolioAnalyticsEngine *epa) { m_epa = epa; }
   void BindTradeJournal(CGmEnterpriseTradeJournalEngine *etj) { m_etj = etj; }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmReportingCenterResult Last(void) const { return m_last; }
   bool MayInterruptTrading(void) const { return false; }

   bool Process(const bool force = false)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(!force && m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_ERC_THROTTLE_MS)
         return true;
      m_last_ms = now;

      if(!force && m_queue.PreferCache((ulong)GM_ERC_THROTTLE_MS) && m_last.valid)
        {
         m_last.queue_status = GM_ERC_Q_CACHED;
         return true;
        }

      m_queue.MarkRunning();

      SGmPortfolioAnalyticsResult epa;
      SGmTradeJournalPlatformResult etj;
      epa.Reset();
      etj.Reset();
      if(m_epa != NULL && m_epa.IsReady() && m_epa.Last().valid)
         epa = m_epa.Last();
      if(m_etj != NULL && m_etj.IsReady() && m_etj.Last().valid)
         etj = m_etj.Last();

      SGmReportingCenterResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.trades_reported = epa.trades_closed;

      m_reports.Generate(epa, etj, r);
      r.report_quality = m_reports.Quality();
      m_investor.Build(epa, r);
      m_bi.Analyze(epa, etj, r);
      m_viz.Build(epa, r);
      m_exec.Compose(epa, etj, r);

      r.may_execute = false;
      r.may_modify_risk = false;
      r.may_interrupt_trading = false;
      r.center_status = "REPORTING CENTER — READ-ONLY BI";
      r.insight = StringFormat(
         "Quality=%.0f BI=%.0f Forecast=%.0f Investor=%.0f | Reports=%d | Net=%.2f PF=%.2f",
         r.report_quality, r.bi_score, r.performance_forecast, r.investor_rating,
         r.reports_generated, r.net_profit, r.profit_factor);
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
      s.ai_status = "Reporting Center";
      s.ai_engine = "GoldMind Enterprise Reporting & BI";
      s.current_mode = "ERC_READ_ONLY";
      s.confidence_pct = m_last.report_quality;
      s.confidence_status = StringFormat("%.0f", m_last.performance_forecast);

      s.w_trend_detector = m_last.daily_report;                               // Today's Report
      s.future_ai_score = StringFormat("%.2f", m_last.avg_monthly_return);    // Monthly Report
      s.w_recovery_ai = StringFormat("PF %.2f | Net %.2f",
                                     m_last.profit_factor, m_last.net_profit); // Performance Summary
      s.prediction_status = StringFormat("Rating %.0f", m_last.investor_rating); // Investor
      s.learning_status = StringFormat("BI %.0f", m_last.bi_score);           // Business Intelligence
      s.w_volatility_scanner = "Exec Summary Ready";                          // Executive Summary
      s.w_market_analyzer = m_last.latest_reports;                            // Latest Reports
      s.w_news_analyzer = GmErcQueueName(m_last.queue_status);                // Export Queue
      s.w_trade_confidence = StringFormat("%.1f%%", m_last.account_growth_pct);
      s.ai_version = StringFormat("Q=%.0f Forecast=%.0f",
                                  m_last.report_quality, m_last.performance_forecast);
      s.decision_status = "REPORTING ONLY — CORE EXECUTION AUTHORITY";
      s.valid = true;
     }
  };

#endif // GM_CENTERPRISE_REPORTING_CENTER_ENGINE_MQH
//+------------------------------------------------------------------+
