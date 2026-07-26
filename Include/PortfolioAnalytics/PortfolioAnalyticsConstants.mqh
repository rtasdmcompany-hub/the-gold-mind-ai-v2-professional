//+------------------------------------------------------------------+
//|                              PortfolioAnalyticsConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 7 Sprint 4 — Portfolio / Risk / Capital Analytics     |
//|     READ-ONLY — NEVER interferes with live trading              |
//+------------------------------------------------------------------+
#ifndef GM_PORTFOLIO_ANALYTICS_CONSTANTS_MQH
#define GM_PORTFOLIO_ANALYTICS_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_EPA_VERSION              "1.0.0-enterprise-portfolio-analytics"
#define GM_EPA_DB_PREFIX            "GM_EPA_"
#define GM_EPA_THROTTLE_MS          25000
#define GM_EPA_EQUITY_MAX           256
#define GM_EPA_HIST_DAYS            365
#define GM_EPA_POLICY               "PORTFOLIO ANALYTICS READ-ONLY — NO TRADING AUTHORITY"
#define GM_EPA_SAFE                 "GOLD MIND MAGIC ONLY — MANUAL TRADES ISOLATED"

enum ENUM_GM_EPA_GRADE
  {
   GM_EPA_GRADE_A = 0,
   GM_EPA_GRADE_B,
   GM_EPA_GRADE_C,
   GM_EPA_GRADE_D,
   GM_EPA_GRADE_F
  };

string GmEpaGradeName(const ENUM_GM_EPA_GRADE g)
  {
   switch(g)
     {
      case GM_EPA_GRADE_A: return "A";
      case GM_EPA_GRADE_B: return "B";
      case GM_EPA_GRADE_C: return "C";
      case GM_EPA_GRADE_D: return "D";
     }
   return "F";
  }

ENUM_GM_EPA_GRADE GmEpaGradeFromScore(const double score)
  {
   if(score >= 85.0) return GM_EPA_GRADE_A;
   if(score >= 70.0) return GM_EPA_GRADE_B;
   if(score >= 55.0) return GM_EPA_GRADE_C;
   if(score >= 40.0) return GM_EPA_GRADE_D;
   return GM_EPA_GRADE_F;
  }

#endif // GM_PORTFOLIO_ANALYTICS_CONSTANTS_MQH
//+------------------------------------------------------------------+
