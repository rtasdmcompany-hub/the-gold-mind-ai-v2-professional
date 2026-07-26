//+------------------------------------------------------------------+
//|                                         CAIContextManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CAI_CONTEXT_MANAGER_MQH
#define GM_CAI_CONTEXT_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmAIBusSnapshot.mqh"
#include "SGmAICoreSettings.mqh"
#include "../../Logging/CLogger.mqh"

class CGmAIContextManager
  {
private:
   CGmLogger          *m_logger;
   SGmAIBusSnapshot    m_ctx;
   SGmAICoreSettings   m_settings;
   double              m_confidence;
   string              m_last_insight;
   bool                m_ready;

public:
                     CGmAIContextManager(void)
                       : m_logger(NULL), m_confidence(0.0),
                         m_last_insight(""), m_ready(false)
     {
      m_ctx.Reset();
      m_settings.Defaults();
     }

   void Init(CGmLogger *logger, const SGmAICoreSettings &settings)
     {
      m_logger = logger;
      m_settings = settings;
      m_settings.Clamp();
      m_ctx.Reset();
      m_confidence = 0.0;
      m_last_insight = "Context empty";
      m_ready = true;
     }

   bool IsReady(void) const { return m_ready; }
   SGmAIBusSnapshot Context(void) const { return m_ctx; }
   double Confidence(void) const { return m_confidence; }
   string LastInsight(void) const { return m_last_insight; }

   void Update(const SGmAIBusSnapshot &bus)
     {
      m_ctx = bus;
      // Sprint 1: lightweight heuristic confidence (advisory only)
      double c = 50.0;
      if(bus.broker_connected)
         c += 5.0;
      if(bus.analytics_valid)
         c += 10.0;
      if(bus.spread_points > 0.0 && bus.spread_points < 300.0)
         c += 5.0;
      if(bus.current_dd_pct > 8.0)
         c -= 15.0;
      if(c < 0.0) c = 0.0;
      if(c > 100.0) c = 100.0;
      m_confidence = c;
      m_last_insight = StringFormat("ctx | %s | open=%d pend=%d dd=%.1f wr=%.1f",
                                    bus.symbol, bus.open_positions, bus.pending_orders,
                                    bus.current_dd_pct, bus.overall_win_rate);
     }
  };

#endif // GM_CAI_CONTEXT_MANAGER_MQH
//+------------------------------------------------------------------+
