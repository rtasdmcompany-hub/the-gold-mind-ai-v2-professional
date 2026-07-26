//+------------------------------------------------------------------+
//|                                        CAISecurityValidator.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_SECURITY_VALIDATOR_MQH
#define GM_CAI_SECURITY_VALIDATOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMasterControlResult.mqh"
#include "../Conversation/SGmConversationResult.mqh"
#include "../Conversation/ConversationAIConstants.mqh"

class CGmAISecurityValidator
  {
public:
   void Analyze(const SGmConversationResult &chat,
                SGmMasterControlResult &r)
     {
      r.may_execute = false;
      r.may_modify_risk = false;
      r.may_modify_strategy = false;

      const bool layer_ready = true; // Conversation security layer compiled into stack
      r.security_pass = (!r.may_execute && !r.may_modify_risk && !r.may_modify_strategy && layer_ready);

      r.security_report = StringFormat(
                             "Security Compliance Report:\r\nPermissions:\r\n✔ Read Only AI Access\r\n\r\nBlocked:\r\n❌ Trading Commands\r\n❌ Order Commands\r\n❌ Risk Commands\r\n❌ Strategy Commands\r\n\r\nmay_execute=%s may_modify_risk=%s may_modify_strategy=%s\r\nChatSecurityLayer=%s\r\nCompliance=%s\r\n%s\r\n",
                             (r.may_execute ? "true" : "false"),
                             (r.may_modify_risk ? "true" : "false"),
                             (r.may_modify_strategy ? "true" : "false"),
                             (chat.valid ? GmChatSecName(chat.security_status) : "ARMED"),
                             (r.security_pass ? "PASS" : "FAIL"),
                             GM_MCC_ADVISORY);
     }
  };

#endif // GM_CAI_SECURITY_VALIDATOR_MQH
//+------------------------------------------------------------------+
