//+------------------------------------------------------------------+
//|                                            CSessionAudit.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CSESSION_AUDIT_MQH
#define GM_CSESSION_AUDIT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SessionConstants.mqh"
#include "SGmSessionLogSettings.mqh"
#include "../Logging/CLogger.mqh"
#include "../Core/CFileManager.mqh"

/// @file CSessionAudit.mqh
/// @brief Enterprise audit trail — every session action is traceable.

enum ENUM_GM_AUDIT_EVENT
  {
   GM_AUDIT_SESSION_CREATED = 0,
   GM_AUDIT_LEVELS_GENERATED,
   GM_AUDIT_ORDER_PLACED,
   GM_AUDIT_ORDER_ACTIVATED,
   GM_AUDIT_ORDER_DELETED,
   GM_AUDIT_TRADE_OPENED,
   GM_AUDIT_TRADE_CLOSED,
   GM_AUDIT_ERROR,
   GM_AUDIT_RECOVERY,
   GM_AUDIT_SYNC,
   GM_AUDIT_CLEANUP,
   GM_AUDIT_PERF
  };

class CGmSessionAudit
  {
private:
   CGmLogger             *m_logger;
   CGmFileManager        *m_files;
   SGmSessionLogSettings  m_settings;
   string                 m_file_name;
   int                    m_line_count;
   bool                   m_ready;

   string EventName(const ENUM_GM_AUDIT_EVENT ev) const
     {
      switch(ev)
        {
         case GM_AUDIT_SESSION_CREATED:   return "SESSION_CREATED";
         case GM_AUDIT_LEVELS_GENERATED:  return "LEVELS_GENERATED";
         case GM_AUDIT_ORDER_PLACED:      return "ORDER_PLACED";
         case GM_AUDIT_ORDER_ACTIVATED:   return "ORDER_ACTIVATED";
         case GM_AUDIT_ORDER_DELETED:     return "ORDER_DELETED";
         case GM_AUDIT_TRADE_OPENED:      return "TRADE_OPENED";
         case GM_AUDIT_TRADE_CLOSED:      return "TRADE_CLOSED";
         case GM_AUDIT_ERROR:             return "ERROR";
         case GM_AUDIT_RECOVERY:          return "RECOVERY";
         case GM_AUDIT_SYNC:              return "SYNC";
         case GM_AUDIT_CLEANUP:           return "CLEANUP";
         case GM_AUDIT_PERF:              return "PERF";
        }
      return "EVENT";
     }

   void RotateIfNeeded(void)
     {
      if(m_files == NULL || !m_settings.automatic_archive)
         return;
      // Soft line-based rotation proxy for max log size.
      const int max_lines = MathMax(100, m_settings.max_log_size_kb * 8);
      if(m_line_count < max_lines)
         return;
      string archived = m_file_name + ".bak";
      string content = "";
      if(m_files.ReadText(m_file_name, content))
         m_files.WriteText(archived, content);
      m_files.WriteText(m_file_name, "#GM_AUDIT_ROTATED\r\n");
      m_line_count = 0;
      if(m_logger != NULL && m_settings.enable_audit_logs)
         m_logger.Info("Audit log archived/rotated", "SessionAudit");
     }

public:
                     CGmSessionAudit(void)
                       : m_logger(NULL), m_files(NULL), m_file_name(""),
                         m_line_count(0), m_ready(false)
     {
      m_settings.Defaults();
     }

                    ~CGmSessionAudit(void) { m_logger = NULL; m_files = NULL; }

   void Init(CGmLogger *logger,
             CGmFileManager *files,
             const long magic,
             const string symbol,
             const SGmSessionLogSettings &settings)
     {
      m_logger = logger;
      m_files = files;
      m_settings = settings;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_file_name = StringFormat("%s%I64d_%s.log", GM_SESSION_AUDIT_PREFIX, magic, sym);
      m_ready = true;
      if(m_logger != NULL && m_settings.enable_audit_logs)
         m_logger.Info("Session Audit System ready", "SessionAudit");
     }

   void Record(const ENUM_GM_AUDIT_EVENT ev,
               const string module_name,
               const string message,
               const ulong session_id = 0)
     {
      if(!m_ready || !m_settings.enable_audit_logs)
         return;

      const string line = StringFormat("%s|%s|%s|SID=%I64u|%s",
                                       TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS),
                                       EventName(ev),
                                       module_name,
                                       session_id,
                                       message);

      if(m_logger != NULL)
        {
         if(ev == GM_AUDIT_ERROR)
            m_logger.Error(line, "SessionAudit");
         else if(ev == GM_AUDIT_RECOVERY && m_settings.enable_recovery_logs)
            m_logger.Info(line, "SessionAudit");
         else
            m_logger.Info(line, "SessionAudit");
        }

      if(m_files != NULL)
        {
         string existing = "";
         if(m_files.Exists(m_file_name))
            m_files.ReadText(m_file_name, existing);
         existing += line + "\r\n";
         m_files.WriteText(m_file_name, existing);
         m_line_count++;
         RotateIfNeeded();
        }
     }
  };

#endif // GM_CSESSION_AUDIT_MQH
//+------------------------------------------------------------------+
