//+------------------------------------------------------------------+
//|                                             CAINewsEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     Phase 3 Sprint 5 — AI News Intelligence Engine              |
//|     ANALYSIS ONLY — NEVER blocks / skips / cancels trades       |
//+------------------------------------------------------------------+
#ifndef GM_CAI_NEWS_ENGINE_MQH
#define GM_CAI_NEWS_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "NewsAIConstants.mqh"
#include "SGmNewsAnalysisResult.mqh"
#include "CNewsDataEngine.mqh"
#include "CEconomicCalendarAnalyzer.mqh"
#include "CNewsImpactClassifier.mqh"
#include "CMarketReactionAnalyzer.mqh"
#include "CGoldEventMonitor.mqh"
#include "CNewsDecisionApi.mqh"
#include "CNewsEventEngine.mqh"
#include "CNewsHistoryDatabase.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../SGmAISnapshot.mqh"

/// @file CAINewsEngine.mqh
/// @brief News / calendar / gold impact intelligence — ANALYSIS ONLY.
/// @warning NEVER open/close/modify trades or block Gold Mind execution.

class CGmAINewsEngine
  {
private:
   CGmLogger                    *m_logger;
   CGmPhase2Bridge              *m_bridge;
   CGmNewsDataEngine             m_data;
   CGmEconomicCalendarAnalyzer   m_calendar;
   CGmNewsImpactClassifier       m_impact;
   CGmMarketReactionAnalyzer     m_reaction;
   CGmGoldEventMonitor           m_gold;
   CGmNewsDecisionApi            m_api;
   CGmNewsEventEngine            m_events;
   CGmNewsHistoryDatabase        m_db;
   SGmNewsAnalysisResult         m_last;
   SGmNewsAnalysisResult         m_prev;
   ulong                         m_last_ms;
   bool                          m_ready;

   string FmtEta(const int sec) const
     {
      if(sec <= 0)
         return "NOW/PAST";
      const int h = sec / 3600;
      const int m = (sec % 3600) / 60;
      if(h > 0)
         return StringFormat("%dh %dm", h, m);
      return StringFormat("%dm", m);
     }

   string ShortName(const string n) const
     {
      if(StringLen(n) == 0)
         return "—";
      if(StringLen(n) <= 28)
         return n;
      return StringSubstr(n, 0, 25) + "...";
     }

public:
                     CGmAINewsEngine(void)
                       : m_logger(NULL), m_bridge(NULL), m_last_ms(0), m_ready(false)
     {
      m_last.Reset();
      m_prev.Reset();
     }

   bool Init(CGmLogger *logger,
             CGmFileManager *files,
             CGmPhase2Bridge *bridge,
             const long magic,
             const string symbol)
     {
      m_logger = logger;
      m_bridge = bridge;
      m_data.Init(logger);
      m_events.Init(logger);
      m_db.Init(logger, files, magic, symbol);
      m_last.Reset();
      m_prev.Reset();
      m_last_ms = 0;
      m_ready = true;
      if(m_logger != NULL)
        {
         m_logger.Success("AI News Engine ready | ANALYSIS ONLY | " + GM_NEWS_AI_VERSION,
                          "AINews");
         m_logger.Info("POLICY | " + GM_NEWS_NO_TRADE_BLOCK +
                       " | Gold Mind may trade during high-impact news",
                       "AINews");
        }
      return true;
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmNewsAnalysisResult Last(void) const { return m_last; }
   CGmNewsEventEngine *Events(void) { return GetPointer(m_events); }
   CGmNewsDecisionApi *DecisionApi(void) { return GetPointer(m_api); }
   SGmNewsDecisionExport DecisionExport(void) const { return m_api.Export(m_last); }

   bool Analyze(void)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_NEWS_THROTTLE_MS && m_last.valid)
         return true;
      m_last_ms = now;

      SGmNewsAnalysisResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.trade_block_allowed = false;
      r.engine_status = "RUNNING";

      if(m_bridge != NULL)
        {
         r.symbol = m_bridge.Symbol();
         r.session_id = m_bridge.SessionId();
        }
      if(StringLen(r.symbol) == 0)
        {
         r.engine_status = "NO SYMBOL";
         if(m_logger != NULL)
            m_logger.Warning("News analysis aborted | no symbol", "AINews");
         return false;
        }

      m_data.Refresh();
      m_calendar.Analyze(m_data, r);
      m_impact.Classify(m_data, r);
      m_gold.Analyze(m_data, r);
      m_reaction.Analyze(r.symbol, r);

      r.engine_status = (r.event_count > 0) ? "READY" : "READY (empty calendar)";
      r.insight = StringFormat("%s | risk=%.0f | %s | gold=%d | %s",
                               GmNewsImpactName(r.current_impact),
                               r.news_risk_score,
                               GmNewsReactionName(r.reaction_status),
                               r.gold_event_count,
                               GM_NEWS_NO_TRADE_BLOCK);
      r.valid = true;

      m_events.Evaluate(r, m_last);
      m_db.Record(r);

      m_prev = m_last;
      m_last = r;

      if(m_logger != NULL)
        {
         m_logger.Info("Impact Classified | " + GmNewsImpactName(r.current_impact), "AINews");
         m_logger.Info("Market Reaction Recorded | " + r.reaction.summary, "AINews");
         m_logger.Info("Dashboard Updated | News widgets", "AINews");
         m_logger.Debug(StringFormat("Performance | news events=%d | conf=%.0f",
                                     r.event_count, r.confidence),
                        "AINews");
        }
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = "NEWS READY";
      s.ai_engine = "GoldMind News AI";
      s.current_mode = "NEWS_ANALYSIS";
      s.confidence_pct = m_last.confidence;
      s.confidence_status = StringFormat("%.0f%%", m_last.confidence);

      // Widget packing (Sprint 5 labels)
      s.w_trend_detector = ShortName(m_last.upcoming.valid ? m_last.upcoming.name : "—");
      s.future_ai_score = ShortName(m_last.next_high_impact.valid
                                    ? m_last.next_high_impact.name : "—");
      s.w_recovery_ai = FmtEta(m_last.seconds_until_next > 0
                               ? m_last.seconds_until_next
                               : m_last.seconds_until_high);
      s.prediction_status = StringFormat("%.0f", m_last.news_risk_score);
      s.learning_status = GmNewsImpactName(m_last.current_impact);
      s.w_volatility_scanner = GmNewsReactionName(m_last.reaction_status);
      s.w_market_analyzer = ShortName(m_last.gold_monitor_summary);
      s.w_news_analyzer = StringFormat("%.0f%%", m_last.confidence);
      s.decision_status = m_last.engine_status;
      s.w_trade_confidence = StringFormat("%.0f%%", m_last.confidence);
      s.ai_version = GM_NEWS_NO_TRADE_BLOCK;
     }
  };

#endif // GM_CAI_NEWS_ENGINE_MQH
//+------------------------------------------------------------------+
