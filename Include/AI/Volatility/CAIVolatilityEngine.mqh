//+------------------------------------------------------------------+
//|                                       CAIVolatilityEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     Phase 3 Sprint 4 — AI Volatility Intelligence Engine        |
//+------------------------------------------------------------------+
#ifndef GM_CAI_VOLATILITY_ENGINE_MQH
#define GM_CAI_VOLATILITY_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "VolatilityAIConstants.mqh"
#include "SGmVolatilityAnalysisResult.mqh"
#include "CAtrIntelligenceEngine.mqh"
#include "CVolatilityIntelligence.mqh"
#include "CMarketEnergyEngine.mqh"
#include "CVolatilityPhaseClassifier.mqh"
#include "CRangeAnalyzer.mqh"
#include "CMovementProbabilityEngine.mqh"
#include "CVolatilityEventEngine.mqh"
#include "CVolatilityHistoryDatabase.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../SGmAISnapshot.mqh"

/// @file CAIVolatilityEngine.mqh
/// @brief ATR / energy / range / movement probability — ANALYSIS ONLY.

class CGmAIVolatilityEngine
  {
private:
   CGmLogger                    *m_logger;
   CGmPhase2Bridge              *m_bridge;
   CGmAtrIntelligenceEngine      m_atr;
   CGmVolatilityIntelligence     m_vol;
   CGmMarketEnergyEngine         m_energy;
   CGmVolatilityPhaseClassifier  m_phase;
   CGmRangeAnalyzer              m_range;
   CGmMovementProbabilityEngine  m_prob;
   CGmVolatilityEventEngine      m_events;
   CGmVolatilityHistoryDatabase  m_db;
   SGmVolatilityAnalysisResult   m_last;
   SGmVolatilityAnalysisResult   m_prev;
   ulong                         m_last_ms;
   bool                          m_ready;

public:
                     CGmAIVolatilityEngine(void)
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
      m_events.Init(logger);
      m_db.Init(logger, files, magic, symbol);
      m_last.Reset();
      m_prev.Reset();
      m_last_ms = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Success("AI Volatility Engine ready | ANALYSIS ONLY | " + GM_VOL_AI_VERSION,
                          "AIVol");
      return true;
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmVolatilityAnalysisResult Last(void) const { return m_last; }
   CGmVolatilityEventEngine *Events(void) { return GetPointer(m_events); }

   bool Analyze(void)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_VOL_THROTTLE_MS && m_last.valid)
         return true;
      m_last_ms = now;

      if(m_logger != NULL)
         m_logger.Info("Volatility Analysis Started", "AIVol");

      SGmVolatilityAnalysisResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();

      if(m_bridge != NULL)
        {
         r.symbol = m_bridge.Symbol();
         r.session_id = m_bridge.SessionId();
        }
      if(StringLen(r.symbol) == 0)
        {
         if(m_logger != NULL)
            m_logger.Warning("Volatility analysis aborted | no symbol", "AIVol");
         return false;
        }

      if(!m_atr.Analyze(r.symbol, r))
        {
         if(m_logger != NULL)
            m_logger.Warning("ATR analysis failed | insufficient bars", "AIVol");
         return false;
        }

      m_vol.Analyze(r.symbol, r);
      m_energy.Analyze(r);
      m_phase.Classify(r);
      m_range.Analyze(r.symbol, r);
      m_prob.Analyze(r);

      r.confidence = GmClamp01(r.vol_confidence * 0.35 +
                               r.phase_confidence * 0.35 +
                               r.prob_confidence * 0.30);

      r.insight = StringFormat("%s | %s | ATR=%.5f | energy=%.0f | large=%.0f%%",
                               GmVolPhaseName(r.phase),
                               GmEnergyName(r.energy),
                               r.atr14,
                               r.energy_score,
                               r.prob_large_move);
      r.valid = true;

      m_events.Evaluate(r, m_last);
      m_db.Record(r);

      m_prev = m_last;
      m_last = r;

      if(m_logger != NULL)
        {
         m_logger.Info("ATR Updated | " + StringFormat("%.5f %s", r.atr14, GmAtrTrendName(r.atr_trend)),
                       "AIVol");
         m_logger.Info("Volatility Updated | " + StringFormat("rel=%.0f", r.relative_vol), "AIVol");
         m_logger.Info("Energy Updated | " + GmEnergyName(r.energy), "AIVol");
         m_logger.Info("Range Updated | " + StringFormat("H4=%.5f", r.range_h4), "AIVol");
         m_logger.Info("Probability Updated | " + StringFormat("large=%.0f", r.prob_large_move),
                       "AIVol");
         m_logger.Info(StringFormat("Vol Confidence Updated | %.0f", r.confidence), "AIVol");
        }
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = "VOL READY";
      s.ai_engine = "GoldMind Volatility AI";
      s.current_mode = "VOLATILITY_ANALYSIS";
      s.atr14 = m_last.atr14;
      s.confidence_pct = m_last.confidence;
      s.confidence_status = StringFormat("%.0f%%", m_last.confidence);
      s.w_trend_detector = StringFormat("%.5f", m_last.atr14);           // Current ATR
      s.future_ai_score = GmAtrTrendName(m_last.atr_trend);              // ATR Trend
      s.w_recovery_ai = StringFormat("%.0f", m_last.atr_strength);       // ATR Strength
      s.prediction_status = GmEnergyName(m_last.energy);                 // Market Energy
      s.learning_status = StringFormat("%.0f", m_last.energy_score);     // Energy Score
      s.w_volatility_scanner = GmVolPhaseName(m_last.phase);             // Volatility State
      s.w_market_analyzer = m_last.range_expansion ? "Expanding"
                            : (m_last.range_compression ? "Compressing" : "Balanced");
      s.w_news_analyzer = StringFormat("Large %.0f%%", m_last.prob_large_move);
      s.decision_status = m_last.atr_expansion ? "Expansion"
                          : (m_last.atr_compression ? "Compression" : "Neutral");
      s.w_trade_confidence = StringFormat("%.0f%%", m_last.confidence);
      s.ai_version = GmVolPhaseName(m_last.phase);
     }
  };

#endif // GM_CAI_VOLATILITY_ENGINE_MQH
//+------------------------------------------------------------------+
