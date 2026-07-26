//+------------------------------------------------------------------+
//|                                      CEnterpriseLogContext.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CENTERPRISE_LOG_CONTEXT_MQH
#define GM_CENTERPRISE_LOG_CONTEXT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../Logging/CLogger.mqh"
#include "../Logging/EnumsLogging.mqh"

/// @file CEnterpriseLogContext.mqh
/// @brief Structured enterprise log lines (traceable fields).

class CGmEnterpriseLogContext
  {
private:
   CGmLogger *m_logger;
   long       m_magic;
   ulong      m_session_id;
   bool       m_enabled;
   datetime   m_last_info_ts;
   string     m_last_info_key;

public:
                     CGmEnterpriseLogContext(void)
                       : m_logger(NULL), m_magic(0), m_session_id(0),
                         m_enabled(true), m_last_info_ts(0), m_last_info_key("")
     {
     }

                    ~CGmEnterpriseLogContext(void) { m_logger = NULL; }

   void Init(CGmLogger *logger, const long magic, const bool enabled)
     {
      m_logger = logger;
      m_magic = magic;
      m_enabled = enabled;
     }

   void SetSessionId(const ulong sid) { m_session_id = sid; }

   string Build(const string module,
                const string message,
                const ulong trade_id = 0,
                const ulong level_id = 0,
                const ulong exec_us = 0,
                const int error_code = 0,
                const string recovery_action = "") const
     {
      return StringFormat("%s | Magic=%I64d | SID=%I64u | TID=%I64u | LID=%I64u | ExecUs=%I64u | Err=%d | Recovery=%s | %s",
                          module,
                          m_magic,
                          m_session_id,
                          trade_id,
                          level_id,
                          exec_us,
                          error_code,
                          (StringLen(recovery_action) > 0 ? recovery_action : "-"),
                          message);
     }

   void Emit(const ENUM_GM_LOG_LEVEL sev,
             const string module,
             const string message,
             const ulong trade_id = 0,
             const ulong level_id = 0,
             const ulong exec_us = 0,
             const int error_code = 0,
             const string recovery_action = "")
     {
      if(!m_enabled || m_logger == NULL)
         return;
      const string line = Build(module, message, trade_id, level_id, exec_us, error_code, recovery_action);
      switch(sev)
        {
         case GM_LOG_DEBUG:   m_logger.Debug(line, module); break;
         case GM_LOG_INFO:    m_logger.Info(line, module); break;
         case GM_LOG_SUCCESS: m_logger.Success(line, module); break;
         case GM_LOG_WARNING: m_logger.Warning(line, module); break;
         case GM_LOG_ERROR:   m_logger.Error(line, module); break;
        }
     }

   /// @brief Throttle identical INFO keys to once per second (performance mode).
   void InfoThrottled(const string key, const string module, const string message)
     {
      if(!m_enabled || m_logger == NULL)
         return;
      const datetime now = TimeCurrent();
      if(key == m_last_info_key && now == m_last_info_ts)
         return;
      m_last_info_key = key;
      m_last_info_ts = now;
      Emit(GM_LOG_INFO, module, message);
     }
  };

#endif // GM_CENTERPRISE_LOG_CONTEXT_MQH
//+------------------------------------------------------------------+
