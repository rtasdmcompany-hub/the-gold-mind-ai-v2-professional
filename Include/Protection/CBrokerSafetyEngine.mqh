//+------------------------------------------------------------------+
//|                                       CBrokerSafetyEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CBROKER_SAFETY_ENGINE_MQH
#define GM_CBROKER_SAFETY_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmBrokerSnapshot.mqh"
#include "CEventLogger.mqh"

/// @file CBrokerSafetyEngine.mqh
/// @brief Broker constraint snapshot + reject invalid operations safely.

class CGmBrokerSafetyEngine
  {
private:
   CGmEventLogger   *m_events;
   string            m_symbol;
   int               m_max_spread_points;
   SGmBrokerSnapshot m_snap;
   string            m_last_reason;
   bool              m_ready;

   bool Fail(const string reason)
     {
      m_last_reason = reason;
      if(m_events != NULL)
         m_events.Validation("BrokerSafety", reason, GM_LOG_WARNING);
      return false;
     }

public:
                     CGmBrokerSafetyEngine(void)
                       : m_events(NULL),
                         m_symbol(""),
                         m_max_spread_points(500),
                         m_last_reason(""),
                         m_ready(false)
     {
      m_snap.Reset();
     }

                    ~CGmBrokerSafetyEngine(void) { m_events = NULL; }

   void Init(CGmEventLogger *events, const string symbol, const int max_spread_points)
     {
      m_events = events;
      m_symbol = symbol;
      m_max_spread_points = (max_spread_points > 0) ? max_spread_points : 500;
      m_ready = true;
      Refresh();
      if(m_events != NULL)
         m_events.Broker("BrokerSafety",
                         StringFormat("Ready | %s maxSpread=%d", m_symbol, m_max_spread_points));
     }

   void SetMaxSpread(const int pts)
     {
      m_max_spread_points = (pts > 0) ? pts : m_max_spread_points;
     }

   string LastReason(void) const { return m_last_reason; }
   SGmBrokerSnapshot Snapshot(void) const { return m_snap; }

   void Refresh(void)
     {
      if(!m_ready || StringLen(m_symbol) == 0)
         return;
      m_snap.Reset();
      m_snap.symbol = m_symbol;
      m_snap.stamped_at = TimeCurrent();
      m_snap.stops_level = SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL);
      m_snap.freeze_level = SymbolInfoInteger(m_symbol, SYMBOL_TRADE_FREEZE_LEVEL);
      m_snap.spread = SymbolInfoInteger(m_symbol, SYMBOL_SPREAD);
      m_snap.tick_size = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
      m_snap.tick_value = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
      m_snap.point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      m_snap.digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
      m_snap.lot_step = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
      m_snap.lot_min = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
      m_snap.lot_max = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
      m_snap.valid = (m_snap.point > 0.0 && m_snap.digits >= 0);
     }

   bool ValidateSpecs(void)
     {
      m_last_reason = "";
      Refresh();
      if(!m_snap.valid)
         return Fail("Invalid broker symbol specs");
      if(m_snap.point <= 0.0)
         return Fail("Invalid point value");
      if(m_snap.tick_size < 0.0)
         return Fail("Invalid tick size");
      if(m_snap.lot_min <= 0.0)
         return Fail("Invalid minimum lot");
      if(m_snap.lot_max < m_snap.lot_min)
         return Fail("Invalid maximum lot");
      if(m_snap.lot_step <= 0.0)
         return Fail("Invalid lot step");
      if(m_snap.spread < 0)
         return Fail("Invalid spread");
      if(m_snap.spread > m_max_spread_points)
         return Fail(StringFormat("Spread too wide | %d > %d",
                                  (int)m_snap.spread, m_max_spread_points));
      return true;
     }

   bool ValidateLot(const double lots)
     {
      Refresh();
      if(lots <= 0.0)
         return Fail("Lot <= 0");
      if(lots + 1e-8 < m_snap.lot_min)
         return Fail(StringFormat("Lot %.2f < min %.2f", lots, m_snap.lot_min));
      if(lots - 1e-8 > m_snap.lot_max)
         return Fail(StringFormat("Lot %.2f > max %.2f", lots, m_snap.lot_max));
      if(m_snap.lot_step > 0.0)
        {
         const double steps = lots / m_snap.lot_step;
         if(MathAbs(steps - MathRound(steps)) > 1e-6)
            return Fail(StringFormat("Lot %.2f not aligned to step %.2f", lots, m_snap.lot_step));
        }
      return true;
     }

   bool ValidateStopDistance(const double entry, const double sl, const double tp)
     {
      Refresh();
      if(m_snap.point <= 0.0)
         return Fail("Invalid point");
      const double min_dist = (double)m_snap.stops_level * m_snap.point;
      if(sl > 0.0 && MathAbs(entry - sl) < min_dist)
         return Fail("SL inside minimum stop distance");
      if(tp > 0.0 && MathAbs(entry - tp) < min_dist)
         return Fail("TP inside minimum stop distance");

      // Freeze level — price too close to market for pending modify/place
      const double freeze = (double)m_snap.freeze_level * m_snap.point;
      if(freeze > 0.0)
        {
         const double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
         const double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
         if(MathAbs(ask - entry) < freeze || MathAbs(bid - entry) < freeze)
            return Fail("Entry inside freeze level");
        }
      return true;
     }
  };

#endif // GM_CBROKER_SAFETY_ENGINE_MQH
//+------------------------------------------------------------------+
