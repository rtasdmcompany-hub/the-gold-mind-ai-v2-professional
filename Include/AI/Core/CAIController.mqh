//+------------------------------------------------------------------+
//|                                              CAIController.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CAI_CONTROLLER_MQH
#define GM_CAI_CONTROLLER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmAICoreSettings.mqh"
#include "CAIStateManager.mqh"
#include "CAISecurityGuard.mqh"
#include "CAIEventDispatcher.mqh"
#include "../../Logging/CLogger.mqh"

/// @file CAIController.mqh
/// @brief Mode / pause / enable control — never routes to trade execution.

class CGmAIController
  {
private:
   CGmLogger            *m_logger;
   SGmAICoreSettings     m_settings;
   CGmAIStateManager    *m_state;
   CGmAISecurityGuard   *m_security;
   CGmAIEventDispatcher *m_events;
   bool                  m_ready;

public:
                     CGmAIController(void)
                       : m_logger(NULL), m_state(NULL), m_security(NULL),
                         m_events(NULL), m_ready(false)
     {
      m_settings.Defaults();
     }

   void Init(CGmLogger *logger,
             CGmAIStateManager *state,
             CGmAISecurityGuard *security,
             CGmAIEventDispatcher *events,
             const SGmAICoreSettings &settings)
     {
      m_logger = logger;
      m_state = state;
      m_security = security;
      m_events = events;
      m_settings = settings;
      m_settings.Clamp();
      m_ready = true;
     }

   bool IsReady(void) const { return m_ready; }
   SGmAICoreSettings Settings(void) const { return m_settings; }

   void ApplySettings(const SGmAICoreSettings &settings)
     {
      m_settings = settings;
      m_settings.Clamp();
      if(!m_settings.enable_ai)
         Disable();
     }

   void Enable(void)
     {
      m_settings.enable_ai = true;
      m_settings.Clamp();
      if(m_state != NULL)
         m_state.SetState(GM_AI_CORE_STATE_MONITORING);
      if(m_events != NULL)
         m_events.Dispatch("AI Enabled", GmAICoreModeName(m_settings.mode));
     }

   void Disable(void)
     {
      m_settings.enable_ai = false;
      m_settings.mode = GM_AI_CORE_MODE_DISABLED;
      if(m_state != NULL)
         m_state.SetState(GM_AI_CORE_STATE_DISABLED);
      if(m_events != NULL)
         m_events.Dispatch("AI Disabled", "user/config");
     }

   void Pause(void)
     {
      if(m_state != NULL)
         m_state.SetState(GM_AI_CORE_STATE_PAUSED);
      if(m_events != NULL)
         m_events.Dispatch("AI Paused", "");
     }

   void Resume(void)
     {
      if(!m_settings.enable_ai)
         return;
      if(m_state != NULL)
         m_state.SetState(GM_AI_CORE_STATE_MONITORING);
      if(m_events != NULL)
         m_events.Dispatch("AI Resumed", GmAICoreModeName(m_settings.mode));
     }

   bool CanAnalyze(void) const
     {
      if(!m_ready || !m_settings.enable_ai)
         return false;
      if(m_security != NULL && !m_security.IsAnalysisOnly())
         return false;
      if(m_state == NULL)
         return false;
      const ENUM_GM_AI_CORE_STATE s = m_state.State();
      return (s != GM_AI_CORE_STATE_DISABLED &&
              s != GM_AI_CORE_STATE_PAUSED &&
              s != GM_AI_CORE_STATE_ERROR);
     }
  };

#endif // GM_CAI_CONTROLLER_MQH
//+------------------------------------------------------------------+
