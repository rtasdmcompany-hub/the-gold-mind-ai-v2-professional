//+------------------------------------------------------------------+
//|                            CAIConversationalAssistantEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 4 Sprint 5 — Conversational Assistant Facade          |
//+------------------------------------------------------------------+
#ifndef GM_CAI_CONVERSATIONAL_ASSISTANT_ENGINE_MQH
#define GM_CAI_CONVERSATIONAL_ASSISTANT_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ConversationAIConstants.mqh"
#include "SGmConversationResult.mqh"
#include "CAICommandSecurityLayer.mqh"
#include "CAIChatContextManager.mqh"
#include "CAIKnowledgeRetrievalEngine.mqh"
#include "CAIExplanationFramework.mqh"
#include "CAIConversationEngine.mqh"
#include "CFutureVoiceInterfaces.mqh"
#include "CConversationDatabase.mqh"
#include "CConversationResponseCache.mqh"
#include "../Volatility/CAIVolatilityEngine.mqh"
#include "../Assistant/CAISupervisorEngine.mqh"
#include "../Intelligence/CAIDecisionIntelligenceEngine.mqh"
#include "../Memory/CAILearningMemoryEngine.mqh"
#include "../Reporting/CAIEnterpriseReportingEngine.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../SGmAISnapshot.mqh"

