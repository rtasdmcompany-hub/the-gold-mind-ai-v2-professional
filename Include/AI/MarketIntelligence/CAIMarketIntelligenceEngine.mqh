//+------------------------------------------------------------------+
//|                              CAIMarketIntelligenceEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 5 Sprint 1 — Market Intelligence Facade               |
//+------------------------------------------------------------------+
#ifndef GM_CAI_MARKET_INTELLIGENCE_ENGINE_MQH
#define GM_CAI_MARKET_INTELLIGENCE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "MarketIntelligenceConstants.mqh"
#include "SGmMarketIntelligenceResult.mqh"
#include "CSmartMarketStructureEngine.mqh"
#include "CAIMomentumEngine.mqh"
#include "CAILiquidityEngine.mqh"
#include "CInstitutionalMarketAnalyzer.mqh"
#include "CAIMarketIntelligenceCore.mqh"
#include "CFutureInstitutionalInterfaces.mqh"
#include "CMarketIntelligenceDatabase.mqh"
#include "CMarketIntelligenceScheduler.mqh"
#include "../Trend/CAITrendEngine.mqh"
#include "../Volatility/CAIVolatilityEngine.mqh"
#include "../News/CAINewsEngine.mqh"
#include "../Assistant/CAISupervisorEngine.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../SGmAISnapshot.mqh"

