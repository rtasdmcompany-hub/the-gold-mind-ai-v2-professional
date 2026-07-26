//+------------------------------------------------------------------+
//|                         CEnterpriseTradeJournalEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 7 Sprint 1 — Trade Journal / Replay / Analytics       |
//|     ANALYSIS ONLY — NEVER modifies trading                      |
//+------------------------------------------------------------------+
#ifndef GM_CENTERPRISE_TRADE_JOURNAL_ENGINE_MQH
#define GM_CENTERPRISE_TRADE_JOURNAL_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "TradeJournalConstants.mqh"
#include "SGmTradeJournalPlatformResult.mqh"
#include "CEtjJournalEngine.mqh"
#include "CEtjTimelineEngine.mqh"
#include "CEtjReplayEngine.mqh"
#include "CEtjAnalyticsEngine.mqh"
#include "CEtjPsychologyAnalyzer.mqh"
#include "CEtjExportCenter.mqh"
#include "CEtjJournalDatabase.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"
#include "../AI/SGmAISnapshot.mqh"

class CGmEnterpriseTradeJournalEngine
  {
private:
   CGmLogger                   *m_logger;
   CGmEtjJournalEngine          m_journal;
   CGmEtjTimelineEngine         m_timeline;
   CGmEtjReplayEngine           m_replay;
   CGmEtjAnalyticsEngine        m_analytics;
   CGmEtjPsychologyAnalyzer     m_psycho;
   CGmEtjExportCenter           m_export;
   CGmEtjJournalDatabase        m_db;
   SGmTradeJournalPlatformResult m_last;
   ulong                        m_last_ms;
   ulong                        m_cycle_us;
   bool                         m_ready;
   bool                         m_exported;

public:
                     CGmEnterpriseTradeJournalEngine(void)
                       : m_logger(NULL), m_last_ms(0), m_cycle_us(0),
                         m_ready(false), m_exported(false)
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
      m_journal.Init(logger, magic, symbol);
      m_timeline.Init(logger);
      m_replay.Init(logger);
      m_analytics.Init(logger);
      m_psycho.Init(logger);
      m_export.Init(logger, files, m_db.Prefix());
      m_last.Reset();
      m_ready = true;
      m_exported = false;
      if(m_logger != NULL)
        {
         m_logger.Success("Trade Journal Engine Started | " + GM_ETJ_VERSION, "ETJ");
         m_logger.Info("POLICY | " + GM_ETJ_POLICY, "ETJ");
         m_logger.Info("SAFE | " + GM_ETJ_SAFE, "ETJ");
        }
      return true;
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmTradeJournalPlatformResult Last(void) const { return m_last; }
   bool MayInterruptTrading(void) const { return false; }

   bool Process(const bool force = false)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(!force && m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_ETJ_THROTTLE_MS)
         return true;
      m_last_ms = now;

      const ulong t0 = GetMicrosecondCount();

      m_journal.SyncFromTerminal();
      m_timeline.RebuildFromTrades(GetPointer(m_journal));
      m_replay.Generate(GetPointer(m_journal), GetPointer(m_timeline));

      SGmTradeJournalPlatformResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.trades_total = m_journal.Count();
      r.trades_open = m_journal.CountOpen();
      r.trades_today = m_journal.CountToday();
      r.timeline_events = m_timeline.Count();
      r.timeline_summary = m_timeline.Summary();
      r.replay_status = m_replay.Status();
      r.replay_summary = m_replay.Summary();

      m_analytics.Calculate(GetPointer(m_journal), r);
      m_psycho.Analyze(GetPointer(m_journal), r);

      if(!m_exported || force)
        {
         m_export.ExportCsv(GetPointer(m_journal), r);
         m_exported = true;
        }
      r.export_status = m_export.Status();

      r.may_execute = false;
      r.may_modify_risk = false;
      r.may_interrupt_trading = false;
      r.center_status = "TRADE JOURNAL CENTER — ANALYSIS ONLY";
      r.insight = StringFormat(
         "GM trades=%d open=%d today=%d | WR=%.0f%% PF=%.2f | Exec=%.0f | %s",
         r.trades_total, r.trades_open, r.trades_today,
         r.win_rate, r.profit_factor, r.execution_score,
         GmEtjReplayName(r.replay_status));
      r.valid = true;

      m_cycle_us = GetMicrosecondCount() - t0;
      m_last = r;
      m_db.Persist(GetPointer(m_journal), r, r.timeline_summary);

      if(m_logger != NULL && m_cycle_us > 50000)
         m_logger.Warning(StringFormat("ETJ cycle slow | %I64u us", m_cycle_us), "ETJ");

      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = "Trade Journal Center";
      s.ai_engine = "GoldMind Enterprise Trade Journal";
      s.current_mode = "ETJ_ANALYSIS_ONLY";
      s.confidence_pct = m_last.execution_score;
      s.confidence_status = StringFormat("%.0f", m_last.compliance_score);

      s.w_trend_detector = m_last.timeline_summary;                          // Trade Timeline
      s.future_ai_score = IntegerToString(m_last.trades_today);              // Today's Trades
      s.w_recovery_ai = StringFormat("%.2f", m_last.weekly_pnl);             // Weekly Performance
      s.prediction_status = StringFormat("%.2f", m_last.monthly_pnl);        // Monthly Performance
      s.learning_status = StringFormat("%.0f", m_last.execution_score);      // Execution Score
      s.w_volatility_scanner = StringFormat("%.1f%%", m_last.win_rate);      // Win Rate
      s.w_market_analyzer = StringFormat("%.2f", m_last.profit_factor);       // Profit Factor
      s.w_news_analyzer = StringFormat("%.1f%%", m_last.recovery_rate);      // Recovery Statistics
      s.w_trade_confidence = GmEtjReplayName(m_last.replay_status);          // Trade Replay Status
      s.ai_version = StringFormat("Disc %.0f | Comp %.0f",
                                  m_last.discipline_score,
                                  m_last.compliance_score);
      s.decision_status = "ANALYSIS ONLY — CORE EXECUTION AUTHORITY";
      s.valid = true;
     }
  };

#endif // GM_CENTERPRISE_TRADE_JOURNAL_ENGINE_MQH
//+------------------------------------------------------------------+
