//+------------------------------------------------------------------+
//|                                                    Defines.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_DEFINES_MQH
#define GM_DEFINES_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file Defines.mqh
/// @brief Global project macros and structural constants (non-strategy).
/// @note Trading parameters must live in CGmConfiguration — never hardcode strategy values here.

#define GM_MAGIC_DEFAULT              112233
#define GM_LOT_DEFAULT                0.01
#define GM_LOG_MAX_LINE_LENGTH        512
#define GM_LOG_FILE_PREFIX            "GoldMindAI_"
#define GM_CONFIG_SECTION_CORE        "Core"
#define GM_CONFIG_SECTION_LOGGING     "Logging"
#define GM_CONFIG_SECTION_SESSION     "Session"
#define GM_CONFIG_SECTION_RISK        "Risk"
#define GM_CONFIG_SECTION_AI          "AI"
#define GM_CONFIG_SECTION_TRADING     "Trading"
#define GM_CONFIG_SECTION_RECOVERY    "Recovery"
#define GM_CONFIG_SECTION_ANALYTICS   "Analytics"
#define GM_TIMER_INTERVAL_DEFAULT_MS  1000
#define GM_INVALID_HANDLE             -1

#define GM_OK                         0
#define GM_FAIL                      -1

#endif // GM_DEFINES_MQH
//+------------------------------------------------------------------+
