//+------------------------------------------------------------------+
//|                                  CNotificationEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CNOTIFICATION_ENGINE_MQH
#define GM_CNOTIFICATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "EnumsDashboard.mqh"
#include "CActivityTimeline.mqh"
#include "../Logging/CLogger.mqh"

/// @file CNotificationEngine.mqh
/// @brief Smart Notification Engine — UI alerts only (no trade mutations).

class CGmNotificationEngine
  {
private:
   CGmLogger           *m_logger;
   CGmActivityTimeline  m_timeline;
   string               m_banner;
   ENUM_GM_NOTIFY_SEVERITY m_banner_sev;
   datetime             m_banner_at;
   int                  m_generated;

   string TypeName(const ENUM_GM_NOTIFY_TYPE t) const
     {
      switch(t)
        {
         case GM_NOTIFY_NEW_H4_SESSION:      return "New H4 Session";
         case GM_NOTIFY_PENDING_CREATED:     return "Pending Orders Created";
         case GM_NOTIFY_TRADE_ACTIVATED:     return "Trade Activated";
         case GM_NOTIFY_TP_HIT:              return "Take Profit Hit";
         case GM_NOTIFY_SL_HIT:              return "Stop Loss Hit";
         case GM_NOTIFY_BREAK_EVEN:          return "Break Even Activated";
         case GM_NOTIFY_PARTIAL_CLOSE:       return "Partial Close Executed";
         case GM_NOTIFY_TRAILING:            return "Trailing Stop Activated";
         case GM_NOTIFY_LEVEL_REACTIVATED:   return "Level Reactivated";
         case GM_NOTIFY_RECOVERY_STARTED:    return "Recovery Started";
         case GM_NOTIFY_RECOVERY_COMPLETED:  return "Recovery Completed";
         case GM_NOTIFY_BROKER_WARNING:      return "Broker Warning";
         case GM_NOTIFY_SPREAD_WARNING:      return "Spread Warning";
         case GM_NOTIFY_CONNECTION_LOST:     return "Connection Lost";
         case GM_NOTIFY_CONNECTION_RESTORED: return "Connection Restored";
         case GM_NOTIFY_DAILY_PROFIT_TARGET: return "Daily Profit Target Achieved";
         case GM_NOTIFY_DAILY_LOSS_WARNING:  return "Daily Loss Warning";
         default:                            return "Info";
        }
     }

   ENUM_GM_NOTIFY_SEVERITY DefaultSeverity(const ENUM_GM_NOTIFY_TYPE t) const
     {
      switch(t)
        {
         case GM_NOTIFY_CONNECTION_LOST:
         case GM_NOTIFY_SL_HIT:
         case GM_NOTIFY_DAILY_LOSS_WARNING:
            return GM_SEV_ERROR;
         case GM_NOTIFY_SPREAD_WARNING:
         case GM_NOTIFY_BROKER_WARNING:
         case GM_NOTIFY_RECOVERY_STARTED:
            return GM_SEV_WARN;
         case GM_NOTIFY_TP_HIT:
         case GM_NOTIFY_DAILY_PROFIT_TARGET:
         case GM_NOTIFY_CONNECTION_RESTORED:
         case GM_NOTIFY_RECOVERY_COMPLETED:
         case GM_NOTIFY_BREAK_EVEN:
         case GM_NOTIFY_TRAILING:
            return GM_SEV_OK;
         case GM_NOTIFY_PENDING_CREATED:
            return GM_SEV_WARN;
         default:
            return GM_SEV_INFO;
        }
     }

   string SeverityStatus(const ENUM_GM_NOTIFY_SEVERITY s) const
     {
      switch(s)
        {
         case GM_SEV_OK:    return "OK";
         case GM_SEV_WARN:  return "WARN";
         case GM_SEV_PAUSE: return "PAUSE";
         case GM_SEV_ERROR: return "ERROR";
         default:           return "INFO";
        }
     }

public:
                     CGmNotificationEngine(void)
                       : m_logger(NULL), m_banner(""), m_banner_sev(GM_SEV_INFO),
                         m_banner_at(0), m_generated(0)
     {
     }

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_timeline.Clear();
      m_banner = "";
      m_generated = 0;
      if(m_logger != NULL)
         m_logger.Info("Smart Notification Engine ready", "Notifications");
     }

   CGmActivityTimeline *Timeline(void) { return GetPointer(m_timeline); }
   string Banner(void) const { return m_banner; }
   ENUM_GM_NOTIFY_SEVERITY BannerSeverity(void) const { return m_banner_sev; }
   int GeneratedCount(void) const { return m_generated; }

   void Notify(const ENUM_GM_NOTIFY_TYPE type,
               const string detail = "",
               const ulong trade_id = 0,
               const string level_id = "",
               const ulong session_id = 0)
     {
      const ENUM_GM_NOTIFY_SEVERITY sev = DefaultSeverity(type);
      const string title = TypeName(type);
      string desc = title;
      if(StringLen(detail) > 0)
         desc = title + " — " + detail;

      m_banner = desc;
      m_banner_sev = sev;
      m_banner_at = TimeCurrent();
      m_generated++;

      m_timeline.Push("Notify", desc, SeverityStatus(sev), sev,
                      trade_id, level_id, session_id);

      if(m_logger != NULL)
        {
         const string msg = StringFormat("Notification Generated | %s", desc);
         if(sev == GM_SEV_ERROR)
            m_logger.Warning(msg, "Notifications");
         else
            m_logger.Info(msg, "Notifications");
        }
     }

   void Info(const string module_name, const string description,
             const ulong trade_id = 0, const string level_id = "",
             const ulong session_id = 0)
     {
      m_timeline.Push(module_name, description, "INFO", GM_SEV_INFO,
                      trade_id, level_id, session_id);
     }
  };

#endif // GM_CNOTIFICATION_ENGINE_MQH
//+------------------------------------------------------------------+
