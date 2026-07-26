//+------------------------------------------------------------------+
//|                                            CAITrendEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     Phase 3 Sprint 3 — AI Trend Detection Engine                |
//+------------------------------------------------------------------+
#ifndef GM_CAI_TREND_ENGINE_MQH
#define GM_CAI_TREND_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "TrendAIConstants.mqh"
#include "SGmTrendAnalysisResult.mqh"
#include "CTrendStrengthAnalyzer.mqh"
#include "CMarketStructureEngine.mqh"
#include "CTrendPhaseClassifier.mqh"
#include "CMultiTimeframeTrend.mqh"
#include "CTrendEventEngine.mqh"
#include "CTrendHistoryDatabase.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../SGmAISnapshot.mqh"

/// @file CAITrendEngine.mqh
/// @brief Multi-TF trend + structure intelligence — ANALYSIS ONLY.

class CGmAITrendEngine
  {
private:
   CGmLogger                 *m_logger;
   CGmPhase2Bridge           *m_bridge;
   CGmTrendStrengthAnalyzer   m_strength;
   CGmMarketStructureEngine   m_structure;
   CGmTrendPhaseClassifier    m_phase;
   CGmMultiTimeframeTrend     m_mtf;
   CGmTrendEventEngine        m_events;
   CGmTrendHistoryDatabase    m_db;
   SGmTrendAnalysisResult     m_last;
   SGmTrendAnalysisResult     m_prev;
   ulong                      m_last_ms;
   int                        m_duration_bars;
   datetime                   m_h4_bar;
   bool                       m_ready;

public:
                     CGmAITrendEngine(void)
                       : m_logger(NULL), m_bridge(NULL), m_last_ms(0),
                         m_duration_bars(0), m_h4_bar(0), m_ready(false)
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
      m_events.Init(logger);
      m_db.Init(logger, files, magic, symbol);
      m_last.Reset();
      m_prev.Reset();
      m_last_ms = 0;
      m_duration_bars = 0;
      m_h4_bar = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Success("AI Trend Engine ready | ANALYSIS ONLY | " + GM_TREND_AI_VERSION,
                          "AITrend");
      return true;
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmTrendAnalysisResult Last(void) const { return m_last; }
   CGmTrendEventEngine *Events(void) { return GetPointer(m_events); }

   bool Analyze(void)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_TREND_THROTTLE_MS && m_last.valid)
         return true;
      m_last_ms = now;

      if(m_logger != NULL)
         m_logger.Info("Trend Analysis Started", "AITrend");

      SGmTrendAnalysisResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.prev_primary = m_last.valid ? m_last.primary : GM_TREND_DIR_UNKNOWN;

      if(m_bridge != NULL)
        {
         r.symbol = m_bridge.Symbol();
         r.session_id = m_bridge.SessionId();
        }
      if(StringLen(r.symbol) == 0)
        {
         if(m_logger != NULL)
            m_logger.Warning("Trend analysis aborted | no symbol", "AITrend");
         return false;
        }

      m_strength.AnalyzeTF(r.symbol, PERIOD_H4, r.h4);
      m_strength.AnalyzeTF(r.symbol, PERIOD_D1, r.d1);
      m_strength.AnalyzeTF(r.symbol, PERIOD_W1, r.w1);
      m_strength.AnalyzeTF(r.symbol, PERIOD_MN1, r.mn1);
      m_strength.Aggregate(r);
      m_mtf.Compare(r);
      m_structure.Analyze(r.symbol, r);
      m_phase.Classify(r);

      // Duration tracking on H4 bar change
      const datetime h4 = iTime(r.symbol, PERIOD_H4, 0);
      if(h4 > 0 && h4 != m_h4_bar)
        {
         m_h4_bar = h4;
         if(m_last.valid && m_last.primary == r.primary && r.primary != GM_TREND_DIR_UNKNOWN)
            m_duration_bars++;
         else
            m_duration_bars = 1;
        }
      r.trend_duration_bars = m_duration_bars;
      if(m_last.valid && m_last.primary != r.primary)
         r.last_trend_change = r.stamped_at;
      else
         r.last_trend_change = m_last.valid ? m_last.last_trend_change : r.stamped_at;

      r.insight = StringFormat("%s | %s | str=%.0f | agree=%.0f | %s",
                               GmTrendPhaseName(r.phase),
                               GmTrendDirName(r.primary),
                               r.strength_score,
                               r.agreement_score,
                               GmTrendStructName(r.structure));
      r.valid = true;

      m_events.Evaluate(r, m_last);
      m_db.Record(r);

      m_prev = m_last;
      m_last = r;

      if(m_logger != NULL)
        {
         m_logger.Info("Trend Updated | " + r.insight, "AITrend");
         m_logger.Info(StringFormat("Trend Confidence Updated | %.0f", r.confidence), "AITrend");
         if(r.bos_up || r.bos_down)
            m_logger.Info(r.bos_up ? "BOS Detected | Up" : "BOS Detected | Down", "AITrend");
         if(r.choch_up || r.choch_down)
            m_logger.Info(r.choch_up ? "CHOCH Detected | Up" : "CHOCH Detected | Down", "AITrend");
         if(m_prev.valid && m_prev.primary != r.primary)
            m_logger.Info("Trend Reversal Detected", "AITrend");
        }
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = "TREND READY";
      s.ai_engine = "GoldMind Trend AI";
      s.current_mode = "TREND_ANALYSIS";
      s.decision_status = StringFormat("%d bars", m_last.trend_duration_bars);
      s.confidence_status = StringFormat("%.0f%%", m_last.confidence);
      s.confidence_pct = m_last.confidence;
      s.w_trend_detector = GmTrendDirName(m_last.primary);
      s.future_ai_score = StringFormat("%.0f", m_last.strength_score);
      s.w_recovery_ai = GmTrendStructName(m_last.structure);
      s.prediction_status = StringFormat("BOS %s",
                                         (m_last.bos_up || m_last.bos_down) ? "YES" : "NO");
      s.learning_status = StringFormat("CHOCH %s",
                                       (m_last.choch_up || m_last.choch_down) ? "YES" : "NO");
      s.w_volatility_scanner = StringFormat("Agree %.0f", m_last.agreement_score);
      s.w_news_analyzer = GmTrendDirName(m_last.higher_tf_bias);
      s.w_trade_confidence = StringFormat("%.0f%%", m_last.confidence);
      s.w_market_analyzer = (m_last.last_trend_change > 0)
                            ? TimeToString(m_last.last_trend_change, TIME_DATE | TIME_MINUTES)
                            : "—";
      s.ai_version = GmTrendPhaseName(m_last.phase);
     }
  };

#endif // GM_CAI_TREND_ENGINE_MQH
//+------------------------------------------------------------------+
