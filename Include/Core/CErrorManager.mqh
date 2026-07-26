//+------------------------------------------------------------------+
//|                                              CErrorManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|                        Copyright 2026, RTAS Softwear            |
//+------------------------------------------------------------------+
#ifndef GM_CERROR_MANAGER_MQH
#define GM_CERROR_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Softwear"
#property link      "https://rtas.softwear"

#include "../Core/Defines.mqh"
#include "../Core/EnumsCore.mqh"
#include "../Logging/CLogger.mqh"

/// @file CErrorManager.mqh
/// @brief Consistent error capture, classification, and reporting across modules.
/// @details Every module should report failures through this manager so logs,
///          diagnostics, and future telemetry share one contract.

//+------------------------------------------------------------------+
//| SGmErrorRecord – last-error snapshot                             |
//+------------------------------------------------------------------+
struct SGmErrorRecord
  {
   int                     code;           ///< Application or MQL error code
   ENUM_GM_ERROR_SEVERITY  severity;       ///< Severity classification
   string                  module;         ///< Originating module name
   string                  message;        ///< Human-readable description
   datetime                timestamp;      ///< Server time of capture
   bool                    active;         ///< True when a record is stored
  };

//+------------------------------------------------------------------+
//| CGmErrorManager                                                  |
//+------------------------------------------------------------------+
class CGmErrorManager
  {
private:
   CGmLogger           *m_logger;
   SGmErrorRecord       m_last;
   int                  m_error_count;
   int                  m_warning_count;
   bool                 m_initialized;

public:
                     CGmErrorManager(void)
                       : m_logger(NULL),
                         m_error_count(0),
                         m_warning_count(0),
                         m_initialized(false)
     {
      ClearLast();
     }

                    ~CGmErrorManager(void)
     {
      m_logger = NULL;
     }

   /// @brief Binds logger used for standardized error output.
   /// @param logger Pointer to shared application logger (not owned).
   /// @return true when binding succeeds.
   bool Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_error_count = 0;
      m_warning_count = 0;
      ClearLast();
      m_initialized = (m_logger != NULL);
      return m_initialized;
     }

   bool IsInitialized(void) const { return m_initialized; }

   /// @brief Clears the last error snapshot.
   void ClearLast(void)
     {
      m_last.code = GM_OK;
      m_last.severity = GM_ERROR_SEVERITY_INFO;
      m_last.module = "";
      m_last.message = "";
      m_last.timestamp = 0;
      m_last.active = false;
     }

   /// @brief Records a structured application error.
   /// @param code Numeric error code (GM_FAIL or platform code).
   /// @param severity Severity classification.
   /// @param module Origin module tag.
   /// @param message Description.
   void Report(const int code,
               const ENUM_GM_ERROR_SEVERITY severity,
               const string module,
               const string message)
     {
      m_last.code = code;
      m_last.severity = severity;
      m_last.module = module;
      m_last.message = message;
      m_last.timestamp = TimeCurrent();
      m_last.active = true;

      if(severity == GM_ERROR_SEVERITY_WARNING)
         m_warning_count++;
      else if(severity == GM_ERROR_SEVERITY_ERROR || severity == GM_ERROR_SEVERITY_CRITICAL)
         m_error_count++;

      if(m_logger == NULL || !m_logger.IsInitialized())
         return;

      const string line = StringFormat("code=%d | %s", code, message);

      switch(severity)
        {
         case GM_ERROR_SEVERITY_INFO:
            m_logger.Info(line, module);
            break;
         case GM_ERROR_SEVERITY_WARNING:
            m_logger.Warning(line, module);
            break;
         case GM_ERROR_SEVERITY_ERROR:
         case GM_ERROR_SEVERITY_CRITICAL:
            m_logger.Error(line, module);
            break;
        }
     }

   /// @brief Captures the current MQL5 GetLastError() into the manager.
   /// @param module Origin module tag.
   /// @param context Extra context appended to the message.
   /// @return The platform error code that was captured.
   int ReportLastMqlError(const string module, const string context = "")
     {
      const int err = (int)GetLastError();
      ResetLastError();

      string msg = StringFormat("MQL error %d", err);
      if(StringLen(context) > 0)
         msg = msg + " | " + context;

      const ENUM_GM_ERROR_SEVERITY sev =
         (err == 0) ? GM_ERROR_SEVERITY_INFO : GM_ERROR_SEVERITY_ERROR;
      Report(err, sev, module, msg);
      return err;
     }

   /// @brief Convenience: report a warning.
   void Warning(const string module, const string message, const int code = GM_FAIL)
     {
      Report(code, GM_ERROR_SEVERITY_WARNING, module, message);
     }

   /// @brief Convenience: report an error.
   void Error(const string module, const string message, const int code = GM_FAIL)
     {
      Report(code, GM_ERROR_SEVERITY_ERROR, module, message);
     }

   /// @brief Convenience: report a critical failure.
   void Critical(const string module, const string message, const int code = GM_FAIL)
     {
      Report(code, GM_ERROR_SEVERITY_CRITICAL, module, message);
     }

   SGmErrorRecord GetLast(void) const { return m_last; }
   bool           HasError(void) const { return m_last.active && (m_last.severity >= GM_ERROR_SEVERITY_ERROR); }
   int            ErrorCount(void) const { return m_error_count; }
   int            WarningCount(void) const { return m_warning_count; }
  };

#endif // GM_CERROR_MANAGER_MQH
//+------------------------------------------------------------------+
