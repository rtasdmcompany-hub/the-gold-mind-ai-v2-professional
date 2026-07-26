//+------------------------------------------------------------------+
//|                                                  CLevelGate.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CLEVEL_GATE_MQH
#define GM_CLEVEL_GATE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../Calculation/EnumsLevels.mqh"

/// @file CLevelGate.mqh
/// @brief Abstract gate so Pending Engine never circular-includes LevelManager.

class CGmLevelGate
  {
public:
   virtual          ~CGmLevelGate(void) {}
   virtual bool      ShouldSkipPlacement(const ENUM_GM_LEVEL_TAG tag) const { return false; }
   virtual int       DesiredAttempt(const ENUM_GM_LEVEL_TAG tag) const { return 1; }
   virtual double    LockedEntry(const ENUM_GM_LEVEL_TAG tag, const double fallback) const { return fallback; }
   virtual void      NotifyPendingPlaced(const ENUM_GM_LEVEL_TAG tag,
                                         const ulong trade_id,
                                         const ulong order_ticket,
                                         const int attempt) {}
   virtual void      NotifyActivated(const string level_tag,
                                     const ulong trade_id,
                                     const ulong position_ticket,
                                     const double entry) {}
   virtual void      NotifyClosed(const string level_tag,
                                  const ulong trade_id,
                                  const bool is_tp,
                                  const bool is_sl,
                                  const double pnl) {}
  };

#endif // GM_CLEVEL_GATE_MQH
//+------------------------------------------------------------------+
