//+------------------------------------------------------------------+
//|                                AIDecisionCenterConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 7 Sprint 7 — AI Decision / Trade Quality / Execution  |
//|     READ-ONLY — NEVER interferes with live trading              |
//+------------------------------------------------------------------+
#ifndef GM_AI_DECISION_CENTER_CONSTANTS_MQH
#define GM_AI_DECISION_CENTER_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_ADC_VERSION              "1.0.0-enterprise-ai-decision-center"
#define GM_ADC_DB_PREFIX            "GM_ADC_"
#define GM_ADC_THROTTLE_MS          30000
#define GM_ADC_POLICY               "AI DECISION INTELLIGENCE READ-ONLY — ADVISORY ONLY"
#define GM_ADC_SAFE                 "GOLD MIND TRADES ONLY — NEVER AUTO-MODIFY LIVE LOGIC"

enum ENUM_GM_ADC_QUEUE
  {
   GM_ADC_Q_IDLE = 0,
   GM_ADC_Q_PENDING,
   GM_ADC_Q_RUNNING,
   GM_ADC_Q_CACHED,
   GM_ADC_Q_EXPORTED
  };

enum ENUM_GM_ADC_QUALITY_GRADE
  {
   GM_ADC_QG_F = 0,
   GM_ADC_QG_D,
   GM_ADC_QG_C,
   GM_ADC_QG_B,
   GM_ADC_QG_A,
   GM_ADC_QG_A_PLUS
  };

enum ENUM_GM_ADC_MARKET_CLASS
  {
   GM_ADC_MKT_TRENDING = 0,
   GM_ADC_MKT_RANGING,
   GM_ADC_MKT_HIGH_VOL,
   GM_ADC_MKT_LOW_VOL,
   GM_ADC_MKT_NEWS,
   GM_ADC_MKT_ASIAN,
   GM_ADC_MKT_LONDON,
   GM_ADC_MKT_NEWYORK,
   GM_ADC_MKT_WEEKEND_GAP
  };

string GmAdcQueueName(const ENUM_GM_ADC_QUEUE q)
  {
   switch(q)
     {
      case GM_ADC_Q_PENDING:  return "Pending";
      case GM_ADC_Q_RUNNING:  return "Running";
      case GM_ADC_Q_CACHED:   return "Cached";
      case GM_ADC_Q_EXPORTED: return "Exported";
     }
   return "Idle";
  }

string GmAdcGradeName(const ENUM_GM_ADC_QUALITY_GRADE g)
  {
   switch(g)
     {
      case GM_ADC_QG_A_PLUS: return "A+";
      case GM_ADC_QG_A:      return "A";
      case GM_ADC_QG_B:      return "B";
      case GM_ADC_QG_C:      return "C";
      case GM_ADC_QG_D:      return "D";
     }
   return "F";
  }

string GmAdcMarketName(const ENUM_GM_ADC_MARKET_CLASS m)
  {
   switch(m)
     {
      case GM_ADC_MKT_TRENDING:    return "Trending";
      case GM_ADC_MKT_RANGING:     return "Ranging";
      case GM_ADC_MKT_HIGH_VOL:    return "High Volatility";
      case GM_ADC_MKT_LOW_VOL:     return "Low Volatility";
      case GM_ADC_MKT_NEWS:        return "News Session";
      case GM_ADC_MKT_ASIAN:       return "Asian Session";
      case GM_ADC_MKT_LONDON:      return "London Session";
      case GM_ADC_MKT_NEWYORK:     return "New York Session";
      case GM_ADC_MKT_WEEKEND_GAP: return "Weekend Gap Recovery";
     }
   return "Unknown";
  }

ENUM_GM_ADC_QUALITY_GRADE GmAdcGradeFromScore(const double score)
  {
   if(score >= 92.0) return GM_ADC_QG_A_PLUS;
   if(score >= 85.0) return GM_ADC_QG_A;
   if(score >= 75.0) return GM_ADC_QG_B;
   if(score >= 65.0) return GM_ADC_QG_C;
   if(score >= 50.0) return GM_ADC_QG_D;
   return GM_ADC_QG_F;
  }

#endif // GM_AI_DECISION_CENTER_CONSTANTS_MQH
//+------------------------------------------------------------------+
