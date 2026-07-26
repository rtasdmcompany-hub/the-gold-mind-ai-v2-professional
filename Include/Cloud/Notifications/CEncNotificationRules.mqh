//+------------------------------------------------------------------+
//|                                     CEncNotificationRules.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CENC_NOTIFICATION_RULES_MQH
#define GM_CENC_NOTIFICATION_RULES_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "NotificationCenterConstants.mqh"

class CGmEncNotificationRules
  {
private:
   ENUM_GM_ENC_RULE_MODE m_mode;
   bool                  m_ready;

public:
                     CGmEncNotificationRules(void)
                       : m_mode(GM_ENC_RULE_CUSTOM_ALL), m_ready(false) {}

   bool Init(const ENUM_GM_ENC_RULE_MODE mode = GM_ENC_RULE_CUSTOM_ALL)
     {
      m_mode = mode;
      m_ready = true;
      return true;
     }

   ENUM_GM_ENC_RULE_MODE Mode(void) const { return m_mode; }
   void SetMode(const ENUM_GM_ENC_RULE_MODE mode) { m_mode = mode; }

   bool Allows(const ENUM_GM_ENC_CATEGORY cat, const ENUM_GM_ENC_PRIORITY pri) const
     {
      if(!m_ready) return false;
      if(m_mode == GM_ENC_RULE_CRITICAL_ONLY)
         return (pri == GM_ENC_PRI_CRITICAL);
      if(m_mode == GM_ENC_RULE_TRADING_ONLY)
         return (cat == GM_ENC_CAT_TRADING || cat == GM_ENC_CAT_RECOVERY);
      if(m_mode == GM_ENC_RULE_AI_ONLY)
         return (cat == GM_ENC_CAT_AI);
      if(m_mode == GM_ENC_RULE_CLOUD_ONLY)
         return (cat == GM_ENC_CAT_CLOUD || cat == GM_ENC_CAT_LICENSE);
      if(m_mode == GM_ENC_RULE_SYSTEM_ONLY)
         return (cat == GM_ENC_CAT_SYSTEM);
      if(m_mode == GM_ENC_RULE_PERFORMANCE_ONLY)
         return (cat == GM_ENC_CAT_PERFORMANCE);
      if(m_mode == GM_ENC_RULE_SECURITY_ONLY)
         return (cat == GM_ENC_CAT_SECURITY);
      return true; // custom all
     }

   string Summary(void) const
     {
      return "Rules=" + GmEncRuleModeName(m_mode) + " | per-device prefs reserved";
     }
  };

#endif // GM_CENC_NOTIFICATION_RULES_MQH
//+------------------------------------------------------------------+
