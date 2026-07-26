//+------------------------------------------------------------------+
//|                                          Phase3AIConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     Phase 3 Sprint 1 — AI Core Foundation (ANALYSIS ONLY)       |
//+------------------------------------------------------------------+
#ifndef GM_PHASE3_AI_CONSTANTS_MQH
#define GM_PHASE3_AI_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_AI_CORE_VERSION              "1.0.0-core"
#define GM_AI_CORE_LABEL                "Phase3-AI-Core"
#define GM_AI_CORE_DB_PREFIX            "GM_AI_CORE_"
#define GM_AI_CORE_MEM_MAX              128
#define GM_AI_CORE_QUEUE_MAX            64
#define GM_AI_CORE_EVENT_MAX            200
#define GM_AI_CORE_PROCESS_THROTTLE_MS  500
#define GM_AI_CORE_BUS_THROTTLE_MS      250

/// @brief AI runtime states (Phase 3 Sprint 1).
enum ENUM_GM_AI_CORE_STATE
  {
   GM_AI_CORE_STATE_INITIALIZING = 0,
   GM_AI_CORE_STATE_LEARNING,
   GM_AI_CORE_STATE_ANALYZING,
   GM_AI_CORE_STATE_WAITING,
   GM_AI_CORE_STATE_MONITORING,
   GM_AI_CORE_STATE_DECISION_READY,
   GM_AI_CORE_STATE_PAUSED,
   GM_AI_CORE_STATE_DISABLED,
   GM_AI_CORE_STATE_ERROR
  };

/// @brief AI operating modes — Live Decision is reserved (never executes trades).
enum ENUM_GM_AI_CORE_MODE
  {
   GM_AI_CORE_MODE_DISABLED = 0,
   GM_AI_CORE_MODE_SAFE,            ///< Minimal observation
   GM_AI_CORE_MODE_LEARNING,        ///< Collect / store only
   GM_AI_CORE_MODE_ANALYSIS_ONLY,   ///< Default Phase 3
   GM_AI_CORE_MODE_SIMULATION,      ///< Simulated advisory
   GM_AI_CORE_MODE_FUTURE_LIVE      ///< Reserved — still cannot execute in Phase 3
  };

string GmAICoreStateName(const ENUM_GM_AI_CORE_STATE s)
  {
   switch(s)
     {
      case GM_AI_CORE_STATE_INITIALIZING:   return "Initializing";
      case GM_AI_CORE_STATE_LEARNING:       return "Learning";
      case GM_AI_CORE_STATE_ANALYZING:      return "Analyzing";
      case GM_AI_CORE_STATE_WAITING:        return "Waiting";
      case GM_AI_CORE_STATE_MONITORING:     return "Monitoring";
      case GM_AI_CORE_STATE_DECISION_READY: return "Decision Ready";
      case GM_AI_CORE_STATE_PAUSED:         return "Paused";
      case GM_AI_CORE_STATE_DISABLED:       return "Disabled";
      case GM_AI_CORE_STATE_ERROR:          return "Error";
     }
   return "Unknown";
  }

string GmAICoreModeName(const ENUM_GM_AI_CORE_MODE m)
  {
   switch(m)
     {
      case GM_AI_CORE_MODE_DISABLED:      return "Disabled";
      case GM_AI_CORE_MODE_SAFE:          return "Safe Mode";
      case GM_AI_CORE_MODE_LEARNING:      return "Learning Mode";
      case GM_AI_CORE_MODE_ANALYSIS_ONLY: return "Analysis Only";
      case GM_AI_CORE_MODE_SIMULATION:    return "Simulation";
      case GM_AI_CORE_MODE_FUTURE_LIVE:   return "Future Live (blocked)";
     }
   return "Unknown";
  }

#endif // GM_PHASE3_AI_CONSTANTS_MQH
//+------------------------------------------------------------------+
