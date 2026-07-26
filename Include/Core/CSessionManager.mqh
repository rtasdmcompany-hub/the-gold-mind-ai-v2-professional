//+------------------------------------------------------------------+
//|                                            CSessionManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|                        Copyright 2026, RTAS Softwear            |
//+------------------------------------------------------------------+
#ifndef GM_CSESSION_MANAGER_MQH
#define GM_CSESSION_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Softwear"
#property link      "https://rtas.softwear"

#include "EnumsCore.mqh"
#include "../Logging/CLogger.mqh"
#include "CTimeManager.mqh"

/// @file CSessionManager.mqh
/// @brief Trading-session awareness framework (classification only).
/// @note Sprint 1 does not enforce session filters or trading windows.

//+------------------------------------------------------------------+
//| CGmSessionManager                                                |
//+------------------------------------------------------------------+
class CGmSessionManager
  {
private:
   CGmLogger       *m_logger;
   CGmTimeManager  *m_time;
   bool             m_initialized;
   ENUM_GM_SESSION_TYPE m_current_session;

   /// @brief Maps server hour to a coarse session bucket (framework default).
   ENUM_GM_SESSION_TYPE ClassifyHour(const int hour) const
     {
      // Framework defaults only — strategy session rules come later.
      if(hour >= 0 && hour < 7)
         return GM_SESSION_ASIAN;
      if(hour >= 7 && hour < 12)
         return GM_SESSION_LONDON;
      if(hour >= 12 && hour < 16)
         return GM_SESSION_OVERLAP;
      if(hour >= 16 && hour < 21)
         return GM_SESSION_NEWYORK;
      return GM_SESSION_CLOSED;
     }

public:
                     CGmSessionManager(void)
                       : m_logger(NULL),
                         m_time(NULL),
                         m_initialized(false),
                         m_current_session(GM_SESSION_UNKNOWN)
     {
     }

                    ~CGmSessionManager(void)
     {
      m_logger = NULL;
      m_time = NULL;
     }

   /// @brief Binds shared logger and time manager.
   bool Init(CGmLogger *logger, CGmTimeManager *time_manager)
     {
      m_logger = logger;
      m_time = time_manager;
      m_initialized = (m_time != NULL);
      if(m_initialized)
         Refresh();
      if(m_logger != NULL)
         m_logger.Debug("SessionManager ready", "SessionManager");
      return m_initialized;
     }

   bool IsInitialized(void) const { return m_initialized; }

   /// @brief Refreshes current session classification from server time.
   void Refresh(void)
     {
      if(!m_initialized || m_time == NULL)
        {
         m_current_session = GM_SESSION_UNKNOWN;
         return;
        }
      m_current_session = ClassifyHour(m_time.ServerHour());
     }

   ENUM_GM_SESSION_TYPE CurrentSession(void) const { return m_current_session; }

   string CurrentSessionName(void) const
     {
      switch(m_current_session)
        {
         case GM_SESSION_ASIAN:    return "Asian";
         case GM_SESSION_LONDON:   return "London";
         case GM_SESSION_NEWYORK:  return "NewYork";
         case GM_SESSION_OVERLAP:  return "London/NY Overlap";
         case GM_SESSION_CLOSED:   return "Closed/Off";
         default:                  return "Unknown";
        }
     }

   /// @brief Framework hook: future sprints may gate trading here.
   /// @return Always true in Sprint 1 (no session filtering).
   bool IsTradingAllowed(void) const
     {
      return true;
     }
  };

#endif // GM_CSESSION_MANAGER_MQH
//+------------------------------------------------------------------+
