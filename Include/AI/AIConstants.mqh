//+------------------------------------------------------------------+
//|                                              AIConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_AI_CONSTANTS_MQH
#define GM_AI_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file AIConstants.mqh
/// @brief Phase 2 Sprint 6 — AI Dashboard foundation limits (READ-ONLY).

#define GM_AI_VERSION_STRING        "0.1.0-foundation"
#define GM_AI_ENGINE_NAME           "GoldMind AI Core"
#define GM_AI_EVENT_MAX             200
#define GM_AI_LOG_MAX               300
#define GM_AI_DECISION_MAX          100
#define GM_AI_PRED_HIST_MAX         100
#define GM_AI_REC_HIST_MAX          100
#define GM_AI_SYNC_SEC              5
#define GM_AI_COMING_SOON           "COMING SOON"
#define GM_AI_NOT_INITIALIZED       "NOT INITIALIZED"
#define GM_AI_DB_FILE_PREFIX        "GM_AI_DB_"

enum ENUM_GM_AI_MODE
  {
   GM_AI_MODE_OFFLINE = 0,
   GM_AI_MODE_OBSERVE,
   GM_AI_MODE_LEARN,       ///< Future Phase 3
   GM_AI_MODE_ADVISE,      ///< Future Phase 3
   GM_AI_MODE_AUTONOMOUS   ///< Future — never used in Phase 2
  };

enum ENUM_GM_AI_STATUS
  {
   GM_AI_STATUS_NOT_INITIALIZED = 0,
   GM_AI_STATUS_IDLE,
   GM_AI_STATUS_READY,
   GM_AI_STATUS_LEARNING,
   GM_AI_STATUS_ERROR
  };

enum ENUM_GM_AI_EVENT_TYPE
  {
   GM_AI_EVT_STARTED = 0,
   GM_AI_EVT_STOPPED,
   GM_AI_EVT_LEARNING,
   GM_AI_EVT_PREDICTION,
   GM_AI_EVT_RECOMMENDATION,
   GM_AI_EVT_WARNING,
   GM_AI_EVT_ERROR,
   GM_AI_EVT_CONFIDENCE_UPDATED,
   GM_AI_EVT_DATA_UPDATED,
   GM_AI_EVT_INFO
  };

enum ENUM_GM_AI_API_TARGET
  {
   GM_AI_API_PYTHON = 0,
   GM_AI_API_ML,
   GM_AI_API_DEEP_LEARNING,
   GM_AI_API_NEURAL,
   GM_AI_API_CLOUD,
   GM_AI_API_GPT,
   GM_AI_API_VISION,
   GM_AI_API_NEWS
  };

#endif // GM_AI_CONSTANTS_MQH
//+------------------------------------------------------------------+
