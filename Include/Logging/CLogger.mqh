//+------------------------------------------------------------------+
//|                                                     CLogger.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|                        Copyright 2026, RTAS Softwear            |
//+------------------------------------------------------------------+
#ifndef GM_CLOGGER_MQH
#define GM_CLOGGER_MQH
#property copyright "Copyright 2026, RTAS Softwear"
#property link      "https://rtas.softwear"
#property strict

#include "../Core/Version.mqh"
#include "../Core/Defines.mqh"
#include "EnumsLogging.mqh"

/// @file CLogger.mqh
/// @brief Professional, centralized logging framework for all modules.
/// @details Supports DEBUG / INFO / SUCCESS / WARNING / ERROR with
///          terminal and optional file output. Future-proof for report hooks.

//+------------------------------------------------------------------+
//| CGmLogger                                                        |
//+------------------------------------------------------------------+
class CGmLogger
  {
private:
   string                  m_module_name;
   ENUM_GM_LOG_LEVEL       m_min_level;
   ENUM_GM_LOG_DESTINATION m_destination;
   bool                    m_initialized;
   bool                    m_file_enabled;
   string                  m_file_name;
   int                     m_file_handle;
   ulong                   m_sequence;

   /// @brief Converts a log level to a fixed-width label.
   string LevelToString(const ENUM_GM_LOG_LEVEL level) const
     {
      switch(level)
        {
         case GM_LOG_DEBUG:   return "DEBUG  ";
         case GM_LOG_INFO:    return "INFO   ";
         case GM_LOG_SUCCESS: return "SUCCESS";
         case GM_LOG_WARNING: return "WARNING";
         case GM_LOG_ERROR:   return "ERROR  ";
         default:             return "UNKNOWN";
        }
     }

   /// @brief Builds a single formatted log line.
   string FormatLine(const ENUM_GM_LOG_LEVEL level,
                     const string module_tag,
                     const string message) const
     {
      string tag = module_tag;
      if(StringLen(tag) == 0)
         tag = m_module_name;

      return StringFormat("[%s] [%s] [%s] [#%I64u] %s",
                          TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS),
                          LevelToString(level),
                          tag,
                          m_sequence,
                          message);
     }

   /// @brief Writes one line to the configured destinations.
   void Emit(const ENUM_GM_LOG_LEVEL level,
             const string module_tag,
             const string message)
     {
      if(!m_initialized)
         return;
      if(level < m_min_level)
         return;

      m_sequence++;
      const string line = FormatLine(level, module_tag, message);

      if(m_destination == GM_LOG_DEST_TERMINAL || m_destination == GM_LOG_DEST_BOTH)
         Print(line);

      if(m_file_enabled &&
         (m_destination == GM_LOG_DEST_FILE || m_destination == GM_LOG_DEST_BOTH) &&
         m_file_handle != INVALID_HANDLE)
        {
         FileWriteString(m_file_handle, line + "\r\n");
         FileFlush(m_file_handle);
        }
     }

public:
   /// @brief Constructs an uninitialized logger.
                     CGmLogger(void)
                       : m_module_name("Core"),
                         m_min_level(GM_LOG_INFO),
                         m_destination(GM_LOG_DEST_TERMINAL),
                         m_initialized(false),
                         m_file_enabled(false),
                         m_file_name(""),
                         m_file_handle(INVALID_HANDLE),
                         m_sequence(0)
     {
     }

   /// @brief Ensures file handle is closed on destruction.
                    ~CGmLogger(void)
     {
      Shutdown();
     }

   /// @brief Initializes logger with destination and verbosity.
   /// @param module_name Default module tag for messages.
   /// @param min_level Minimum level that will be emitted.
   /// @param destination Terminal, file, or both.
   /// @param enable_file When true, opens a dated log file under Files.
   /// @return true on success.
   bool Init(const string module_name,
             const ENUM_GM_LOG_LEVEL min_level = GM_LOG_INFO,
             const ENUM_GM_LOG_DESTINATION destination = GM_LOG_DEST_TERMINAL,
             const bool enable_file = false)
     {
      m_module_name  = module_name;
      m_min_level    = min_level;
      m_destination  = destination;
      m_file_enabled = enable_file;
      m_sequence     = 0;

      if(m_file_enabled &&
         (m_destination == GM_LOG_DEST_FILE || m_destination == GM_LOG_DEST_BOTH))
        {
         string date_part = TimeToString(TimeCurrent(), TIME_DATE);
         StringReplace(date_part, ".", "-");
         StringReplace(date_part, ":", "-");
         StringReplace(date_part, " ", "_");
         m_file_name = StringFormat("%s%s_%s.log",
                                    GM_LOG_FILE_PREFIX,
                                    GM_PRODUCT_SHORT,
                                    date_part);

         m_file_handle = FileOpen(m_file_name,
                                  FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
         if(m_file_handle == INVALID_HANDLE)
           {
            m_file_enabled = false;
            Print("[LOGGER] Failed to open log file: ", m_file_name,
                  " | error=", GetLastError());
           }
        }

      m_initialized = true;
      Info("Logger initialized | " + GmVersionBanner());
      return true;
     }

   /// @brief Closes file resources and marks logger inactive.
   void Shutdown(void)
     {
      if(m_file_handle != INVALID_HANDLE)
        {
         FileClose(m_file_handle);
         m_file_handle = INVALID_HANDLE;
        }
      m_initialized = false;
     }

   /// @brief Updates minimum log level at runtime.
   void SetMinLevel(const ENUM_GM_LOG_LEVEL level) { m_min_level = level; }

   /// @brief Returns current minimum log level.
   ENUM_GM_LOG_LEVEL GetMinLevel(void) const { return m_min_level; }

   /// @brief Returns whether Init has completed successfully.
   bool IsInitialized(void) const { return m_initialized; }

   void Debug(const string message, const string module_tag = "")
     { Emit(GM_LOG_DEBUG, module_tag, message); }

   void Info(const string message, const string module_tag = "")
     { Emit(GM_LOG_INFO, module_tag, message); }

   void Success(const string message, const string module_tag = "")
     { Emit(GM_LOG_SUCCESS, module_tag, message); }

   void Warning(const string message, const string module_tag = "")
     { Emit(GM_LOG_WARNING, module_tag, message); }

   void Error(const string message, const string module_tag = "")
     { Emit(GM_LOG_ERROR, module_tag, message); }
  };

#endif // GM_CLOGGER_MQH
//+------------------------------------------------------------------+
