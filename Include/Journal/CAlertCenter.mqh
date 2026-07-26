//+------------------------------------------------------------------+
//|                                           CAlertCenter.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CALERT_CENTER_MQH
#define GM_CALERT_CENTER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmAlertRecord.mqh"
#include "../Logging/CLogger.mqh"
#include "../Core/CFileManager.mqh"

/// @file CAlertCenter.mqh
/// @brief Enterprise Alert Center — categorized read-only alerts.

class CGmAlertCenter
  {
private:
   CGmLogger       *m_logger;
   CGmFileManager  *m_files;
   SGmAlertRecord   m_items[GM_ALERT_MAX];
   int              m_count;
   int              m_head;
   ulong            m_next_id;
   long             m_magic;
   string           m_symbol;

public:
                     CGmAlertCenter(void)
                       : m_logger(NULL), m_files(NULL), m_count(0), m_head(0),
                         m_next_id(1), m_magic(0), m_symbol("")
     {
     }

   void Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      m_magic = magic;
      m_symbol = symbol;
      m_count = 0;
      m_head = 0;
      m_next_id = 1;
      if(m_logger != NULL)
         m_logger.Info("Alert Center ready", "AlertCenter");
     }

   int Count(void) const { return m_count; }

   void Raise(const ENUM_GM_ALERT_CATEGORY category,
              const string module_name,
              const string description,
              const int priority = 3,
              const ulong trade_id = 0,
              const string level_id = "",
              const ulong session_id = 0)
     {
      SGmAlertRecord a;
      a.Reset();
      a.alert_id = m_next_id++;
      a.stamped_at = TimeCurrent();
      a.module_name = module_name;
      a.trade_id = trade_id;
      a.level_id = level_id;
      a.session_id = session_id;
      a.description = description;
      a.priority = MathMax(1, MathMin(5, priority));
      a.category = category;
      a.status = GM_ALERT_NEW;
      a.used = true;

      m_items[m_head] = a;
      m_head = (m_head + 1) % GM_ALERT_MAX;
      if(m_count < GM_ALERT_MAX)
         m_count++;

      if(m_logger != NULL)
        {
         const string msg = StringFormat("Alert Created | cat=%d | %s | %s",
                                         (int)category, module_name, description);
         if(category == GM_ALERT_ERROR || category == GM_ALERT_CRITICAL)
            m_logger.Warning(msg, "AlertCenter");
         else
            m_logger.Info(msg, "AlertCenter");
        }
     }

   bool GetRecent(const int newest_index, SGmAlertRecord &out) const
     {
      if(newest_index < 0 || newest_index >= m_count)
         return false;
      int idx = m_head - 1 - newest_index;
      while(idx < 0)
         idx += GM_ALERT_MAX;
      out = m_items[idx];
      return true;
     }

   string CategoryName(const ENUM_GM_ALERT_CATEGORY c) const
     {
      switch(c)
        {
         case GM_ALERT_SUCCESS:  return "SUCCESS";
         case GM_ALERT_WARNING:  return "WARNING";
         case GM_ALERT_ERROR:    return "ERROR";
         case GM_ALERT_CRITICAL: return "CRITICAL";
         default:                return "INFO";
        }
     }

   string FormatLine(const SGmAlertRecord &a) const
     {
      return StringFormat("%s | %s | %s | P%d | TID=%I64u | %s",
                          TimeToString(a.stamped_at, TIME_SECONDS),
                          CategoryName(a.category),
                          a.module_name,
                          a.priority,
                          a.trade_id,
                          a.description);
     }

   void PersistSnapshot(void)
     {
      if(m_files == NULL)
         return;
      string body = "#GM_ALERT_CENTER\r\n";
      const int n = MathMin(m_count, 50);
      for(int i = 0; i < n; i++)
        {
         SGmAlertRecord a;
         if(!GetRecent(i, a))
            break;
         body += FormatLine(a) + "\r\n";
        }
      string sym = m_symbol;
      StringReplace(sym, ".", "_");
      m_files.WriteText(StringFormat("%s%I64d_%s.txt", GM_ALERT_FILE_PREFIX, m_magic, sym), body);
     }
  };

#endif // GM_CALERT_CENTER_MQH
//+------------------------------------------------------------------+
