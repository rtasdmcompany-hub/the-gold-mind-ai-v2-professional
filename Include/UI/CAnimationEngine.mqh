//+------------------------------------------------------------------+
//|                                         CAnimationEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CANIMATION_ENGINE_MQH
#define GM_CANIMATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../Logging/CLogger.mqh"

/// @file CAnimationEngine.mqh
/// @brief Lightweight optional UI animations (no trading side effects).

class CGmAnimationEngine
  {
private:
   CGmLogger *m_logger;
   bool       m_enabled;
   int        m_pulse_phase;
   datetime   m_last_tick;

public:
                     CGmAnimationEngine(void)
                       : m_logger(NULL), m_enabled(false), m_pulse_phase(0), m_last_tick(0)
     {
     }

   void Init(CGmLogger *logger, const bool enabled)
     {
      m_logger = logger;
      m_enabled = enabled;
      m_pulse_phase = 0;
      m_last_tick = 0;
     }

   bool Enabled(void) const { return m_enabled; }

   void SetEnabled(const bool on)
     {
      m_enabled = on;
      if(m_logger != NULL)
         m_logger.Info(on ? "Settings Updated | Animations ON" : "Settings Updated | Animations OFF",
                       "Animation");
     }

   void Toggle(void) { SetEnabled(!m_enabled); }

   /// @brief Advance pulse phase — returns 0..3 for status pulse styling.
   int TickPulse(void)
     {
      if(!m_enabled)
         return 0;
      const datetime now = TimeCurrent();
      if(now == m_last_tick)
         return m_pulse_phase;
      m_last_tick = now;
      m_pulse_phase = (m_pulse_phase + 1) % 4;
      return m_pulse_phase;
     }

   /// @brief Fade factor 0.0..1.0 for optional transparency modulation.
   double FadeFactor(void) const
     {
      if(!m_enabled)
         return 1.0;
      switch(m_pulse_phase)
        {
         case 1: return 0.92;
         case 2: return 0.85;
         case 3: return 0.92;
         default: return 1.0;
        }
     }

   string NotifyAnimTag(void) const
     {
      if(!m_enabled)
         return "";
      return (m_pulse_phase % 2 == 0) ? " ◆" : " ◇";
     }
  };

#endif // GM_CANIMATION_ENGINE_MQH
//+------------------------------------------------------------------+
