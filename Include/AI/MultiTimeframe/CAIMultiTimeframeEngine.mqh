//+------------------------------------------------------------------+
//|                          CAIMultiTimeframeEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 5 Sprint 5 — Multi-Timeframe Intelligence Facade      |
//+------------------------------------------------------------------+
#ifndef GM_CAI_MULTI_TIMEFRAME_ENGINE_MQH
#define GM_CAI_MULTI_TIMEFRAME_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "MultiTimeframeConstants.mqh"
#include "SGmMultiTimeframeResult.mqh"
#include "CAIMultiTimeframeIntelligence.mqh"
#include "CTrendSynchronizationEngine.mqh"
#include "CH4ExecutionContextEngine.mqh"
#include "CTimeframeCorrelationEngine.mqh"
#include "CConfluenceEngine.mqh"
#include "CFutureMultiTimeframeInterfaces.mqh"
#include "CMultiTimeframeDatabase.mqh"
#include "CMultiTimeframeScheduler.mqh"
#include "../Trend/CAITrendEngine.mqh"
#include "../Volatility/CAIVolatilityEngine.mqh"
#include "../OrderFlow/CAIOrderFlowIntelligenceEngine.mqh"
#include "../NewsIntelligence/CAINewsIntelligenceEngine.mqh"
#include "../RecoveryIntelligence/CAIRecoveryIntelligenceEngine.mqh"
#include "../MarketIntelligence/CAIMarketIntelligenceEngine.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../SGmAISnapshot.mqh"

