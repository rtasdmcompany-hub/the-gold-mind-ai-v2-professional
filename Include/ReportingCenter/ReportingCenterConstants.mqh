//+------------------------------------------------------------------+
//|                                 ReportingCenterConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 7 Sprint 5 — Reporting / Investor / Executive BI      |
//|     READ-ONLY — NEVER interferes with live trading              |
//+------------------------------------------------------------------+
#ifndef GM_REPORTING_CENTER_CONSTANTS_MQH
#define GM_REPORTING_CENTER_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_ERC_VERSION              "1.0.0-enterprise-reporting-center"
#define GM_ERC_DB_PREFIX            "GM_ERC_"
#define GM_ERC_THROTTLE_MS          30000
#define GM_ERC_POLICY               "REPORTING & BI READ-ONLY — NO TRADING AUTHORITY"
#define GM_ERC_SAFE                 "GOLD MIND TRADES ONLY — MANUAL TRADES EXCLUDED"

enum ENUM_GM_ERC_QUEUE
  {
   GM_ERC_Q_IDLE = 0,
   GM_ERC_Q_PENDING,
   GM_ERC_Q_RUNNING,
   GM_ERC_Q_CACHED,
   GM_ERC_Q_EXPORTED
  };

enum ENUM_GM_ERC_REPORT
  {
   GM_ERC_RPT_DAILY = 0,
   GM_ERC_RPT_WEEKLY,
   GM_ERC_RPT_MONTHLY,
   GM_ERC_RPT_QUARTERLY,
   GM_ERC_RPT_YEARLY,
   GM_ERC_RPT_SESSION,
   GM_ERC_RPT_GROWTH,
   GM_ERC_RPT_RISK,
   GM_ERC_RPT_RECOVERY,
   GM_ERC_RPT_EXECUTIVE
  };

string GmErcQueueName(const ENUM_GM_ERC_QUEUE q)
  {
   switch(q)
     {
      case GM_ERC_Q_PENDING:  return "Pending";
      case GM_ERC_Q_RUNNING:  return "Running";
      case GM_ERC_Q_CACHED:   return "Cached";
      case GM_ERC_Q_EXPORTED: return "Exported";
     }
   return "Idle";
  }

string GmErcReportName(const ENUM_GM_ERC_REPORT r)
  {
   switch(r)
     {
      case GM_ERC_RPT_DAILY:      return "Daily";
      case GM_ERC_RPT_WEEKLY:     return "Weekly";
      case GM_ERC_RPT_MONTHLY:    return "Monthly";
      case GM_ERC_RPT_QUARTERLY:  return "Quarterly";
      case GM_ERC_RPT_YEARLY:     return "Yearly";
      case GM_ERC_RPT_SESSION:    return "Session";
      case GM_ERC_RPT_GROWTH:     return "Account Growth";
      case GM_ERC_RPT_RISK:       return "Risk";
      case GM_ERC_RPT_RECOVERY:   return "Recovery";
      case GM_ERC_RPT_EXECUTIVE:  return "Executive Summary";
     }
   return "Report";
  }

#endif // GM_REPORTING_CENTER_CONSTANTS_MQH
//+------------------------------------------------------------------+
