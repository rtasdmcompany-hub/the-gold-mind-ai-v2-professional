//+------------------------------------------------------------------+
//|                                     CEocLiveOperationsRoom.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEOC_LIVE_OPERATIONS_ROOM_MQH
#define GM_CEOC_LIVE_OPERATIONS_ROOM_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmCommandCenterResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmEocLiveOperationsRoom
  {
private:
   CGmLogger *m_logger;

public:
                     CGmEocLiveOperationsRoom(void) : m_logger(NULL) {}

   void Init(CGmLogger *logger) { m_logger = logger; }

   void Build(const int open_ai_trades,
              const int pending_orders,
              const int licensed_accounts,
              const int connected,
              const double account_health,
              const string sync_status,
              SGmCommandCenterResult &out)
     {
      out.open_ai_trades = open_ai_trades;
      out.pending_orders = pending_orders;
      // Lifecycle proxies (observe-only catalog — never inspect manual trades)
      out.recovery_trades = (open_ai_trades > 1 ? 1 : 0);
      out.breakeven_trades = (open_ai_trades > 0 ? open_ai_trades / 2 : 0);
      out.trailing_trades = (open_ai_trades > 0 ? 1 : 0);
      out.connected_terminals = connected > 0 ? connected : (TerminalInfoInteger(TERMINAL_CONNECTED) ? 1 : 0);
      out.running_ai_instances = licensed_accounts > 0 ? licensed_accounts : 1;

      out.ops_room_summary = StringFormat(
         "=== LIVE OPERATIONS ROOM ===\r\n"
         "Terminals=%d | AI Instances=%d | OpenAI=%d Pending=%d\r\n"
         "Recovery~=%d BE~=%d Trail~=%d | AcctHealth=%.0f | Sync=%s\r\n"
         "Overall=%s | REAL-TIME BG SYNC | NO REMOTE COMMANDS\r\n",
         out.connected_terminals, out.running_ai_instances,
         out.open_ai_trades, out.pending_orders,
         out.recovery_trades, out.breakeven_trades, out.trailing_trades,
         account_health, sync_status, out.enterprise_status);

      if(m_logger != NULL)
         m_logger.Info("Operations Updated | Ops Room refreshed", "EOC");
     }
  };

#endif // GM_CEOC_LIVE_OPERATIONS_ROOM_MQH
//+------------------------------------------------------------------+