class CGmAIMultiTimeframeEngine
  {
private:
   CGmLogger             *m_logger;
   CGmPhase2Bridge       *m_bridge;
   CGmAITrendEngine      *m_trend;
   CGmAIVolatilityEngine *m_vol;
   CGmAIOrderFlowIntelligenceEngine *m_orderflow;
   CGmAINewsIntelligenceEngine *m_newsintel;
   CGmAIRecoveryIntelligenceEngine *m_recintel;
   CGmAIMarketIntelligenceEngine *m_mktintel;

   CGmAIMultiTimeframeIntelligence m_mtf;
   CGmTrendSynchronizationEngine   m_sync;
   CGmH4ExecutionContextEngine     m_context;
   CGmTimeframeCorrelationEngine   m_corr;
   CGmConfluenceEngine             m_confluence;
   CGmFutureMultiTimeframeLayer    m_future;
   CGmMultiTimeframeDatabase       m_db;
   CGmMultiTimeframeScheduler       m_sched;

   SGmMultiTimeframeResult m_last;
   long                    m_magic;
   bool                    m_ready;

public:
                     CGmAIMultiTimeframeEngine(void)
                       : m_logger(NULL), m_bridge(NULL), m_trend(NULL), m_vol(NULL),
                         m_orderflow(NULL), m_newsintel(NULL), m_recintel(NULL),
                         m_mktintel(NULL), m_magic(0), m_ready(false)
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
      m_magic = magic;
      m_db.Init(logger, files, magic, symbol);
      m_sched.Reset();
      m_last.Reset();
      m_ready = true;
      if(m_logger != NULL)
        {
         m_logger.Success("Multi-Timeframe Intelligence Started | " + GM_MTF_VERSION +
                          " | " + GM_MTF_ANALYSIS_ONLY, "AIMTF");
         m_logger.Info("POLICY | " + GM_MTF_ADVISORY, "AIMTF");
         m_logger.Info("RULE | " + GM_MTF_H4_RULE, "AIMTF");
         m_logger.Info(m_future.Banner(), "AIMTF");
        }
      return true;
     }

   void BindSources(CGmAITrendEngine *trend,
                    CGmAIVolatilityEngine *vol,
                    CGmAIOrderFlowIntelligenceEngine *orderflow,
                    CGmAINewsIntelligenceEngine *newsintel,
                    CGmAIRecoveryIntelligenceEngine *recintel,
                    CGmAIMarketIntelligenceEngine *mktintel)
     {
      m_trend = trend;
      m_vol = vol;
      m_orderflow = orderflow;
      m_newsintel = newsintel;
      m_recintel = recintel;
      m_mktintel = mktintel;
      if(m_logger != NULL)
         m_logger.Info("MTF sources bound | Trend+Vol+OrderFlow+NewsIntel+RecIntel+MarketIntel", "AIMTF");
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmMultiTimeframeResult Last(void) const { return m_last; }
   CGmFutureMultiTimeframeLayer *FutureLayer(void) { return GetPointer(m_future); }

   bool Analyze(void)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      m_sched.Signal();
      if(!m_sched.ShouldRun(now, GM_MTF_THROTTLE_MS))
        {
         if(m_last.valid && m_sched.CacheValid(now))
           {
            m_last.from_cache = true;
            m_last.status = GM_MTF_STATUS_CACHED;
            return true;
           }
         return m_last.valid;
        }

      m_sched.Begin(now);

      SGmMultiTimeframeResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.status = GM_MTF_STATUS_RUNNING;
      r.may_execute = false;
      r.may_modify_risk = false;
      r.advisory_status = GM_MTF_ADVISORY;

      if(m_bridge != NULL)
        {
         r.symbol = m_bridge.Symbol();
         r.session_id = m_bridge.SessionId();
        }
      if(StringLen(r.symbol) == 0)
        {
         r.status = GM_MTF_STATUS_ERROR;
         m_sched.Complete(now);
         return false;
        }

      SGmTrendAnalysisResult trend;
      SGmVolatilityAnalysisResult vol;
      SGmOrderFlowResult of;
      SGmNewsIntelligenceResult ni;
      SGmRecoveryIntelligenceResult ri;
      SGmMarketIntelligenceResult mi;
      trend.Reset(); vol.Reset(); of.Reset(); ni.Reset(); ri.Reset(); mi.Reset();
      if(m_trend != NULL && m_trend.IsReady()) trend = m_trend.Last();
      if(m_vol != NULL && m_vol.IsReady()) vol = m_vol.Last();
      if(m_orderflow != NULL && m_orderflow.IsReady()) of = m_orderflow.Last();
      if(m_newsintel != NULL && m_newsintel.IsReady()) ni = m_newsintel.Last();
      if(m_recintel != NULL && m_recintel.IsReady()) ri = m_recintel.Last();
      if(m_mktintel != NULL && m_mktintel.IsReady()) mi = m_mktintel.Last();

      m_mtf.Analyze(r.symbol, trend, r);
      if(m_logger != NULL)
         m_logger.Info("Timeframe Analysis Completed | Overall=" +
                       GmMtfBiasName(r.overall_market_bias), "AIMTF");

      m_sync.Analyze(trend, vol, mi, r, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Synchronization Updated | Sync=%.0f",
                                    r.synchronization_score), "AIMTF");

      m_context.Analyze(trend, vol, of, ni, ri, mi, r, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Context Generated | Score=%.0f Grade=%s",
                                    r.execution_context_score,
                                    GmMtfGradeName(r.market_context_grade)), "AIMTF");

      m_corr.Analyze(vol, r, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Correlation Updated | Index=%.0f",
                                    r.correlation_index), "AIMTF");

      m_confluence.Analyze(trend, vol, of, ni, ri, mi, r, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Confluence Calculated | Score=%.0f",
                                    r.confluence_score), "AIMTF");

      r.center_status = "MTF INTEL READY";
      r.status = GM_MTF_STATUS_READY;
      r.insight = StringFormat("%s | Bias=%s Sync=%.0f Conf=%.0f Ctx=%.0f(%s) | %s",
                               r.center_status,
                               GmMtfBiasName(r.overall_market_bias),
                               r.synchronization_score, r.confluence_score,
                               r.execution_context_score,
                               GmMtfGradeName(r.market_context_grade),
                               GM_MTF_ADVISORY);
      r.valid = true;

      m_db.Record(r);
      m_last = r;
      m_sched.Complete(GetTickCount());

      if(m_logger != NULL)
         m_logger.Info("Dashboard Refreshed | MTF pending=" +
                       IntegerToString(m_sched.Pending()), "AIMTF");
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = m_last.center_status;
      s.ai_engine = "GoldMind AI Multi-Timeframe Intelligence";
      s.current_mode = "AI_MTF_INTEL";
      s.confidence_pct = m_last.confluence_confidence;
      s.confidence_status = StringFormat("%.0f", m_last.confluence_confidence);

      // Phase 5 Sprint 5 widgets (last-wins)
      s.w_trend_detector = GmMtfBiasName(m_last.higher_tf_bias);                 // Higher TF Bias
      s.future_ai_score = GmMtfBiasName(m_last.lower_tf_bias);                   // Lower TF Bias
      s.w_recovery_ai = StringFormat("%.0f", m_last.synchronization_score);      // Synchronization
      s.prediction_status = StringFormat("%.0f", m_last.confluence_score);       // Confluence
      s.learning_status = StringFormat("%.0f | %s",
                                       m_last.execution_context_score,
                                       GmMtfGradeName(m_last.market_context_grade)); // Execution Context
      s.w_volatility_scanner = StringFormat("%.0f", m_last.correlation_index);   // Correlation Index
      s.w_market_analyzer = StringFormat("%.0f", m_last.timeframe_agreement);    // TF Agreement
      s.w_news_analyzer = StringFormat("%.0f", m_last.timeframe_conflict);       // TF Conflict
      s.w_trade_confidence = GmMtfBiasName(m_last.overall_market_bias);          // Overall Market Bias
      s.ai_version = StringFormat("Hist=%.0f", m_last.historical_similarity);    // Historical Match
      s.decision_status = GM_MTF_ADVISORY;
     }
  };

#endif // GM_CAI_MULTI_TIMEFRAME_ENGINE_MQH
//+------------------------------------------------------------------+
