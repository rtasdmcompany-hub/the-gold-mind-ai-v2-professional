//+------------------------------------------------------------------+
//|                                    StrategyLabConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 7 Sprint 2 — Backtest / Monte Carlo / Walk-Forward    |
//|     RESEARCH ONLY — NEVER interferes with live trading          |
//+------------------------------------------------------------------+
#ifndef GM_STRATEGY_LAB_CONSTANTS_MQH
#define GM_STRATEGY_LAB_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_ESL_VERSION              "1.0.0-enterprise-strategy-lab"
#define GM_ESL_DB_PREFIX            "GM_ESL_"
#define GM_ESL_THROTTLE_MS          30000
#define GM_ESL_BARS_MAX             500
#define GM_ESL_MC_RUNS_FULL         100
#define GM_ESL_MC_RUNS_LIGHT        20
#define GM_ESL_WFA_FOLDS            5
#define GM_ESL_PARAM_PROFILES       6
#define GM_ESL_POLICY               "STRATEGY VALIDATION RESEARCH ONLY — NO TRADING AUTHORITY"
#define GM_ESL_SAFE                 "PAUSE HEAVY SIMS WHILE GM TRADES ACTIVE — LIVE TRADING FIRST"

// Reference knowledge of frozen Gold Mind rules (READ-ONLY — never written to live config)
#define GM_ESL_REF_SL_PIPS          30.0
#define GM_ESL_REF_ATR_PERIOD       14
#define GM_ESL_REF_BE_PIPS          50.0
#define GM_ESL_REF_PARTIAL_PCT      80.0
#define GM_ESL_REF_TRAIL_PIPS       30.0
#define GM_ESL_REF_LEVELS           6

enum ENUM_GM_ESL_MODE
  {
   GM_ESL_MODE_IDLE = 0,
   GM_ESL_MODE_BACKTEST,
   GM_ESL_MODE_MONTE_CARLO,
   GM_ESL_MODE_WALK_FORWARD,
   GM_ESL_MODE_COMPARE,
   GM_ESL_MODE_ROBUSTNESS,
   GM_ESL_MODE_PAUSED
  };

enum ENUM_GM_ESL_SCENARIO
  {
   GM_ESL_SC_HISTORICAL = 0,
   GM_ESL_SC_HIGH_VOL,
   GM_ESL_SC_LOW_VOL,
   GM_ESL_SC_NEWS,
   GM_ESL_SC_SESSION,
   GM_ESL_SC_RECOVERY,
   GM_ESL_SC_HEDGE
  };

enum ENUM_GM_ESL_QUEUE
  {
   GM_ESL_Q_IDLE = 0,
   GM_ESL_Q_PENDING,
   GM_ESL_Q_RUNNING,
   GM_ESL_Q_CACHED,
   GM_ESL_Q_PAUSED
  };

string GmEslModeName(const ENUM_GM_ESL_MODE m)
  {
   switch(m)
     {
      case GM_ESL_MODE_BACKTEST:      return "Backtest";
      case GM_ESL_MODE_MONTE_CARLO:   return "MonteCarlo";
      case GM_ESL_MODE_WALK_FORWARD:  return "WalkForward";
      case GM_ESL_MODE_COMPARE:       return "Compare";
      case GM_ESL_MODE_ROBUSTNESS:    return "Robustness";
      case GM_ESL_MODE_PAUSED:        return "Paused";
     }
   return "Idle";
  }

string GmEslScenarioName(const ENUM_GM_ESL_SCENARIO s)
  {
   switch(s)
     {
      case GM_ESL_SC_HIGH_VOL:  return "High Volatility";
      case GM_ESL_SC_LOW_VOL:   return "Low Volatility";
      case GM_ESL_SC_NEWS:      return "News Session";
      case GM_ESL_SC_SESSION:   return "Session";
      case GM_ESL_SC_RECOVERY:  return "Recovery";
      case GM_ESL_SC_HEDGE:     return "Hedge Logic";
     }
   return "Historical";
  }

string GmEslQueueName(const ENUM_GM_ESL_QUEUE q)
  {
   switch(q)
     {
      case GM_ESL_Q_PENDING: return "Pending";
      case GM_ESL_Q_RUNNING: return "Running";
      case GM_ESL_Q_CACHED:  return "Cached";
      case GM_ESL_Q_PAUSED:  return "Paused";
     }
   return "Idle";
  }

#endif // GM_STRATEGY_LAB_CONSTANTS_MQH
//+------------------------------------------------------------------+
