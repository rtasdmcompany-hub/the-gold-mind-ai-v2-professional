//+------------------------------------------------------------------+
//|                                       CAIAuditTrailSystem.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_AUDIT_TRAIL_SYSTEM_MQH
#define GM_CAI_AUDIT_TRAIL_SYSTEM_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ReportingAIConstants.mqh"
#include "../../Logging/CLogger.mqh"

class CGmAIAuditTrailSystem
  {
private:
   CGmLogger *m_logger;
   string     m_events[GM_RPT_AUDIT_MAX];
   int        m_n;

public:
                     CGmAIAuditTrailSystem(void) : m_logger(NULL), m_n(0) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_n = 0;
     }

   void Record(const string activity)
     {
      const string line = StringFormat("%s | %s | %s",
                                       TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS),
                                       activity,
                                       GM_RPT_ANALYSIS_ONLY);
      if(m_n < GM_RPT_AUDIT_MAX)
         m_events[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_RPT_AUDIT_MAX; i++)
            m_events[i - 1] = m_events[i];
         m_events[GM_RPT_AUDIT_MAX - 1] = line;
        }
      if(m_logger != NULL)
         m_logger.Info("Audit Trail Updated | " + activity, "AIRpt");
     }

   int Count(void) const { return m_n; }

   string History(void) const
     {
      string body = "";
      const int show = MathMin(m_n, 6);
      for(int i = m_n - show; i < m_n; i++)
        {
         if(i < 0) continue;
         if(StringLen(body) > 0) body += " || ";
         body += m_events[i];
        }
      if(StringLen(body) == 0)
         body = "No audit events yet";
      return body;
     }

   string Export(void) const
     {
      string body = "=== audit_reports ===\r\nPOLICY=Full transparency | No hidden AI decisions\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_events[i] + "\r\n";
      return body;
     }
  };

#endif // GM_CAI_AUDIT_TRAIL_SYSTEM_MQH
//+------------------------------------------------------------------+
