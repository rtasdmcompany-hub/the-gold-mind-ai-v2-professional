//+------------------------------------------------------------------+
//|                                    CAccountProfileManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Account profiles — NO trading credentials stored            |
//+------------------------------------------------------------------+
#ifndef GM_CACCOUNT_PROFILE_MANAGER_MQH
#define GM_CACCOUNT_PROFILE_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmEnterpriseResult.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Protection/SGmAccountSnapshot.mqh"

class CGmAccountProfileManager
  {
public:
   void BuildLocal(CGmPhase2Bridge *bridge,
                   const bool terminal_connected,
                   SGmEnterpriseAccountProfile &out)
     {
      out.Reset();
      out.account_id = IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN));
      out.broker = AccountInfoString(ACCOUNT_COMPANY);
      out.server = AccountInfoString(ACCOUNT_SERVER);
      const long trade_mode = AccountInfoInteger(ACCOUNT_TRADE_MODE);
      if(trade_mode == ACCOUNT_TRADE_MODE_DEMO)
         out.account_type = "Demo";
      else if(trade_mode == ACCOUNT_TRADE_MODE_CONTEST)
         out.account_type = "Contest";
      else
         out.account_type = "Real";
      out.currency = AccountInfoString(ACCOUNT_CURRENCY);
      out.risk_profile = "Observed (read-only)";
      out.connection_status = terminal_connected ? "Connected" : "Disconnected";
      if(bridge != NULL && StringLen(bridge.Symbol()) > 0)
         out.connection_status += " | Symbol=" + bridge.Symbol();
      out.valid = (StringLen(out.account_id) > 0);
     }
  };

#endif // GM_CACCOUNT_PROFILE_MANAGER_MQH
//+------------------------------------------------------------------+
