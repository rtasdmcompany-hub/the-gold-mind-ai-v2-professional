//+------------------------------------------------------------------+
//|                                       CEacForensicLogging.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEAC_FORENSIC_LOGGING_MQH
#define GM_CEAC_FORENSIC_LOGGING_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "AuditConstants.mqh"
#include "CEacAuditSecurity.mqh"

struct SGmEacForensicEntry
  {
   datetime              stamped_at;
   ENUM_GM_EAC_EVENT     event_type;
   ENUM_GM_EAC_SEVERITY  severity;
   string                message;
   string                signature;
   string                seal_hash;
   string                session_id;

   void Reset(void)
     {
      stamped_at = 0;
      event_type = GM_EAC_EVT_SESSION;
      severity = GM_EAC_SEV_INFO;
      message = signature = seal_hash = session_id = "";
     }
  };

class CGmEacForensicLogging
  {
private:
   CGmEacAuditSecurity *m_sec;
   SGmEacForensicEntry  m_entries[GM_EAC_EVENT_MAX];
   int                  m_n;
   int                  m_critical;
   string               m_session_id;
   bool                 m_ready;

public:
                     CGmEacForensicLogging(void)
                       : m_sec(NULL), m_n(0), m_critical(0),
                         m_session_id(""), m_ready(false) {}

   bool Init(CGmEacAuditSecurity *sec, const string session_id)
     {
      m_sec = sec;
      m_session_id = session_id;
      m_n = 0;
      m_critical = 0;
      m_ready = true;
      return true;
     }

   int Count(void) const { return m_n; }
   int CriticalCount(void) const { return m_critical; }
   string SessionId(void) const { return m_session_id; }

   bool Record(const ENUM_GM_EAC_EVENT type,
               const ENUM_GM_EAC_SEVERITY sev,
               const string message)
     {
      if(!m_ready) return false;

      SGmEacForensicEntry e;
      e.Reset();
      e.stamped_at = TimeCurrent();
      e.event_type = type;
      e.severity = sev;
      e.message = message;
      e.session_id = m_session_id;

      const string body = StringFormat("%I64d|%s|%s|%s|%s",
                                       (long)e.stamped_at,
                                       GmEacEventName(type),
                                       GmEacSeverityName(sev),
                                       message, m_session_id);
      if(m_sec != NULL)
        {
         e.signature = m_sec.SignEntry(body);
         e.seal_hash = m_sec.SealEntry(body);
        }

      if(m_n < GM_EAC_EVENT_MAX)
         m_entries[m_n++] = e;
      else
        {
         for(int i = 1; i < GM_EAC_EVENT_MAX; i++)
            m_entries[i - 1] = m_entries[i];
         m_entries[GM_EAC_EVENT_MAX - 1] = e;
        }

      if(sev == GM_EAC_SEV_CRITICAL)
         m_critical++;
      return true;
     }

   string RecentSummary(const int max_items = 5) const
     {
      string out = "";
      const int start = MathMax(0, m_n - max_items);
      for(int i = start; i < m_n; i++)
        {
         if(StringLen(out) > 0) out += " | ";
         out += TimeToString(m_entries[i].stamped_at, TIME_SECONDS) + " " +
                GmEacEventName(m_entries[i].event_type);
        }
      return out;
     }

   string CriticalSummary(void) const
     {
      string out = "";
      for(int i = 0; i < m_n; i++)
        {
         if(m_entries[i].severity != GM_EAC_SEV_CRITICAL)
            continue;
         if(StringLen(out) > 0) out += " | ";
         out += GmEacEventName(m_entries[i].event_type) + ": " + m_entries[i].message;
        }
      return (StringLen(out) > 0) ? out : "None";
     }

   string Timeline(void) const
     {
      return RecentSummary(8);
     }

   string ExportBody(void) const
     {
      string body = "=== forensic_immutable_log ===\r\n";
      for(int i = 0; i < m_n; i++)
        {
         body += StringFormat("%s|%s|%s|%s|sig=%s|seal=%s\r\n",
                              TimeToString(m_entries[i].stamped_at, TIME_DATE | TIME_SECONDS),
                              GmEacEventName(m_entries[i].event_type),
                              GmEacSeverityName(m_entries[i].severity),
                              m_entries[i].message,
                              m_entries[i].signature,
                              m_entries[i].seal_hash);
        }
      return body;
     }
  };

#endif // GM_CEAC_FORENSIC_LOGGING_MQH
//+------------------------------------------------------------------+
