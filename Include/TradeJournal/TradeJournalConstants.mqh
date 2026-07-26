//+------------------------------------------------------------------+
//|                                   TradeJournalConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 7 Sprint 1 — Trade Journal / Replay / Analytics       |
//|     ANALYSIS ONLY — NEVER modifies trading                      |
//+------------------------------------------------------------------+
#ifndef GM_TRADE_JOURNAL_PLATFORM_CONSTANTS_MQH
#define GM_TRADE_JOURNAL_PLATFORM_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_ETJ_VERSION              "1.0.0-enterprise-trade-journal"
#define GM_ETJ_DB_PREFIX            "GM_ETJ_"
#define GM_ETJ_THROTTLE_MS          15000
#define GM_ETJ_MAX_TRADES           128
#define GM_ETJ_MAX_EVENTS           512
#define GM_ETJ_HIST_DAYS            90
#define GM_ETJ_POLICY               "TRADE JOURNAL ANALYSIS ONLY — NO TRADING AUTHORITY"
#define GM_ETJ_SAFE                 "GOLD MIND MAGIC ONLY — MANUAL TRADES ISOLATED"
#define GM_ETJ_SCREENSHOT_ARCH      "FUTURE — screenshot capture architecture reserved"

enum ENUM_GM_ETJ_SIDE
  {
   GM_ETJ_SIDE_BUY = 0,
   GM_ETJ_SIDE_SELL
  };

enum ENUM_GM_ETJ_STATUS
  {
   GM_ETJ_ST_OPEN = 0,
   GM_ETJ_ST_CLOSED,
   GM_ETJ_ST_CANCELLED
  };

enum ENUM_GM_ETJ_EVENT
  {
   GM_ETJ_EV_PENDING_CREATED = 0,
   GM_ETJ_EV_PENDING_TRIGGERED,
   GM_ETJ_EV_TRADE_ACTIVATED,
   GM_ETJ_EV_BREAK_EVEN,
   GM_ETJ_EV_PARTIAL_80,
   GM_ETJ_EV_TRAILING_STARTED,
   GM_ETJ_EV_RECOVERY_STARTED,
   GM_ETJ_EV_RECOVERY_FINISHED,
   GM_ETJ_EV_TRADE_CLOSED,
   GM_ETJ_EV_NOTE
  };

enum ENUM_GM_ETJ_REPLAY
  {
   GM_ETJ_RP_IDLE = 0,
   GM_ETJ_RP_READY,
   GM_ETJ_RP_PLAYING,
   GM_ETJ_RP_PAUSED,
   GM_ETJ_RP_COMPLETE
  };

enum ENUM_GM_ETJ_EXPORT
  {
   GM_ETJ_EX_CSV = 0,
   GM_ETJ_EX_EXCEL_ARCH,
   GM_ETJ_EX_PDF_ARCH,
   GM_ETJ_EX_INVESTOR_ARCH
  };

string GmEtjSideName(const ENUM_GM_ETJ_SIDE s)
  {
   return (s == GM_ETJ_SIDE_SELL) ? "SELL" : "BUY";
  }

string GmEtjStatusName(const ENUM_GM_ETJ_STATUS s)
  {
   if(s == GM_ETJ_ST_CLOSED) return "Closed";
   if(s == GM_ETJ_ST_CANCELLED) return "Cancelled";
   return "Open";
  }

string GmEtjEventName(const ENUM_GM_ETJ_EVENT e)
  {
   switch(e)
     {
      case GM_ETJ_EV_PENDING_CREATED:   return "Pending Order Created";
      case GM_ETJ_EV_PENDING_TRIGGERED: return "Pending Triggered";
      case GM_ETJ_EV_TRADE_ACTIVATED:   return "Trade Activated";
      case GM_ETJ_EV_BREAK_EVEN:        return "Break Even Activated";
      case GM_ETJ_EV_PARTIAL_80:        return "80% Partial Close";
      case GM_ETJ_EV_TRAILING_STARTED:  return "Trailing Started";
      case GM_ETJ_EV_RECOVERY_STARTED:  return "Recovery Started";
      case GM_ETJ_EV_RECOVERY_FINISHED: return "Recovery Finished";
      case GM_ETJ_EV_TRADE_CLOSED:      return "Trade Closed";
     }
   return "Note";
  }

string GmEtjReplayName(const ENUM_GM_ETJ_REPLAY r)
  {
   switch(r)
     {
      case GM_ETJ_RP_READY:    return "Ready";
      case GM_ETJ_RP_PLAYING:  return "Playing";
      case GM_ETJ_RP_PAUSED:   return "Paused";
      case GM_ETJ_RP_COMPLETE: return "Complete";
     }
   return "Idle";
  }

string GmEtjSessionName(const datetime t)
  {
   MqlDateTime dt;
   TimeToStruct(t, dt);
   const int h = dt.hour;
   if(h >= 0 && h < 8)  return "Asia";
   if(h >= 8 && h < 13) return "London";
   if(h >= 13 && h < 21) return "NewYork";
   return "Overlap";
  }

#endif // GM_TRADE_JOURNAL_PLATFORM_CONSTANTS_MQH
//+------------------------------------------------------------------+
