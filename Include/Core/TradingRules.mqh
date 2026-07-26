//+------------------------------------------------------------------+
//|                                             TradingRules.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_TRADING_RULES_MQH
#define GM_TRADING_RULES_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file TradingRules.mqh
/// @brief Immutable proprietary trading & isolation rules.
/// @details These rules are NON-NEGOTIABLE. Every engine (Strategy, Trade
///          Management, Risk, Recovery, AI, Analytics) MUST honour them.
///          Strategy math is implemented in later sprints; the rules live here.

//+------------------------------------------------------------------+
//| RULE #1 – Own trades only                                        |
//| The Gold Mind AI will ONLY manage trades created by itself.      |
//+------------------------------------------------------------------+
#define GM_RULE_OWN_TRADES_ONLY              1

//+------------------------------------------------------------------+
//| RULE #2 – Never touch manual trades                              |
//| NEVER modify / close / trail / hedge / partial-close / move SL   |
//| or TP / interfere with ANY manually opened trade.                |
//+------------------------------------------------------------------+
#define GM_RULE_IGNORE_MANUAL_TRADES         1

//+------------------------------------------------------------------+
//| RULE #3 – Never manage other EAs                                 |
//| NEVER manage trades opened by another Expert Advisor.            |
//+------------------------------------------------------------------+
#define GM_RULE_IGNORE_FOREIGN_EA_TRADES     1

//+------------------------------------------------------------------+
//| RULE #4 – Magic Number ownership                                 |
//| Every Gold Mind AI trade uses the configured Magic Number.       |
//| ONLY positions/orders with that Magic Number may be managed.     |
//| All other trades must be completely ignored.                     |
//+------------------------------------------------------------------+
#define GM_RULE_MAGIC_OWNERSHIP_ENFORCED     1

//+------------------------------------------------------------------+
//| STARTUP POLICY                                                   |
//| Become active immediately after attach — do NOT wait for next    |
//| H4 candle. Use the most recently CLOSED H4 candle High/Low,      |
//| calculate official Gold Mind levels, place pending orders for    |
//| the current H4 cycle, then continue on each new H4 close.        |
//+------------------------------------------------------------------+
#define GM_POLICY_STRATEGY_TIMEFRAME         PERIOD_H4
#define GM_POLICY_ACTIVATE_IMMEDIATELY       1
#define GM_POLICY_USE_LAST_CLOSED_H4         1
#define GM_POLICY_NO_WAIT_NEXT_H4            1

//+------------------------------------------------------------------+
//| RECOVERY POLICY                                                  |
//| On EA / MT5 / PC / internet restart: detect own Magic trades,    |
//| restore internal state, NEVER duplicate pendings or positions,   |
//| continue managing only own trades.                               |
//+------------------------------------------------------------------+
#define GM_POLICY_SAFE_RECOVERY              1
#define GM_POLICY_NO_DUPLICATE_PENDINGS      1
#define GM_POLICY_NO_DUPLICATE_POSITIONS     1

/// Manual trades typically carry magic = 0 (platform convention).
#define GM_MAGIC_MANUAL_TRADE                0

#endif // GM_TRADING_RULES_MQH
//+------------------------------------------------------------------+
