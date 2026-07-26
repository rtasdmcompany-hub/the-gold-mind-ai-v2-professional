//+------------------------------------------------------------------+
//|                                          SGmAIEventRecord.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_AI_EVENT_RECORD_MQH
#define GM_SGM_AI_EVENT_RECORD_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "AIConstants.mqh"

struct SGmAIEventRecord
  {
   ulong                 event_id;
   datetime              stamped_at;
   ENUM_GM_AI_EVENT_TYPE type;
   string                module_name;
   string                description;
   double                confidence;
   ulong                 session_id;
   bool                  used;

   void Reset(void)
     {
      event_id = 0;
      stamped_at = 0;
      type = GM_AI_EVT_INFO;
      module_name = "";
      description = "";
      confidence = 0.0;
      session_id = 0;
      used = false;
     }
  };

#endif // GM_SGM_AI_EVENT_RECORD_MQH
//+------------------------------------------------------------------+