class CGmAIMarketIntelligenceEngine
  {
private:
   CGmLogger             *m_logger;
   CGmPhase2Bridge       *m_bridge;
   CGmAITrendEngine      *m_trend;
   CGmAIVolatilityEngine *m_vol;
   CGmAINewsEngine       *m_news;
   CGmAISupervisorEngine *m_supervisor;

   CGmSmartMarketStructureEngine m_structure;
   CGmAIMomentumEngine           m_momentum;
   CGmAILiquidityEngine          m_liquidity;
   CGmInstitutionalMarketAnalyzer m_institutional;
   CGmAIMarketIntelligenceCore   m_core;
   CGmFutureInstitutionalLayer   m_future;
   CGmMarketIntelligenceDatabase m_db;
   CGmMarketIntelligenceScheduler m_sched;

   SGmMarketIntelligenceResult m_last;
   long                        m_magic;
   bool                        m_ready;

public:
                     CGmAIMarketIntelligenceEngine(void)
                       : m_logger(NULL), m_bridge(NULL), m_trend(NULL), m_vol(NULL),
                         m_news(NULL), m_supervisor(NULL), m_magic(0), m_ready(false)
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
         m_logger.Success("Market Intelligence Engine Started | " + GM_MI_VERSION +
                          " | " + GM_MI_ANALYSIS_ONLY, "AIMI");
         m_logger.Info("POLICY | " + GM_MI_ADVISORY, "AIMI");
         m_logger.Info(m_future.Banner(), "AIMI");
        }
      return true;
     }

   void BindSources(CGmAITrendEngine *trend,
                    CGmAIVolatilityEngine *vol,
                    CGmAINewsEngine *news,
                    CGmAISupervisorEngine *supervisor)
     {
      m_trend = trend;
      m_vol = vol;
      m_news = news;
      m_supervisor = supervisor;
      if(m_logger != NULL)
         m_logger.Info("Market Intelligence sources bound | Trend+Vol+News+Supervisor", "AIMI");
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmMarketIntelligenceResult Last(void) const { return m_last; }
   CGmFutureInstitutionalLayer *FutureLayer(void) { return GetPointer(m_future); }

   bool Analyze(void)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      m_sched.Signal();
      if(!m_sched.ShouldRun(now, GM_MI_THROTTLE_MS))
        {
         if(m_last.valid && m_sched.CacheValid(now))
           {
            m_last.from_cache = true;
            m_last.status = GM_MI_STATUS_CACHED;
            return true;
           }
         return m_last.valid;
        }

      m_sched.Begin(now);

      SGmMarketIntelligenceResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.status = GM_MI_STATUS_RUNNING;
      r.may_execute = false;
      r.may_modify_risk = false;
      r.advisory_status = GM_MI_ADVISORY;

      if(m_bridge != NULL)
        {
         r.symbol = m_bridge.Symbol();
         r.session_id = m_bridge.SessionId();
        }
      if(StringLen(r.symbol) == 0)
        {
         r.status = GM_MI_STATUS_ERROR;
         m_sched.Complete(now);
         return false;
        }

      SGmTrendAnalysisResult trend;
      SGmVolatilityAnalysisResult vol;
      SGmNewsAnalysisResult news;
      SGmAssistantResult sup;
      trend.Reset(); vol.Reset(); news.Reset(); sup.Reset();
      if(m_trend != NULL && m_trend.IsReady()) trend = m_trend.Last();
      if(m_vol != NULL && m_vol.IsReady()) vol = m_vol.Last();
      if(m_news != NULL && m_news.IsReady()) news = m_news.Last();
      if(m_supervisor != NULL && m_supervisor.IsReady()) sup = m_supervisor.Last();

      m_structure.Analyze(trend, r);
      if(m_logger != NULL)
         m_logger.Info("Market Structure Updated | " + GmMiStructureName(r.structure_type), "AIMI");

      m_momentum.Analyze(trend, vol, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Momentum Calculated | Index=%.0f", r.momentum_index), "AIMI");

      m_liquidity.Analyze(trend, vol, sup, r);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Liquidity Updated | Score=%.0f", r.liquidity_score), "AIMI");

      m_institutional.Analyze(trend, vol, r, r);
      if(m_logger != NULL)
         m_logger.Info("Institutional Analysis Updated | " +
                       GmMiInstPhaseName(r.institutional_phase), "AIMI");

      m_core.Analyze(vol, news, r);
      if(m_logger != NULL)
         m_logger.Info("Market Intelligence Generated", "AIMI");

      r.intelligence_status = "MARKET INTEL READY";
      r.status = GM_MI_STATUS_READY;
      r.insight = StringFormat("%s | Struct=%s Mom=%.0f Liq=%.0f BO=%.0f%% Rev=%.0f%% Phase=%s | %s",
                               r.intelligence_status,
                               GmMiStructureName(r.structure_type),
                               r.momentum_index, r.liquidity_score,
                               r.breakout_probability, r.reversal_probability,
                               GmMiInstPhaseName(r.institutional_phase),
                               GM_MI_ANALYSIS_ONLY);
      r.valid = true;

      m_db.Record(r);
      m_last = r;
      m_sched.Complete(GetTickCount());

      if(m_logger != NULL)
         m_logger.Info("Dashboard Updated | Market Intelligence pending=" +
                       IntegerToString(m_sched.Pending()), "AIMI");
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = m_last.intelligence_status;
      s.ai_engine = "GoldMind AI Market Intelligence";
      s.current_mode = "AI_MARKET_INTEL";
      s.confidence_pct = GmMiClamp(0.4 * m_last.momentum_index + 0.3 * m_last.liquidity_score +
                                   0.3 * m_last.structure_quality);
      s.confidence_status = StringFormat("%.0f", s.confidence_pct);

      // Phase 5 Sprint 1 widgets (last-wins)
      s.w_trend_detector = StringFormat("Struct=%.0f Energy=%.0f Vol=%.0f",
                                        m_last.market_structure_score,
                                        m_last.market_energy,
                                        m_last.volatility_score);              // Market Intelligence
      s.future_ai_score = StringFormat("%s | Bias=%.0f",
                                       GmMiInstPhaseName(m_last.institutional_phase),
                                       m_last.institutional_bias);             // Institutional Bias
      s.w_recovery_ai = StringFormat("%.0f/100", m_last.momentum_index);       // Momentum Index
      s.prediction_status = StringFormat("%.0f/100", m_last.liquidity_score);  // Liquidity Score
      s.learning_status = GmMiStructureName(m_last.structure_type);            // Market Structure
      s.w_volatility_scanner = StringFormat("%.0f%%", m_last.breakout_probability); // Breakout Prob
      s.w_market_analyzer = StringFormat("%.0f%%", m_last.reversal_probability);    // Reversal Prob
      s.w_news_analyzer = StringFormat("%.0f", m_last.market_energy);          // Market Energy
      s.w_trade_confidence = m_last.institutional_activity;                    // Institutional Activity
      s.ai_version = m_last.intelligence_status;                               // AI Intelligence Status
      s.decision_status = GM_MI_ADVISORY;
     }
  };

#endif // GM_CAI_MARKET_INTELLIGENCE_ENGINE_MQH
//+------------------------------------------------------------------+
