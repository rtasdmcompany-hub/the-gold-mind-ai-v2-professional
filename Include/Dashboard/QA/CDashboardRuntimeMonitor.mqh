//+------------------------------------------------------------------+
//|                                CDashboardRuntimeMonitor.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CDASHBOARD_RUNTIME_MONITOR_MQH
#define GM_CDASHBOARD_RUNTIME_MONITOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "DashboardQAConstants.mqh"
#include "CDashboardPerfMonitor.mqh"
#include "../../Logging/CLogger.mqh"

/// @file CDashboardRuntimeMonitor.mqh
/// @brief Long-runtime stability tracker (12/24/48/72h milestones).

class CGmDashboardRuntimeMonitor
  {
private:
   CGmLogger               *m_logger;
   CGmDashboardPerfMonitor *m_perf;
   datetime                 m_start;
   bool                     m_hit_12;
   bool                     m_hit_24;
   bool                     m_hit_48;
   bool                     m_hit_72;
   bool                     m_ready;

public:
                     CGmDashboardRuntimeMonitor(void)
                       : m_logger(NULL), m_perf(NULL), m_start(0),
                         m_hit_12(false), m_hit_24(false), m_hit_48(false),
                         m_hit_72(false), m_ready(false)
     {
     }

   void Init(CGmLogger *logger, CGmDashboardPerfMonitor *perf)
     {
      m_logger = logger;
      m_perf = perf;
      m_start = TimeCurrent();
      m_hit_12 = false;
      m_hit_24 = false;
      m_hit_48 = false;
      m_hit_72 = false;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Long Runtime Monitor armed | milestones 12/24/48/72h",
                       "DashRuntime");
     }

   bool IsReady(void) const { return m_ready; }
   int HoursElapsed(void) const
     {
      if(m_start <= 0)
         return 0;
      return (int)((TimeCurrent() - m_start) / 3600);
     }

   void Process(void)
     {
      if(!m_ready)
         return;
      if(m_perf != NULL)
         m_perf.SampleMemory();

      const int h = HoursElapsed();
      if(!m_hit_12 && h >= 12)
        {
         m_hit_12 = true;
         LogMilestone(12);
        }
      if(!m_hit_24 && h >= 24)
        {
         m_hit_24 = true;
         LogMilestone(24);
        }
      if(!m_hit_48 && h >= 48)
        {
         m_hit_48 = true;
         LogMilestone(48);
        }
      if(!m_hit_72 && h >= 72)
        {
         m_hit_72 = true;
         LogMilestone(72);
        }
     }

   void LogMilestone(const int hours)
     {
      if(m_logger == NULL)
         return;
      const ulong mem = (m_perf != NULL) ? m_perf.MemEnd() : (ulong)TerminalInfoInteger(TERMINAL_MEMORY_USED);
      m_logger.Success(StringFormat("Runtime Milestone %dh | mem=%I64uKB | avgCollect=%.0fus",
                                    hours, mem,
                                    (m_perf != NULL) ? m_perf.AvgUs() : 0.0),
                       "DashRuntime");
     }

   string StatusLine(void) const
     {
      return StringFormat("uptime=%dh | 12=%s 24=%s 48=%s 72=%s",
                          HoursElapsed(),
                          m_hit_12 ? "Y" : "N",
                          m_hit_24 ? "Y" : "N",
                          m_hit_48 ? "Y" : "N",
                          m_hit_72 ? "Y" : "N");
     }
  };

#endif // GM_CDASHBOARD_RUNTIME_MONITOR_MQH
//+------------------------------------------------------------------+
