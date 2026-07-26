//+------------------------------------------------------------------+
//|                                                  SGmLevels.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_LEVELS_MQH
#define GM_SGM_LEVELS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "EnumsLevels.mqh"
#include "LevelConstants.mqh"

/// @file SGmLevels.mqh
/// @brief Snapshot of one H4 Gold Mind level set.

struct SGmLevels
  {
   datetime h4_bar_time;   ///< Open time of the CLOSED H4 bar used (shift 1)
   double   high;
   double   low;
   double   diff;
   double   pivot;
   double   buy1;
   double   buy2;
   double   buy3;
   double   sell1;
   double   sell2;
   double   sell3;
   bool     valid;

   void Reset(void)
     {
      h4_bar_time = 0;
      high = low = diff = pivot = 0.0;
      buy1 = buy2 = buy3 = 0.0;
      sell1 = sell2 = sell3 = 0.0;
      valid = false;
     }

   double PriceByTag(const ENUM_GM_LEVEL_TAG tag) const
     {
      switch(tag)
        {
         case GM_TAG_BL1: return buy1;
         case GM_TAG_BL2: return buy2;
         case GM_TAG_BL3: return buy3;
         case GM_TAG_SL1: return sell1;
         case GM_TAG_SL2: return sell2;
         case GM_TAG_SL3: return sell3;
        }
      return 0.0;
     }

   static string TagToComment(const ENUM_GM_LEVEL_TAG tag)
     {
      switch(tag)
        {
         case GM_TAG_BL1: return GM_COMMENT_BL1;
         case GM_TAG_BL2: return GM_COMMENT_BL2;
         case GM_TAG_BL3: return GM_COMMENT_BL3;
         case GM_TAG_SL1: return GM_COMMENT_SL1;
         case GM_TAG_SL2: return GM_COMMENT_SL2;
         case GM_TAG_SL3: return GM_COMMENT_SL3;
        }
      return "";
     }

   static ENUM_GM_LEVEL_SIDE TagToSide(const ENUM_GM_LEVEL_TAG tag)
     {
      if(tag == GM_TAG_BL1 || tag == GM_TAG_BL2 || tag == GM_TAG_BL3)
         return GM_LEVEL_SIDE_BUY;
      return GM_LEVEL_SIDE_SELL;
     }

   static int TagToLevelIndex(const ENUM_GM_LEVEL_TAG tag)
     {
      switch(tag)
        {
         case GM_TAG_BL1:
         case GM_TAG_SL1: return 0;
         case GM_TAG_BL2:
         case GM_TAG_SL2: return 1;
         case GM_TAG_BL3:
         case GM_TAG_SL3: return 2;
        }
      return 0;
     }
  };

#endif // GM_SGM_LEVELS_MQH
//+------------------------------------------------------------------+
