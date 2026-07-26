//+------------------------------------------------------------------+
//|                                               CFileManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|                        Copyright 2026, RTAS Softwear            |
//+------------------------------------------------------------------+
#ifndef GM_CFILE_MANAGER_MQH
#define GM_CFILE_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Softwear"
#property link      "https://rtas.softwear"

#include "Defines.mqh"
#include "../Logging/CLogger.mqh"
#include "CErrorManager.mqh"

/// @file CFileManager.mqh
/// @brief Safe file I/O helpers for logs, reports, and future persistence.

//+------------------------------------------------------------------+
//| CGmFileManager                                                   |
//+------------------------------------------------------------------+
class CGmFileManager
  {
private:
   CGmLogger       *m_logger;
   CGmErrorManager *m_errors;
   bool             m_use_common;
   bool             m_initialized;

public:
                     CGmFileManager(void)
                       : m_logger(NULL),
                         m_errors(NULL),
                         m_use_common(true),
                         m_initialized(false)
     {
     }

                    ~CGmFileManager(void)
     {
      m_logger = NULL;
      m_errors = NULL;
     }

   /// @brief Binds logger/error manager and common-folder preference.
   bool Init(CGmLogger *logger, CGmErrorManager *errors, const bool use_common_folder = true)
     {
      m_logger = logger;
      m_errors = errors;
      m_use_common = use_common_folder;
      m_initialized = true;
      if(m_logger != NULL)
         m_logger.Debug(StringFormat("FileManager ready | common=%s",
                                     m_use_common ? "true" : "false"),
                        "FileManager");
      return true;
     }

   bool IsInitialized(void) const { return m_initialized; }

   /// @brief Builds open flags with optional FILE_COMMON.
   int BuildFlags(const int base_flags) const
     {
      if(m_use_common)
         return base_flags | FILE_COMMON;
      return base_flags;
     }

   /// @brief Checks whether a file exists in the configured folder.
   bool Exists(const string file_name) const
     {
      return FileIsExist(file_name, m_use_common ? FILE_COMMON : 0);
     }

   /// @brief Writes a full text payload (creates or overwrites).
   /// @return true on success.
   bool WriteText(const string file_name, const string content)
     {
      if(!m_initialized)
         return false;

      const int handle = FileOpen(file_name,
                                  BuildFlags(FILE_WRITE | FILE_TXT | FILE_ANSI));
      if(handle == INVALID_HANDLE)
        {
         if(m_errors != NULL)
            m_errors.ReportLastMqlError("FileManager", "WriteText: " + file_name);
         return false;
        }

      FileWriteString(handle, content);
      FileClose(handle);
      return true;
     }

   /// @brief Appends a line of text to a file.
   bool AppendLine(const string file_name, const string line)
     {
      if(!m_initialized)
         return false;

      const int handle = FileOpen(file_name,
                                  BuildFlags(FILE_READ | FILE_WRITE | FILE_TXT | FILE_ANSI));
      if(handle == INVALID_HANDLE)
        {
         if(m_errors != NULL)
            m_errors.ReportLastMqlError("FileManager", "AppendLine: " + file_name);
         return false;
        }

      FileSeek(handle, 0, SEEK_END);
      FileWriteString(handle, line + "\r\n");
      FileClose(handle);
      return true;
     }

   /// @brief Reads an entire text file into out_content.
   bool ReadText(const string file_name, string &out_content)
     {
      out_content = "";
      if(!m_initialized)
         return false;

      const int handle = FileOpen(file_name,
                                  BuildFlags(FILE_READ | FILE_TXT | FILE_ANSI));
      if(handle == INVALID_HANDLE)
        {
         if(m_errors != NULL)
            m_errors.ReportLastMqlError("FileManager", "ReadText: " + file_name);
         return false;
        }

      while(!FileIsEnding(handle))
         out_content += FileReadString(handle);

      FileClose(handle);
      return true;
     }
  };

#endif // GM_CFILE_MANAGER_MQH
//+------------------------------------------------------------------+
