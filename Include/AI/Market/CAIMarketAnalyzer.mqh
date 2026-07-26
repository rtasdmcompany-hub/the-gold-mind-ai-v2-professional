//+------------------------------------------------------------------+
//|                                          CAIMarketAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     Phase 3 Sprint 2 — AI Market Analysis Engine                |
//+------------------------------------------------------------------+
#ifndef GM_CAI_MARKET_ANALYZER_MQH
#define GM_CAI_MARKET_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "MarketAnalysisConstants.mqh"
#include "SGmMarketAnalysisResult.mqh"
#include "CMarketStructureAnalyzer.mqh"
#include "CPriceActionAnalyzer.mqh"
#include "CVolatilityAnalyzer.mqh"
#include "CMarketConditionClassifier.mqh"
#include "CMarketSnapshotEngine.mqh"
#include "CMarketAnalysisDatabase.mqh"
#include "../../Phase2/IPhase2Interfaces.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../SGmAISnapshot.mqh"

/// @file CAIMarketAnalyzer.mqh
/// @brief Independent market intelligence engine — ANALYSIS ONLY.
/// @implements IGmAIMarketAnalysis

class CGmAIMarketAnalyzer : public IGmAIMarketAnalysis
  {
private:
   CGmLogger                     *m_logger;
   CGmPhase2Bridge               *m_bridge;
   CGmMarketStructureAnalyzer     m_structure;
   CGmPriceActionAnalyzer         m_price_action;
   CGmVolatilityAnalyzer          m_volatility;
   CGmMarketConditionClassifier   m_condition;
   CGmMarketSnapshotEngine        m_snapshots;
   CGmMarketAnalysisDatabase      m_db;
   SGmMarketAnalysisResult        m_last;
   ulong                          m_last_ms;
   bool                           m_ready;

public:
                     CGmAIMarketAnalyzer(void)
                       : m_logger(NULL), m_bridge(NULL), m_last_ms(0), m_ready(false)
     {
      m_last.Reset();
     }

   bool Init(CGmLogger *logger,
             CGmFileManager *files,
             CGmPhase2Bridge *bridge,
             const long magic,
             const string symbol)
     {
      m_logger = logger;
      m_bridge = bridge;
      m_snapshots.Init(logger);
      m_db.Init(logger, files, magic, symbol);
      m_last.Reset();
      m_last_ms = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Success("AI Market Analyzer ready | ANALYSIS ONLY | " + GM_MKT_AI_VERSION,
                          "AIMarket");
      return true;
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmMarketAnalysisResult Last(void) const { return m_last; }

   virtual bool Analyze(void)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_MKT_THROTTLE_MS && m_last.valid)
         return true;
      m_last_ms = now;

      if(m_logger != NULL)
         m_logger.Info("Market Analysis Started", "AIMarket");

      SGmMarketAnalysisResult r;
      r.Reset();
      r.analysis_status = "Running";
      r.stamped_at = TimeCurrent();

      if(m_bridge != NULL)
        {
         r.symbol = m_bridge.Symbol();
         r.session_id = m_bridge.SessionId();
        }
      if(StringLen(r.symbol) == 0)
        {
         r.analysis_status = "Error";
         r.insight = "No symbol";
         m_last = r;
         if(m_logger != NULL)
            m_logger.Warning("Market Analysis error | no symbol", "AIMarket");
         return false;
        }

      r.bid = SymbolInfoDouble(r.symbol, SYMBOL_BID);
      r.ask = SymbolInfoDouble(r.symbol, SYMBOL_ASK);
      r.mid = (r.bid + r.ask) * 0.5;
      const double point = SymbolInfoDouble(r.symbol, SYMBOL_POINT);
      r.spread_points = (point > 0.0) ? (r.ask - r.bid) / point : 0.0;
      r.tick_volume = (long)iVolume(r.symbol, PERIOD_H4, 0);

      m_volatility.Analyze(r.symbol, r);
      m_structure.Analyze(r.symbol, r);
      m_price_action.Analyze(r.symbol, r);
      m_condition.Classify(r);

      r.insight = StringFormat("%s | %s | %s | mom=%.0f",
                               GmMktDirName(r.direction),
                               GmMktConditionName(r.condition),
                               GmMktPatternName(r.pattern),
                               r.momentum);
      r.analysis_status = "Completed";
      r.valid = true;
      m_last = r;

      m_db.Record(r);
      if(m_snapshots.MaybeSave(r) && m_logger != NULL)
         m_logger.Debug("H4 market snapshot stored", "AIMarket");

      if(m_logger != NULL)
        {
         m_logger.Info("Analysis Completed | " + r.insight, "AIMarket");
         m_logger.Info(StringFormat("Trend Updated | %s | strength=%.0f",
                                    GmMktDirName(r.direction), r.trend_strength),
                       "AIMarket");
         m_logger.Info(StringFormat("Volatility Updated | atr=%.5f ratio=%.2f",
                                    r.atr14, r.volatility_ratio),
                       "AIMarket");
         m_logger.Info(StringFormat("Confidence Updated | %.1f", r.confidence),
                       "AIMarket");
        }
      return true;
     }

   virtual double Confidence(void)
     {
      return m_last.confidence;
     }

   virtual string LastInsight(void)
     {
      return m_last.insight;
     }

   /// @brief Overlay market intelligence onto AI Dashboard snapshot (display only).
   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = "MARKET READY";
      s.ai_engine = "GoldMind Market AI";
      s.ai_version = GM_MKT_AI_VERSION;
      s.learning_status = "Observe";
      s.decision_status = m_last.analysis_status;
      s.prediction_status = GmMktConditionName(m_last.condition);
      s.confidence_status = StringFormat("%.0f%%", m_last.confidence);
      s.current_mode = "MARKET_ANALYSIS";
      s.future_ai_score = StringFormat("%.0f", m_last.trend_strength);
      s.confidence_pct = m_last.confidence;
      s.learning_status = StringFormat("%.0f", m_last.momentum);
      s.w_market_analyzer = TimeToString(m_last.stamped_at, TIME_DATE | TIME_SECONDS);
      s.w_trend_detector = GmMktDirName(m_last.direction);
      s.w_volatility_scanner = StringFormat("%.2fx | %s",
                                            m_last.volatility_ratio,
                                            m_last.expansion ? "EXP" : (m_last.contraction ? "CON" : "STD"));
      s.w_news_analyzer = GmMktPatternName(m_last.pattern);
      s.w_trade_confidence = StringFormat("%.0f%%", m_last.confidence);
      s.w_recovery_ai = GmMktStructName(m_last.structure);
      s.w_learning_engine = m_last.analysis_status;
      if(m_last.atr14 > 0.0)
         s.atr14 = m_last.atr14;
      s.spread_points = m_last.spread_points;
      s.candle_size_cur = m_last.candle_h4;
      s.daily_range = m_last.daily_range;
      s.weekly_range = m_last.weekly_range;
      s.market_volatility = (m_last.volatility_ratio >= 1.5) ? "HIGH"
                            : ((m_last.volatility_ratio <= 0.6) ? "LOW" : "NORMAL");
      s.market_activity = GmMktDirName(m_last.direction);
     }
  };

#endif // GM_CAI_MARKET_ANALYZER_MQH
//+------------------------------------------------------------------+
