//+------------------------------------------------------------------+
//|                                        CValidationEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CVALIDATION_ENGINE_MQH
#define GM_CVALIDATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmValidationSettings.mqh"
#include "CErrorClassifier.mqh"
#include "CModuleValidator.mqh"
#include "CTradeVerifier.mqh"
#include "CLifecycleValidator.mqh"
#include "CDataConsistencyChecker.mqh"
#include "CStressTestEngine.mqh"
#include "CPerformanceAnalyzer.mqh"
#include "CValidationReport.mqh"
#include "../Backtesting/CBacktestFramework.mqh"
#include "../Core/CFileManager.mqh"
#include "../Calculation/CLevelEngine.mqh"
#include "../Trading/CTradeOwnership.mqh"
#include "../Trading/CTradeIdManager.mqh"
#include "../Trading/CTradeRegistry.mqh"
#include "../Lifecycle/CLevelManager.mqh"
#include "../Protection/CCapitalProtectionEngine.mqh"
#include "../Session/CH4SessionEngine.mqh"

/// @file CValidationEngine.mqh
/// @brief Sprint 8 orchestrator — full validation suite (read-only).

class CGmValidationEngine
  {
private:
   CGmLogger                  *m_logger;
   CGmErrorClassifier          m_errors;
   CGmModuleValidator          m_modules;
   CGmTradeVerifier            m_trades;
   CGmLifecycleValidator       m_lifecycle;
   CGmDataConsistencyChecker   m_consistency;
   CGmStressTestEngine         m_stress;
   CGmPerformanceAnalyzer      m_perf;
   CGmValidationReport         m_report;
   CGmBacktestFramework        m_backtest;
   SGmValidationSettings       m_settings;
   SGmFinalValidation          m_final;
   bool                        m_ready;
   bool                        m_ran;

public:
                     CGmValidationEngine(void)
                       : m_logger(NULL), m_ready(false), m_ran(false)
     {
      m_settings.Defaults();
      m_final.Reset();
     }

                    ~CGmValidationEngine(void) { m_logger = NULL; }

   bool Init(CGmLogger *logger,
             CGmFileManager *files,
             CGmLevelEngine *levels,
             CGmTradeOwnership *ownership,
             CGmTradeIdManager *trade_ids,
             CGmTradeRegistry *registry,
             CGmLevelManager *level_mgr,
             CGmCapitalProtectionEngine *protection,
             CGmH4SessionEngine *h4_session,
             const string symbol,
             const long magic,
             const SGmValidationSettings &settings)
     {
      m_logger = logger;
      m_settings = settings;
      m_errors.Init(logger);
      m_modules.Init(logger, GetPointer(m_errors), levels, ownership, trade_ids,
                     registry, level_mgr, protection, h4_session, symbol, magic);
      m_trades.Init(logger, GetPointer(m_errors), registry, ownership, symbol, magic);
      m_lifecycle.Init(logger, GetPointer(m_errors), level_mgr);
      m_consistency.Init(logger, GetPointer(m_errors), registry, level_mgr, h4_session, magic);
      m_stress.Init(logger, GetPointer(m_errors), files, ownership, registry,
                    level_mgr, h4_session, protection, symbol, magic);
      m_perf.Init(logger, GetPointer(m_errors));
      m_report.Init(logger, files, symbol, magic);
      m_backtest.Init(logger, files, symbol, magic);
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Success("Validation Engine ready | Sprint 8 framework", "Validation");
      return true;
     }

   SGmFinalValidation Final(void) const { return m_final; }
   bool HasRun(void) const { return m_ran; }
   string ReportBody(void) const { return m_report.Body(); }

   bool RunFullSuite(void)
     {
      if(!m_ready || !m_settings.enable_validation)
         return true;

      const ulong t0 = GetMicrosecondCount();
      m_errors.Clear();

      if(m_logger != NULL)
         m_logger.Info("========== SPRINT 8 VALIDATION SUITE START ==========", "Validation");

      const ulong t_mod = GetMicrosecondCount();
      const bool modules_ok = m_modules.RunAll();
      if(!modules_ok && m_logger != NULL)
         m_logger.Warning("One or more module contract checks failed", "Validation");
      const ulong mod_us = GetMicrosecondCount() - t_mod;

      const ulong t_tr = GetMicrosecondCount();
      m_trades.VerifyAllOpen();
      const ulong trade_us = GetMicrosecondCount() - t_tr;

      m_lifecycle.Validate();
      const ulong t_db = GetMicrosecondCount();
      m_consistency.Check();
      const ulong db_us = GetMicrosecondCount() - t_db;

      if(m_settings.enable_stress_tests)
         m_stress.Run();

      if(m_settings.enable_backtest_metrics)
         m_backtest.Collect();

      const ulong session_us = mod_us; // proxy for session-related validation cost
      const ulong total_us = GetMicrosecondCount() - t0;
      m_perf.Capture(total_us, trade_us, session_us, db_us);

      m_report.Build(m_modules.PassRate(),
                     m_modules.FailCount(),
                     m_trades.WarningCount(),
                     m_lifecycle.IssueCount(),
                     m_consistency.IssueCount(),
                     m_stress.FailCount(),
                     m_errors,
                     m_perf,
                     m_backtest,
                     m_modules.DumpChecks(),
                     m_stress.Report());

      m_final = m_report.Final();
      m_ran = true;

      if(m_logger != NULL)
         m_logger.Info(StringFormat("========== VALIDATION COMPLETE | %s | %.1f | %I64u us ==========",
                                    m_final.decision, m_final.overall_score, total_us),
                       "Validation");

      return m_final.passed;
     }
  };

#endif // GM_CVALIDATION_ENGINE_MQH
//+------------------------------------------------------------------+
