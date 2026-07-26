//+------------------------------------------------------------------+
//|                                               EnumsLevels.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_ENUMS_LEVELS_MQH
#define GM_ENUMS_LEVELS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file EnumsLevels.mqh
/// @brief Level / cycle enumerations for the Trading Level Engine.

enum ENUM_GM_LEVEL_SIDE
  {
   GM_LEVEL_SIDE_BUY  = 0,
   GM_LEVEL_SIDE_SELL = 1
  };

enum ENUM_GM_LEVEL_INDEX
  {
   GM_LEVEL_1 = 0,
   GM_LEVEL_2 = 1,
   GM_LEVEL_3 = 2
  };

enum ENUM_GM_LEVEL_TAG
  {
   GM_TAG_BL1 = 0,
   GM_TAG_BL2,
   GM_TAG_BL3,
   GM_TAG_SL1,
   GM_TAG_SL2,
   GM_TAG_SL3
  };

#endif // GM_ENUMS_LEVELS_MQH
//+------------------------------------------------------------------+
