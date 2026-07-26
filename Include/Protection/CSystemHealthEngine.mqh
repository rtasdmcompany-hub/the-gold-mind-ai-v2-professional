//+------------------------------------------------------------------+
//|                                       CSystemHealthEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CSYSTEM_HEALTH_ENGINE_MQH
#define GM_CSYSTEM_HEALTH_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ProtectionConstants.mqh"
#include "CEventLogger.mqh"
#include "../Core/EnumsCore.mqh"

/// @file CSystemHealthEngine.mqh
/// @brief EA / terminal / connection / symbol / history / memory health.

struct SGmSystemHealth
  {
   datetime stamped_at;
   ENUM_GM_APP_STATE app_state;
   bool     connected;
   bool     trade_allowed;
   bool     terminal_ok;
   bool     symbol_ok;
   bool     history_ok;
   ulong    memory_kb;
   ulong    last_exec_us;
   bool     abnormal;
   string   last_abnormal;

   void Reset(void)
     {
      stamped_at = 0;
      app_state = GM_APP_STATE_UNINITIALIZED;
      connected = false;
      trade_allowed = false;
      terminal_ok = false;
      symbol_ok = false;
      history_ok = false;
      memory_kb = 0;
      last_exec_us = 0;
      abnormal = false;
      last_abnormal = "";
     }
  };

class CGmSystemHealthEngine
  {
private:
   CGmEventLogger *m_events;
   string          m_symbol;
   SGmSystemHealth m_health;
   bool            m_ready;

   void RecordAbnormal(const string reason)
     {
      m_health.abnormal = true;
      m_health.last_abnormal = reason;
      if(m_events != NULL)
         m_events.Health("SystemHealth", reason, GM_LOG_WARNING);
     }

public:
                     CGmSystemHealthEngine(void)
                       : m_events(NULL), m_symbol(""), m_ready(false)
     {
      m_health.Reset();
     }

                    ~CGmSystemHealthEngine(void) { m_events = NULL; }

   void Init(CGmEventLogger *events, const string symbol)
     {
      m_events = events;
      m_symbol = symbol;
      m_health.Reset();
      m_ready = true;
      if(m_events != NULL)
         m_events.Health("SystemHealth", "System Health Engine ready");
     }

   SGmSystemHealth Health(void) const { return m_health; }

   void SetAppState(const ENUM_GM_APP_STATE state) { m_health.app_state = state; }

   void RecordExecution(const ulong exec_us)
     {
      m_health.last_exec_us = exec_us;
      if(exec_us >= GM_PROT_EXEC_SLOW_US)
        {
         RecordAbnormal(StringFormat("Slow execution | %I64u us", exec_us));
         if(m_events != NULL)
            m_events.Perf("SystemHealth",
                          StringFormat("ExecutionTime=%I64u us", exec_us), GM_LOG_WARNING);
        }
      else if(m_events != NULL && m_events.Detailed())
        {
         m_events.Perf("SystemHealth",
                       StringFormat("ExecutionTime=%I64u us", exec_us), GM_LOG_DEBUG);
        }
     }

   void Refresh(const ENUM_GM_APP_STATE app_state)
     {
      if(!m_ready)
         return;

      m_health.stamped_at = TimeCurrent();
      m_health.app_state = app_state;
      m_health.connected = (TerminalInfoInteger(TERMINAL_CONNECTED) != 0);
      m_health.trade_allowed = (TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) != 0) &&
                               (MQLInfoInteger(MQL_TRADE_ALLOWED) != 0);
      m_health.terminal_ok = (TerminalInfoInteger(TERMINAL_DLLS_ALLOWED) >= 0); // always readable
      m_health.symbol_ok = (SymbolInfoInteger(m_symbol, SYMBOL_SELECT) != 0) ||
                           SymbolSelect(m_symbol, true);
      m_health.history_ok = (Bars(m_symbol, PERIOD_H4) > 20);
      m_health.memory_kb = (ulong)TerminalInfoInteger(TERMINAL_MEMORY_USED);

      if(!m_health.connected)
         RecordAbnormal("Connection lost");
      if(!m_health.trade_allowed)
         RecordAbnormal("Trading permission off");
      if(!m_health.symbol_ok)
         RecordAbnormal("Symbol unavailable");
      if(!m_health.history_ok)
         RecordAbnormal("Insufficient H4 history");

      if(m_events != NULL && m_events.Detailed())
         m_events.Health("SystemHealth",
                         StringFormat("conn=%d trade=%d sym=%d hist=%d mem=%I64uKB state=%s",
                                      (int)m_health.connected, (int)m_health.trade_allowed,
                                      (int)m_health.symbol_ok, (int)m_health.history_ok,
                                      m_health.memory_kb, EnumToString(app_state)),
                         GM_LOG_DEBUG);
     }
  };

#endif // GM_CSYSTEM_HEALTH_ENGINE_MQH
//+------------------------------------------------------------------+
