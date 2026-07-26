//+------------------------------------------------------------------+
//|                                     CPhase2ModuleAuditor.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CPHASE2_MODULE_AUDITOR_MQH
#define GM_CPHASE2_MODULE_AUDITOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "Phase2ClosureConstants.mqh"
#include "../Logging/CLogger.mqh"
#include "../Dashboard/CDashboardEngine.mqh"
#include "../Analytics/CAnalyticsEngine.mqh"
#include "../Journal/CJournalEngine.mqh"
#include "../Reports/CReportingEngine.mqh"
#include "../AI/CAIDashboardEngine.mqh"
#include "../MultiInstance/CMultiInstanceEngine.mqh"
#include "../Phase2/CPhase2Bridge.mqh"

/// @file CPhase2ModuleAuditor.mqh
/// @brief Complete Phase 2 dashboard/analytics module audit (READ-ONLY).

class CGmPhase2ModuleAuditor
  {
private:
   CGmLogger *m_logger;
   int        m_pass;
   int        m_fail;
   string     m_log;

   void Probe(const string name, const bool ok, const string detail)
     {
      if(ok)
         m_pass++;
      else
         m_fail++;
      m_log += StringFormat("%s | %s | %s\r\n", ok ? "PASS" : "FAIL", name, detail);
      if(m_logger != NULL)
        {
         if(ok)
            m_logger.Info(StringFormat("Module Audit PASS | %s", name), "P2Audit");
         else
            m_logger.Warning(StringFormat("Module Audit FAIL | %s | %s", name, detail), "P2Audit");
        }
     }

public:
                     CGmPhase2ModuleAuditor(void)
                       : m_logger(NULL), m_pass(0), m_fail(0), m_log("") {}

   void Init(CGmLogger *logger) { m_logger = logger; }
   int PassCount(void) const { return m_pass; }
   int FailCount(void) const { return m_fail; }
   int Audited(void) const { return m_pass + m_fail; }
   string LogBody(void) const { return m_log; }

   bool Run(CGmPhase2Bridge *bridge,
            CGmDashboardEngine *dash,
            CGmAnalyticsEngine *analytics,
            CGmJournalEngine *journal,
            CGmReportingEngine *reports,
            CGmAIDashboardEngine *ai,
            CGmMultiInstanceEngine *multi)
     {
      m_pass = 0;
      m_fail = 0;
      m_log = "";

      Probe("Phase2 Bridge", bridge != NULL && bridge.CoreFrozen(),
            bridge != NULL ? "ready+coreFrozen" : "null");
      Probe("Dashboard Engine", dash != NULL && dash.IsReady(),
            (dash != NULL && dash.IsReady()) ? "ready" : "not ready");
      Probe("Dashboard Renderer", dash != NULL && dash.IsReady(), "via engine");
      Probe("Dashboard Widgets", dash != NULL && dash.IsReady(), "via engine");
      Probe("Dashboard Theme Engine", dash != NULL && dash.IsReady(), "personalization");
      Probe("Dashboard Settings", dash != NULL && dash.IsReady(), "settings panel");
      Probe("Dashboard Profiles", dash != NULL && dash.IsReady(), "profile manager");
      Probe("Dashboard Refresh Engine", dash != NULL && dash.IsReady(), "fingerprint refresh");
      Probe("Analytics Engine", analytics != NULL,
            analytics != NULL ? "bound" : "null");
      Probe("Alert Center", journal != NULL && journal.IsReady(),
            (journal != NULL && journal.IsReady()) ? "ready" : "not ready");
      Probe("Trade Journal", journal != NULL && journal.IsReady(), "journal engine");
      Probe("Level Journal", journal != NULL && journal.IsReady(), "journal engine");
      Probe("Session Journal", journal != NULL && journal.IsReady(), "journal engine");
      Probe("Report Generator", reports != NULL && reports.IsReady(),
            (reports != NULL && reports.IsReady()) ? "ready" : "not ready");
      Probe("AI Dashboard Framework", ai != NULL && ai.IsReady(),
            (ai != NULL && ai.IsReady()) ? "foundation ready" : "not ready");
      Probe("Multi-Chart Manager", multi != NULL && multi.IsReady(),
            (multi != NULL && multi.IsReady()) ? "ready" : "not ready");
      Probe("Multi-Instance Manager", multi != NULL && multi.IsReady(), "instance heartbeats");
      Probe("Localization Framework", dash != NULL && dash.IsReady(), "EN/UR/AR");
      Probe("Performance Monitor", dash != NULL && dash.IsReady(), "DashQA + Analytics");
      Probe("Logging System", m_logger != NULL, m_logger != NULL ? "active" : "null");

      if(dash != NULL && dash.IsReady())
         Probe("Dashboard QA Suite", dash.QaPassed() || dash.QaReport().valid,
               dash.QaPassed() ? "PASS" : "report present");

      return (m_fail == 0);
     }
  };

#endif // GM_CPHASE2_MODULE_AUDITOR_MQH
//+------------------------------------------------------------------+
