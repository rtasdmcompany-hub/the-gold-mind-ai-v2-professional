//+------------------------------------------------------------------+
//|                       CEnterpriseAIDecisionCenterEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 7 Sprint 7 — AI Decision / Quality / Execution Intel  |
//|     READ-ONLY — NEVER interferes with live trading              |
//+------------------------------------------------------------------+
#ifndef GM_CENTERPRISE_AI_DECISION_CENTER_ENGINE_MQH
#define GM_CENTERPRISE_AI_DECISION_CENTER_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "AIDecisionCenterConstants.mqh"
#include "SGmAIDecisionCenterResult.mqh"
#include "CAdcDecisionEngine.mqh"
#include "CAdcTradeQualityAnalyzer.mqh"
#include "CAdcExecutionIntelligence.mqh"
#include "CAdcMarketConditionAnalyzer.mqh"
#include "CAdcLearningReports.mqh"
#include "CAdcTaskQueue.mqh"
#include "CAdcExportCenter.mqh"
#include "CAdcDecisionDatabase.mqh"
#include "../PortfolioAnalytics/CEnterprisePortfolioAnalyticsEngine.mqh"
#include "../TradeJournal/CEnterpriseTradeJournalEngine.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"
#include "../AI/SGmAISnapshot.mqh"

class CGmEnterpriseAIDecisionCenterEngine
  {
private:
   CGmLogger                             *m_logger;
   CGmEnterprisePortfolioAnalyticsEngine *m_epa;
   CGmEnterpriseTradeJournalEngine       *m_etj;
   CGmAdcDecisionEngine                   m_decisions;
   CGmAdcTradeQualityAnalyzer             m_quality;
   CGmAdcExecutionIntelligence            m_execution;
   CGmAdcMarketConditionAnalyzer          m_market;
   CGmAdcLearningReports                  m_reports;
   CGmAdcTaskQueue                        m_queue;
   CGmAdcExportCenter                     m_export;
   CGmAdcDecisionDatabase                 m_db;
   SGmAIDecisionCenterResult              m_last;
   ulong                                  m_last_ms;
   bool                                   m_ready;
   bool                                   m_exported;

public:
                     CGmEnterpriseAIDecisionCenterEngine(void)
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
      m_decisions.Init(logger);
      m_quality.Init(logger);
      m_execution.Init(logger);
      m_market.Init(logger);
      m_reports.Init(logger);
      m_queue.Reset();
      m_export.Init(logger, files, m_db.Prefix());
      m_last.Reset();
      m_ready = true;
      m_exported = false;
      if(m_logger != NULL)
        {
         m_logger.Success("AI Decision Center Started | " + GM_ADC_VERSION, "ADC");
         m_logger.Info("POLICY | " + GM_ADC_POLICY, "ADC");
         m_logger.Info("SAFE | " + GM_ADC_SAFE, "ADC");
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
   SGmAIDecisionCenterResult Last(void) const { return m_last; }
   bool MayInterruptTrading(void) const { return false; }
   bool MayAutoChangeAi(void) const { return false; }

   bool Process(const bool force = false)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(!force && m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_ADC_THROTTLE_MS)
         return true;
      m_last_ms = now;

      if(!force && m_queue.PreferCache((ulong)GM_ADC_THROTTLE_MS) && m_last.valid)
        {
         m_last.queue_status = GM_ADC_Q_CACHED;
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

      SGmAIDecisionCenterResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();

      m_decisions.Analyze(epa, etj, r);
      m_quality.Evaluate(epa, etj, r);
      m_execution.Analyze(etj, epa, r);
      m_market.Analyze(epa, etj, r);
      m_reports.Generate(epa, etj, r);

      r.may_execute = false;
      r.may_modify_risk = false;
      r.may_interrupt_trading = false;
      r.may_auto_change_ai = false;
      r.center_status = "AI DECISION CENTER — ADVISORY ONLY";
      r.insight = StringFormat(
         "Conf=%.0f Qual=%.0f TradeQ=%.0f(%s) Exec=%.0f Broker=%.0f | %s Adapt=%.0f",
         r.decision_confidence, r.decision_quality, r.trade_quality_score,
         GmAdcGradeName(r.trade_quality_grade), r.execution_health, r.broker_quality,
         GmAdcMarketName(r.market_class), r.market_adaptability);
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
      s.ai_status = "AI Decision Center";
      s.ai_engine = "GoldMind Enterprise AI Decision Intelligence";
      s.current_mode = "ADC_READ_ONLY";
      s.confidence_pct = m_last.decision_confidence;
      s.confidence_status = StringFormat("%.0f", m_last.decision_confidence);

      s.w_trend_detector = StringFormat("%.0f", m_last.decision_quality);     // Decision Score
      s.future_ai_score = StringFormat("%.0f", m_last.execution_health);      // Execution Score
      s.w_recovery_ai = StringFormat("%s (%.0f)",
                                     GmAdcGradeName(m_last.trade_quality_grade),
                                     m_last.trade_quality_score);             // Trade Quality
      s.prediction_status = StringFormat("%.0f", m_last.broker_quality);      // Broker Health
      s.learning_status = GmAdcMarketName(m_last.market_class);               // Market Class
      s.w_volatility_scanner = "AI Reports Ready";                            // AI Reports
      s.w_market_analyzer = StringFormat("Events=%d", m_last.decisions_recorded); // Timeline
      s.w_news_analyzer = StringFormat("Hist Conf=%.0f", m_last.decision_confidence);
      s.w_trade_confidence = StringFormat("Adapt %.0f", m_last.market_adaptability);
      s.ai_version = StringFormat("DQ=%.0f EQ=%.0f",
                                  m_last.decision_quality, m_last.execution_health);
      s.decision_status = "ADVISORY ONLY — CORE EXECUTION AUTHORITY";
      s.valid = true;
     }
  };

#endif // GM_CENTERPRISE_AI_DECISION_CENTER_ENGINE_MQH
//+------------------------------------------------------------------+
