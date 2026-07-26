//+------------------------------------------------------------------+
//|                                  CSystemHealthSupervisor.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     Continuous health observation — NO control actions          |
//+------------------------------------------------------------------+
#ifndef GM_CSYSTEM_HEALTH_SUPERVISOR_MQH
#define GM_CSYSTEM_HEALTH_SUPERVISOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmAssistantResult.mqh"
#include "../Learning/CAILearningEngine.mqh"
#include "../AIValidation/CAIValidationEngine.mqh"
#include "../../Analytics/CAnalyticsEngine.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"

/// @brief Observes EA / terminal / AI stack health (advisory metrics only).
class CGmSystemHealthSupervisor
  {
public:
   void Analyze(CGmPhase2Bridge *bridge,
                CGmAnalyticsEngine *analytics,
                CGmAILearningEngine *learn,
                CGmAIValidationEngine *aival,
                const bool dashboard_ok,
                SGmAssistantResult &r)
     {
      r.terminal_connected = (TerminalInfoInteger(TERMINAL_CONNECTED) != 0);
      r.terminal_ping_ms = (int)TerminalInfoInteger(TERMINAL_PING_LAST);
      r.memory_used_mb = (ulong)TerminalInfoInteger(TERMINAL_MEMORY_USED);
      r.memory_available_mb = (ulong)TerminalInfoInteger(TERMINAL_MEMORY_AVAILABLE);

      // EA health: bridge + protection readable
      r.ea_health = 40.0;
      if(bridge != NULL && StringLen(bridge.Symbol()) > 0)
        {
         r.ea_health = 75.0;
         if(bridge.ProtectionReady())
            r.ea_health = 90.0;
         if(!r.terminal_connected)
            r.ea_health -= 25.0;
         if(r.terminal_ping_ms >= GM_ASSIST_PING_WARN_MS)
            r.ea_health -= 10.0;
        }
      r.ea_health = GmAssistClamp(r.ea_health);

      // Database / Analytics as proxy for persistence health
      r.database_health = (analytics != NULL) ? 88.0 : 45.0;
      r.api_health = (bridge != NULL) ? 85.0 : 40.0;
      r.dashboard_health = dashboard_ok ? 90.0 : 50.0;

      r.learning_health = 50.0;
      if(learn != NULL && learn.IsReady() && learn.Last().valid)
         r.learning_health = GmAssistClamp(50.0 + learn.Last().learning_progress_pct * 0.5);

      r.validation_health = 50.0;
      if(aival != NULL && aival.IsReady() && aival.Last().valid)
         r.validation_health = GmAssistClamp(aival.Last().ai_health_score);

      // Memory soft scoring
      double mem_score = 85.0;
      if(r.memory_available_mb > 0 && r.memory_used_mb > 0)
        {
         const double ratio = 100.0 * (double)r.memory_used_mb /
                              (double)(r.memory_used_mb + r.memory_available_mb);
         mem_score = GmAssistClamp(100.0 - MathMax(0.0, ratio - 60.0) * 1.5);
        }

      r.system_health_score = GmAssistClamp(
                                 0.22 * r.ea_health +
                                 0.14 * r.database_health +
                                 0.12 * r.api_health +
                                 0.14 * r.dashboard_health +
                                 0.12 * r.learning_health +
                                 0.14 * r.validation_health +
                                 0.12 * mem_score);
     }
  };

#endif // GM_CSYSTEM_HEALTH_SUPERVISOR_MQH
//+------------------------------------------------------------------+
