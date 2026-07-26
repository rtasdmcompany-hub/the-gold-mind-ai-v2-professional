//+------------------------------------------------------------------+
//|                                              CEventLogger.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CEVENT_LOGGER_MQH
#define GM_CEVENT_LOGGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../Logging/CLogger.mqh"
#include "../Logging/EnumsLogging.mqh"

/// @file CEventLogger.mqh
/// @brief Enterprise event categories for Capital Protection (AI-ready).

enum ENUM_GM_EVENT_CATEGORY
  {
   GM_EVT_ACCOUNT = 0,
   GM_EVT_RISK,
   GM_EVT_BROKER,
   GM_EVT_TRADE,
   GM_EVT_VALIDATION,
   GM_EVT_RECOVERY,
   GM_EVT_WARNING,
   GM_EVT_CRITICAL,
   GM_EVT_PERF,
   GM_EVT_HEALTH
  };

class CGmEventLogger
  {
private:
   CGmLogger *m_logger;
   bool       m_detailed;

   string CategoryName(const ENUM_GM_EVENT_CATEGORY cat) const
     {
      switch(cat)
        {
         case GM_EVT_ACCOUNT:     return "Account";
         case GM_EVT_RISK:        return "Risk";
         case GM_EVT_BROKER:      return "Broker";
         case GM_EVT_TRADE:       return "Trade";
         case GM_EVT_VALIDATION:  return "Validation";
         case GM_EVT_RECOVERY:    return "Recovery";
         case GM_EVT_WARNING:     return "Warning";
         case GM_EVT_CRITICAL:    return "Critical";
         case GM_EVT_PERF:        return "Perf";
         case GM_EVT_HEALTH:      return "Health";
        }
      return "Event";
     }

   string Format(const ENUM_GM_EVENT_CATEGORY cat,
                 const string module_name,
                 const string message) const
     {
      return StringFormat("[%s] [%s] %s", CategoryName(cat), module_name, message);
     }

public:
                     CGmEventLogger(void) : m_logger(NULL), m_detailed(false) {}
                    ~CGmEventLogger(void) { m_logger = NULL; }

   void Init(CGmLogger *logger, const bool detailed_logs)
     {
      m_logger = logger;
      m_detailed = detailed_logs;
     }

   void SetDetailed(const bool detailed) { m_detailed = detailed; }
   bool Detailed(void) const { return m_detailed; }

   void Emit(const ENUM_GM_EVENT_CATEGORY cat,
             const ENUM_GM_LOG_LEVEL severity,
             const string module_name,
             const string message)
     {
      if(m_logger == NULL)
         return;
      if(severity == GM_LOG_DEBUG && !m_detailed)
         return;

      const string msg = Format(cat, module_name, message);
      switch(severity)
        {
         case GM_LOG_DEBUG:   m_logger.Debug(msg, module_name); break;
         case GM_LOG_INFO:    m_logger.Info(msg, module_name); break;
         case GM_LOG_SUCCESS: m_logger.Success(msg, module_name); break;
         case GM_LOG_WARNING: m_logger.Warning(msg, module_name); break;
         case GM_LOG_ERROR:   m_logger.Error(msg, module_name); break;
        }
     }

   void Account(const string module_name, const string message, const ENUM_GM_LOG_LEVEL sev = GM_LOG_INFO)
     { Emit(GM_EVT_ACCOUNT, sev, module_name, message); }

   void Risk(const string module_name, const string message, const ENUM_GM_LOG_LEVEL sev = GM_LOG_INFO)
     { Emit(GM_EVT_RISK, sev, module_name, message); }

   void Broker(const string module_name, const string message, const ENUM_GM_LOG_LEVEL sev = GM_LOG_INFO)
     { Emit(GM_EVT_BROKER, sev, module_name, message); }

   void Trade(const string module_name, const string message, const ENUM_GM_LOG_LEVEL sev = GM_LOG_INFO)
     { Emit(GM_EVT_TRADE, sev, module_name, message); }

   void Validation(const string module_name, const string message, const ENUM_GM_LOG_LEVEL sev = GM_LOG_WARNING)
     { Emit(GM_EVT_VALIDATION, sev, module_name, message); }

   void Recovery(const string module_name, const string message, const ENUM_GM_LOG_LEVEL sev = GM_LOG_INFO)
     { Emit(GM_EVT_RECOVERY, sev, module_name, message); }

   void Warn(const string module_name, const string message)
     { Emit(GM_EVT_WARNING, GM_LOG_WARNING, module_name, message); }

   void Critical(const string module_name, const string message)
     { Emit(GM_EVT_CRITICAL, GM_LOG_ERROR, module_name, message); }

   void Perf(const string module_name, const string message, const ENUM_GM_LOG_LEVEL sev = GM_LOG_DEBUG)
     { Emit(GM_EVT_PERF, sev, module_name, message); }

   void Health(const string module_name, const string message, const ENUM_GM_LOG_LEVEL sev = GM_LOG_INFO)
     { Emit(GM_EVT_HEALTH, sev, module_name, message); }
  };

#endif // GM_CEVENT_LOGGER_MQH
//+------------------------------------------------------------------+
