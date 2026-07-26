//+------------------------------------------------------------------+
//|                                   CAICommandSecurityLayer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Blocks trade / order / risk / strategy command intents      |
//+------------------------------------------------------------------+
#ifndef GM_CAI_COMMAND_SECURITY_LAYER_MQH
#define GM_CAI_COMMAND_SECURITY_LAYER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ConversationAIConstants.mqh"

class CGmAICommandSecurityLayer
  {
public:
   ENUM_GM_CHAT_SECURITY Validate(const string query) const
     {
      const string q = GmChatLower(query);

      // Trade execution language
      if(StringFind(q, "open buy") >= 0 || StringFind(q, "open sell") >= 0 ||
         StringFind(q, "place buy") >= 0 || StringFind(q, "place sell") >= 0 ||
         StringFind(q, "buy now") >= 0 || StringFind(q, "sell now") >= 0 ||
         StringFind(q, "execute trade") >= 0 || StringFind(q, "enter trade") >= 0 ||
         StringFind(q, "close all") >= 0 || StringFind(q, "close trade") >= 0 ||
         StringFind(q, "close position") >= 0)
         return GM_CHAT_SEC_BLOCK_TRADE;

      // Order modification
      if(StringFind(q, "modify order") >= 0 || StringFind(q, "move sl") >= 0 ||
         StringFind(q, "change sl") >= 0 || StringFind(q, "change tp") >= 0 ||
         StringFind(q, "modify stop") >= 0 || StringFind(q, "modify take") >= 0 ||
         StringFind(q, "cancel pending") >= 0 || StringFind(q, "delete pending") >= 0)
         return GM_CHAT_SEC_BLOCK_ORDER;

      // Risk modification
      if(StringFind(q, "change risk") >= 0 || StringFind(q, "set lot") >= 0 ||
         StringFind(q, "increase risk") >= 0 || StringFind(q, "decrease risk") >= 0 ||
         StringFind(q, "modify risk") >= 0 || StringFind(q, "set equity risk") >= 0)
         return GM_CHAT_SEC_BLOCK_RISK;

      // Strategy change
      if(StringFind(q, "change strategy") >= 0 || StringFind(q, "disable gold mind") >= 0 ||
         StringFind(q, "override strategy") >= 0 || StringFind(q, "change levels") >= 0 ||
         StringFind(q, "change atr") >= 0 || StringFind(q, "change stop loss pip") >= 0)
         return GM_CHAT_SEC_BLOCK_STRATEGY;

      return GM_CHAT_SEC_ALLOW;
     }

   bool IsAllowed(const ENUM_GM_CHAT_SECURITY s) const
     {
      return (s == GM_CHAT_SEC_ALLOW);
     }

   string BlockMessage(const ENUM_GM_CHAT_SECURITY s) const
     {
      if(s == GM_CHAT_SEC_ALLOW)
         return "";
      return GM_CHAT_BLOCK_MSG + " [" + GmChatSecName(s) + "]";
     }
  };

#endif // GM_CAI_COMMAND_SECURITY_LAYER_MQH
//+------------------------------------------------------------------+
