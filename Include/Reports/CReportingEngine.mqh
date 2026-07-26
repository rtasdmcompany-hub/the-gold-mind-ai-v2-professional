//+------------------------------------------------------------------+
//|                                          CReportingEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     Phase 2 Sprint 5 — Reporting Engine (READ-ONLY)             |
//+------------------------------------------------------------------+
#ifndef GM_CREPORTING_ENGINE_MQH
#define GM_CREPORTING_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CReportGenerator.mqh"
#include "CReportExport.mqh"
#include "../Journal/CJournalEngine.mqh"
#include "../Analytics/CAnalyticsEngine.mqh"
#include "../Logging/CLogger.mqh"

/// @file CReportingEngine.mqh
/// @brief Orchestrates report generation + export stubs.
/// @warning NEVER opens/closes/modifies trades or risk.

class CGmReportingEngine
  {
private:
   CGmLogger          *m_logger;
   CGmJournalEngine   *m_journal;
   CGmAnalyticsEngine *m_analytics;
   CGmReportGenerator  m_gen;
   CGmReportExport     m_export;
   datetime            m_last_auto;
   bool                m_ready;
   string              m_last_daily;

public:
                     CGmReportingEngine(void)
                       : m_logger(NULL), m_journal(NULL), m_analytics(NULL),
                         m_last_auto(0), m_ready(false), m_last_daily("")
     {
     }

                    ~CGmReportingEngine(void) { Shutdown(); }

   bool Init(CGmLogger *logger,
             CGmJournalEngine *journal,
             CGmAnalyticsEngine *analytics)
     {
      m_logger = logger;
      m_journal = journal;
      m_analytics = analytics;
      m_gen.Init(logger);
      m_export.Init(logger);
      m_last_auto = 0;
      m_last_daily = "";
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Success("Reporting Engine ready | READ-ONLY", "ReportingEngine");
      GenerateAll();
      return true;
     }

   void Shutdown(void) { m_ready = false; }
   bool IsReady(void) const { return m_ready; }
   string LastDaily(void) const { return m_last_daily; }
   CGmReportExport *ExportLayer(void) { return GetPointer(m_export); }

   string Generate(const ENUM_GM_REPORT_TYPE type)
     {
      if(!m_ready)
         return "";
      SGmAnalyticsSnapshot an;
      an.Reset();
      if(m_analytics != NULL)
        {
         m_analytics.Collect();
         an = m_analytics.Snapshot();
        }
      const string body = m_gen.Generate(type, m_journal, an);
      if(type == GM_RPT_DAILY)
         m_last_daily = body;
      return body;
     }

   void GenerateAll(void)
     {
      if(!m_ready)
         return;
      Generate(GM_RPT_DAILY);
      Generate(GM_RPT_WEEKLY);
      Generate(GM_RPT_MONTHLY);
      Generate(GM_RPT_SESSION);
      Generate(GM_RPT_TRADE);
      Generate(GM_RPT_PERFORMANCE);
      Generate(GM_RPT_RISK);
      Generate(GM_RPT_RECOVERY);
     }

   /// @brief Auto-refresh daily report at most once per sync window.
   void Process(void)
     {
      if(!m_ready)
         return;
      const datetime now = TimeCurrent();
      if(m_last_auto > 0 && (now - m_last_auto) < GM_JOURNAL_SYNC_SEC * 6)
         return;
      m_last_daily = Generate(GM_RPT_DAILY);
      m_last_auto = now;
      if(m_logger != NULL)
         m_logger.Debug("Performance Updated | Reporting Engine", "ReportingEngine");
     }

   bool PrepareExport(const ENUM_GM_REPORT_EXPORT target,
                      const ENUM_GM_REPORT_TYPE type,
                      string &out_payload)
     {
      string body = "";
      if(!m_gen.GetCached(type, body))
         body = Generate(type);
      return m_export.Prepare(target, body, out_payload);
     }
  };

#endif // GM_CREPORTING_ENGINE_MQH
//+------------------------------------------------------------------+
