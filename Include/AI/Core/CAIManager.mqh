//+------------------------------------------------------------------+
//|                                                 CAIManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CAI_MANAGER_MQH
#define GM_CAI_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CAIDataBus.mqh"
#include "CAIContextManager.mqh"
#include "CAIMemoryManager.mqh"
#include "CAIDecisionQueue.mqh"
#include "CAICoreDatabase.mqh"
#include "CAIStateManager.mqh"
#include "CAIEventDispatcher.mqh"
#include "CAIController.mqh"
#include "CAICoreApi.mqh"
#include "../../Logging/CLogger.mqh"

/// @file CAIManager.mqh
/// @brief Coordinates one analysis cycle (advisory only).

class CGmAIManager
  {
private:
   CGmLogger            *m_logger;
   CGmAIDataBus         *m_bus;
   CGmAIContextManager  *m_context;
   CGmAIMemoryManager   *m_memory;
   CGmAIDecisionQueue   *m_queue;
   CGmAICoreDatabase    *m_db;
   CGmAIStateManager    *m_state;
   CGmAIEventDispatcher *m_events;
   CGmAIController      *m_ctrl;
   CGmAICoreApi         *m_api;
   bool                  m_ready;

public:
                     CGmAIManager(void)
                       : m_logger(NULL), m_bus(NULL), m_context(NULL),
                         m_memory(NULL), m_queue(NULL), m_db(NULL),
                         m_state(NULL), m_events(NULL), m_ctrl(NULL),
                         m_api(NULL), m_ready(false) {}

   void Init(CGmLogger *logger,
             CGmAIDataBus *bus,
             CGmAIContextManager *context,
             CGmAIMemoryManager *memory,
             CGmAIDecisionQueue *queue,
             CGmAICoreDatabase *db,
             CGmAIStateManager *state,
             CGmAIEventDispatcher *events,
             CGmAIController *ctrl,
             CGmAICoreApi *api)
     {
      m_logger = logger;
      m_bus = bus;
      m_context = context;
      m_memory = memory;
      m_queue = queue;
      m_db = db;
      m_state = state;
      m_events = events;
      m_ctrl = ctrl;
      m_api = api;
      m_ready = true;
     }

   bool IsReady(void) const { return m_ready; }

   /// @brief Run one analysis-only cycle. Returns false if skipped/disabled.
   bool RunAnalysisCycle(void)
     {
      if(!m_ready || m_ctrl == NULL || !m_ctrl.CanAnalyze())
         return false;

      if(m_events != NULL)
         m_events.Dispatch("Analysis Started", "cycle");
      if(m_state != NULL)
         m_state.SetState(GM_AI_CORE_STATE_ANALYZING);

      SGmAIBusSnapshot snap;
      if(m_bus == NULL || !m_bus.Collect(snap) || !snap.valid)
        {
         if(m_state != NULL)
            m_state.SetState(GM_AI_CORE_STATE_WAITING);
         if(m_events != NULL)
            m_events.Dispatch("Analysis Finished", "no data");
         return false;
        }

      if(m_context != NULL)
         m_context.Update(snap);
      if(m_memory != NULL)
         m_memory.Push(snap);
      if(m_db != NULL)
        {
         m_db.RecordMarketSnapshot(snap);
         if(m_context != NULL)
            m_db.RecordConfidence(m_context.Confidence());
        }

      const SGmAICoreSettings cfg = m_ctrl.Settings();
      if(cfg.mode == GM_AI_CORE_MODE_LEARNING || cfg.learning_mode)
        {
         if(m_state != NULL)
            m_state.SetState(GM_AI_CORE_STATE_LEARNING);
         if(m_db != NULL)
            m_db.RecordLearning(StringFormat("learn | eq=%.2f wr=%.1f",
                                            snap.equity, snap.overall_win_rate));
        }

      // Sprint 1 advisory decision (never executed)
      const double conf = (m_context != NULL) ? m_context.Confidence() : 0.0;
      string kind = "HOLD_OBSERVE";
      string reason = "Phase3 Sprint1 baseline observation";
      if(snap.current_dd_pct >= 8.0)
        {
         kind = "ADVISORY_CAUTION";
         reason = "Elevated drawdown observed";
        }
      else if(snap.spread_points >= 400.0)
        {
         kind = "ADVISORY_SPREAD";
         reason = "Wide spread observed";
        }
      else if(conf >= 70.0)
        {
         kind = "ADVISORY_STABLE";
         reason = "Stable observation context";
        }

      if(m_queue != NULL)
         m_queue.Enqueue(kind, reason, conf);
      if(m_db != NULL)
        {
         SGmAIDecisionItem d;
         if(m_queue != NULL && m_queue.PeekLatest(d))
            m_db.RecordDecision(d);
         m_db.RecordPrediction(StringFormat("%s | %.1f", kind, conf));
        }

      if(m_api != NULL)
        {
         string payload = "";
         m_api.PreparePython(snap, conf, payload);
        }

      if(m_state != NULL)
         m_state.SetState(GM_AI_CORE_STATE_DECISION_READY);
      if(m_events != NULL)
         m_events.Dispatch("Analysis Finished",
                           StringFormat("%s | conf=%.1f", kind, conf));
      if(m_state != NULL)
         m_state.SetState(GM_AI_CORE_STATE_MONITORING);

      if(m_logger != NULL)
         m_logger.Debug(StringFormat("Analysis cycle | %s | conf=%.1f", kind, conf),
                        "AIManager");
      return true;
     }
  };

#endif // GM_CAI_MANAGER_MQH
//+------------------------------------------------------------------+
