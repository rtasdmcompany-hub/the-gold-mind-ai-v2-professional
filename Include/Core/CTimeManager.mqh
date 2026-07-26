//+------------------------------------------------------------------+
//|                                               CTimeManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|                        Copyright 2026, RTAS Softwear            |
//+------------------------------------------------------------------+
#ifndef GM_CTIME_MANAGER_MQH
#define GM_CTIME_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Softwear"
#property link      "https://rtas.softwear"

#include "../Logging/CLogger.mqh"

/// @file CTimeManager.mqh
/// @brief Time utilities and new-bar detection framework (no strategy rules).

//+------------------------------------------------------------------+
//| CGmTimeManager                                                   |
//+------------------------------------------------------------------+
class CGmTimeManager
  {
private:
   CGmLogger       *m_logger;
   string           m_symbol;
   ENUM_TIMEFRAMES  m_timeframe;
   datetime         m_last_bar_time;
   bool             m_initialized;

public:
                     CGmTimeManager(void)
                       : m_logger(NULL),
                         m_symbol(""),
                         m_timeframe(PERIOD_CURRENT),
                         m_last_bar_time(0),
                         m_initialized(false)
     {
     }

                    ~CGmTimeManager(void) { m_logger = NULL; }

   /// @brief Initializes time tracking for a symbol/timeframe pair.
   bool Init(CGmLogger *logger, const string symbol, const ENUM_TIMEFRAMES timeframe)
     {
      m_logger = logger;
      m_symbol = symbol;
      m_timeframe = timeframe;
      m_last_bar_time = iTime(m_symbol, m_timeframe, 0);
      m_initialized = true;

      if(m_logger != NULL)
         m_logger.Debug(StringFormat("TimeManager ready | %s %s",
                                     m_symbol, EnumToString(m_timeframe)),
                        "TimeManager");
      return true;
     }

   bool IsInitialized(void) const { return m_initialized; }

   /// @brief Detects formation of a new bar on the configured timeframe.
   /// @return true once per new bar.
   bool IsNewBar(void)
     {
      if(!m_initialized)
         return false;

      const datetime bar_time = iTime(m_symbol, m_timeframe, 0);
      if(bar_time <= 0)
         return false;

      if(bar_time != m_last_bar_time)
        {
         m_last_bar_time = bar_time;
         return true;
        }
      return false;
     }

   datetime CurrentBarTime(void) const { return m_last_bar_time; }
   datetime ServerTime(void) const { return TimeCurrent(); }
   datetime LocalTimeNow(void) const { return TimeLocal(); }
   datetime GMTTime(void) const { return TimeGMT(); }

   /// @brief Returns hour of server time (0–23).
   int ServerHour(void) const
     {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      return dt.hour;
     }

   /// @brief Returns day of week of server time (0=Sunday).
   int ServerDayOfWeek(void) const
     {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      return dt.day_of_week;
     }
  };

#endif // GM_CTIME_MANAGER_MQH
//+------------------------------------------------------------------+
