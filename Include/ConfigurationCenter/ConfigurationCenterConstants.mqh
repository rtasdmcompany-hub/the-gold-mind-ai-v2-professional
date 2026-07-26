//+------------------------------------------------------------------+
//|                              ConfigurationCenterConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 7 Sprint 6 — Config / Profiles / Strategy Templates   |
//|     CONFIGURATION ONLY — NEVER interferes with live trading     |
//+------------------------------------------------------------------+
#ifndef GM_CONFIGURATION_CENTER_CONSTANTS_MQH
#define GM_CONFIGURATION_CENTER_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_ECC_VERSION              "1.0.0-enterprise-configuration-center"
#define GM_ECC_DB_PREFIX            "GM_ECC_"
#define GM_ECC_THROTTLE_MS          30000
#define GM_ECC_POLICY               "CONFIGURATION ONLY — NO TRADING AUTHORITY"
#define GM_ECC_SAFE                 "TEMPLATES LOCKED WHILE AI-MANAGED TRADES ACTIVE"

enum ENUM_GM_ECC_QUEUE
  {
   GM_ECC_Q_IDLE = 0,
   GM_ECC_Q_PENDING,
   GM_ECC_Q_RUNNING,
   GM_ECC_Q_CACHED,
   GM_ECC_Q_EXPORTED
  };

enum ENUM_GM_ECC_PROFILE
  {
   GM_ECC_PROF_USER = 0,
   GM_ECC_PROF_TRADER,
   GM_ECC_PROF_DEVELOPER,
   GM_ECC_PROF_DEMO,
   GM_ECC_PROF_PRODUCTION,
   GM_ECC_PROF_TESTING,
   GM_ECC_PROF_CUSTOM
  };

enum ENUM_GM_ECC_TEMPLATE
  {
   GM_ECC_TMPL_GOLDMIND_DEFAULT = 0,
   GM_ECC_TMPL_CONSERVATIVE,
   GM_ECC_TMPL_BALANCED,
   GM_ECC_TMPL_AGGRESSIVE,
   GM_ECC_TMPL_NEWS,
   GM_ECC_TMPL_SCALABILITY,
   GM_ECC_TMPL_CUSTOM
  };

string GmEccQueueName(const ENUM_GM_ECC_QUEUE q)
  {
   switch(q)
     {
      case GM_ECC_Q_PENDING:  return "Pending";
      case GM_ECC_Q_RUNNING:  return "Running";
      case GM_ECC_Q_CACHED:   return "Cached";
      case GM_ECC_Q_EXPORTED: return "Exported";
     }
   return "Idle";
  }

string GmEccProfileName(const ENUM_GM_ECC_PROFILE p)
  {
   switch(p)
     {
      case GM_ECC_PROF_USER:       return "User";
      case GM_ECC_PROF_TRADER:     return "Trader";
      case GM_ECC_PROF_DEVELOPER:  return "Developer";
      case GM_ECC_PROF_DEMO:       return "Demo";
      case GM_ECC_PROF_PRODUCTION: return "Production";
      case GM_ECC_PROF_TESTING:    return "Testing";
      case GM_ECC_PROF_CUSTOM:     return "Custom";
     }
   return "Profile";
  }

string GmEccTemplateName(const ENUM_GM_ECC_TEMPLATE t)
  {
   switch(t)
     {
      case GM_ECC_TMPL_GOLDMIND_DEFAULT: return "Gold Mind Default";
      case GM_ECC_TMPL_CONSERVATIVE:     return "Conservative";
      case GM_ECC_TMPL_BALANCED:         return "Balanced";
      case GM_ECC_TMPL_AGGRESSIVE:       return "Aggressive";
      case GM_ECC_TMPL_NEWS:             return "News Trading";
      case GM_ECC_TMPL_SCALABILITY:      return "Scalability";
      case GM_ECC_TMPL_CUSTOM:           return "Custom";
     }
   return "Template";
  }

#endif // GM_CONFIGURATION_CENTER_CONSTANTS_MQH
//+------------------------------------------------------------------+