class CGmAIConversationalAssistantEngine
  {
private:
   CGmLogger             *m_logger;
   CGmPhase2Bridge       *m_bridge;
   CGmAIVolatilityEngine *m_vol;
   CGmAISupervisorEngine *m_supervisor;
   CGmAIDecisionIntelligenceEngine *m_intel;
   CGmAILearningMemoryEngine *m_memlearn;
   CGmAIEnterpriseReportingEngine *m_aireport;

   CGmAIKnowledgeRetrievalEngine m_retrieve;
   CGmAIConversationEngine       m_converse;
   CGmAIChatContextManager       m_ctx;
   CGmConversationDatabase       m_db;
   CGmConversationResponseCache  m_cache;
   CGmFutureVoiceAssistantLayer  m_voice;

   SGmConversationResult m_last;
   string                m_forced_query;
   long                  m_magic;
   ulong                 m_last_ms;
   bool                  m_ready;

   string DefaultStatusQuery(void) const
     {
      return "How is Gold Mind today?";
     }

public:
                     CGmAIConversationalAssistantEngine(void)
                       : m_logger(NULL), m_bridge(NULL), m_vol(NULL),
                         m_supervisor(NULL), m_intel(NULL), m_memlearn(NULL),
                         m_aireport(NULL), m_forced_query(""), m_magic(0),
                         m_last_ms(0), m_ready(false)
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
      m_forced_query = "";
      m_last.Reset();
      m_ready = true;
      if(m_logger != NULL)
        {
         m_logger.Success("AI Assistant Started | " + GM_CHAT_VERSION +
                          " | " + GM_CHAT_ANALYSIS_ONLY, "AIChat");
         m_logger.Info("POLICY | " + GM_CHAT_ADVISORY, "AIChat");
         m_logger.Info(m_voice.Banner(), "AIChat");
        }
      return true;
     }

   void BindSources(CGmAIVolatilityEngine *vol,
                    CGmAISupervisorEngine *supervisor,
                    CGmAIDecisionIntelligenceEngine *intel,
                    CGmAILearningMemoryEngine *memlearn,
                    CGmAIEnterpriseReportingEngine *aireport)
     {
      m_vol = vol;
      m_supervisor = supervisor;
      m_intel = intel;
      m_memlearn = memlearn;
      m_aireport = aireport;
      if(m_logger != NULL)
         m_logger.Info("Assistant sources bound | Vol+Supervisor+Intel+Memory+Reporting",
                       "AIChat");
     }

   /// @brief Optional external query (API / inbox). Informational only.
   void Ask(const string query)
     {
      m_forced_query = query;
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmConversationResult Last(void) const { return m_last; }
   CGmFutureVoiceAssistantLayer *VoiceLayer(void) { return GetPointer(m_voice); }

   bool Analyze(void)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_CHAT_THROTTLE_MS &&
         m_last.valid && StringLen(m_forced_query) == 0)
        {
         m_last.from_cache = true;
         m_last.status = GM_CHAT_STATUS_CACHED;
         return true;
        }
      m_last_ms = now;

      SGmConversationResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();
      r.status = GM_CHAT_STATUS_RUNNING;
      r.may_execute = false;
      r.may_modify_orders = false;
      r.may_modify_risk = false;
      r.voice_activated = false;
      r.voice_status = m_voice.Banner();
      r.advisory_status = GM_CHAT_ADVISORY;

      if(m_bridge != NULL)
        {
         r.symbol = m_bridge.Symbol();
         r.session_id = m_bridge.SessionId();
        }
      if(StringLen(r.symbol) == 0)
        {
         r.status = GM_CHAT_STATUS_ERROR;
         return false;
        }

      SGmVolatilityAnalysisResult vol;
      SGmAssistantResult sup;
      SGmIntelligenceResult intel;
      SGmMemoryLearningResult mem;
      SGmReportingResult rpt;
      vol.Reset(); sup.Reset(); intel.Reset(); mem.Reset(); rpt.Reset();
      if(m_vol != NULL && m_vol.IsReady()) vol = m_vol.Last();
      if(m_supervisor != NULL && m_supervisor.IsReady()) sup = m_supervisor.Last();
      if(m_intel != NULL && m_intel.IsReady()) intel = m_intel.Last();
      if(m_memlearn != NULL && m_memlearn.IsReady()) mem = m_memlearn.Last();
      if(m_aireport != NULL && m_aireport.IsReady()) rpt = m_aireport.Last();

      m_ctx.SetMarketContext(intel.valid ? intel.market_score_condition : "—");
      m_ctx.SetSessionContext(StringFormat("SID=%I64u", r.session_id));

      if(m_logger != NULL)
         m_logger.Info("Knowledge Retrieval Completed", "AIChat");
      m_retrieve.Retrieve(intel, sup, mem, rpt, r);

      string query = m_forced_query;
      if(StringLen(query) == 0)
         query = m_db.TryReadInbox();
      if(StringLen(query) == 0)
         query = DefaultStatusQuery();
      m_forced_query = "";

      if(m_logger != NULL)
         m_logger.Info("User Query Received | " + query, "AIChat");

      string cached = "";
      if(m_cache.TryGet(query, now, cached))
        {
         r.user_query = query;
         r.ai_response = cached;
         r.short_response = StringLen(cached) > 120 ? StringSubstr(cached, 0, 117) + "..." : cached;
         r.intent = GM_CHAT_INTENT_GENERAL;
         r.security_status = GM_CHAT_SEC_ALLOW;
         r.status = GM_CHAT_STATUS_CACHED;
         r.from_cache = true;
        }
      else
        {
         m_converse.Respond(query, vol, intel, sup, r);
         m_cache.Store(query, r.ai_response, now);
         if(m_logger != NULL)
           {
            m_logger.Info("Security Validation Completed | " + GmChatSecName(r.security_status),
                          "AIChat");
            m_logger.Info("Response Generated | intent=" + GmChatIntentName(r.intent), "AIChat");
           }
        }

      m_ctx.Push(r.user_query, r.short_response);
      r.context_summary = m_ctx.Summary();
      if(m_logger != NULL)
         m_logger.Info("Context Updated", "AIChat");

      r.assistant_status = (r.status == GM_CHAT_STATUS_BLOCKED) ? "ASSISTANT BLOCKED"
                                                                : "ASSISTANT READY";
      r.insight = StringFormat("%s | Q=%s | %s",
                               r.assistant_status, r.user_query, r.short_response);
      r.valid = true;

      m_db.Record(r);
      if(m_logger != NULL)
         m_logger.Info("Conversation Saved", "AIChat");

      m_last = r;
      if(m_logger != NULL)
         m_logger.Info("Dashboard Assistant Updated", "AIChat");
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = m_last.assistant_status;
      s.ai_engine = "GoldMind AI Conversational Assistant";
      s.current_mode = "AI_ASSISTANT";
      s.confidence_pct = 0.0;
      s.confidence_status = GmChatSecName(m_last.security_status);

      // Assistant Center widgets (last-wins)
      s.w_trend_detector = m_last.short_response;                 // AI Chat Window
      s.future_ai_score = m_last.market_answer;                   // Market Question Panel
      s.w_recovery_ai = m_last.report_answer;                     // Report Explanation
      s.prediction_status = m_last.risk_answer;                   // Risk Explanation
      s.learning_status = m_last.performance_answer;              // Performance Discussion
      s.w_volatility_scanner = m_last.learning_answer;            // Learning Insights
      s.w_market_analyzer = m_last.health_answer;                 // System Health Explanation
      s.w_news_analyzer = m_last.user_query;                      // Last Query
      s.w_trade_confidence = m_last.voice_status;                 // Voice foundation status
      s.ai_version = GmChatIntentName(m_last.intent);
      s.decision_status = GM_CHAT_ADVISORY;
     }
  };

#endif // GM_CAI_CONVERSATIONAL_ASSISTANT_ENGINE_MQH
//+------------------------------------------------------------------+
