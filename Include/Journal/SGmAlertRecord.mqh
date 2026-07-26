//+------------------------------------------------------------------+
//|                                          SGmAlertRecord.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_ALERT_RECORD_MQH
#define GM_SGM_ALERT_RECORD_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "JournalConstants.mqh"

struct SGmAlertRecord
  {
   ulong                 alert_id;
   datetime              stamped_at;
   string                module_name;
   ulong                 trade_id;
   string                level_id;
   ulong                 session_id;
   string                description;
   int                   priority;       // 1..5
   ENUM_GM_ALERT_CATEGORY category;
   ENUM_GM_ALERT_STATUS  status;
   bool                  used;

   void Reset(void)
     {
      alert_id = 0;
      stamped_at = 0;
      module_name = "";
      trade_id = 0;
      level_id = "";
      session_id = 0;
      description = "";
      priority = 3;
      category = GM_ALERT_INFO;
      status = GM_ALERT_NEW;
      used = false;
     }
  };

#endif // GM_SGM_ALERT_RECORD_MQH
//+------------------------------------------------------------------+
