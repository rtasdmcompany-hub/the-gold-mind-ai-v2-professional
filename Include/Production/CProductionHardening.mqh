//+------------------------------------------------------------------+
//|                                     CProductionHardening.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CPRODUCTION_HARDENING_MQH
#define GM_CPRODUCTION_HARDENING_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmProductionSettings.mqh"
#include "CEnterpriseLogContext.mqh"
#include "CFailSafeEngine.mqh"
#include "CSecurityGuard.mqh"
#include "CLiveExecutionValidator.mqh"
#include "../Core/CFileManager.mqh"
#include "../Core/Version.mqh"
#include "../Session/CH4SessionEngine.mqh"
#include "../Trading/CTradeRegistry.mqh"
#include "../Trading/CTradeOwnership.mqh"

/// @file CProductionHardening.mqh
/// @brief Sprint 9 / RC-1 orchestrator — fail-safe, security, live checks, modes.

class CGmProductionHardening
  {
private:
   CGmLogger                 *m_logger;
   CGmFileManager            *m_files;
   CGmEnterpriseLogContext    m_elog;
   CGmFailSafeEngine          m_failsafe;
   CGmSecurityGuard           m_security;
   CGmLiveExecutionValidator  m_live;
   SGmProductionSettings      m_settings;
   CGmH4SessionEngine        *m_session;
   CGmTradeRegistry          *m_registry;
   datetime                   m_last_live_check;
   datetime                   m_last_flush;
   bool                       m_ready;

public:
                     CGmProductionHardening(void)
                       : m_logger(NULL), m_files(NULL), m_session(NULL),
                         m_registry(NULL), m_last_live_check(0), m_last_flush(0),
                         m_ready(false)
     {
      m_settings.Defaults();
     }

                    ~CGmProductionHardening(void)
     {
      m_logger = NULL;
      m_files = NULL;
      m_session = NULL;
      m_registry = NULL;
     }

   bool Init(CGmLogger *logger,
             CGmFileManager *files,
             CGmExecutionControl *exec,
             CGmTradeRegistry *registry,
             CGmTradeOwnership *ownership,
             CGmH4SessionEngine *session,
             const string symbol,
             const long magic,
             const SGmProductionSettings &settings)
     {
      m_logger = logger;
      m_files = files;
      m_registry = registry;
      m_session = session;
      m_settings = settings;

      if(logger != NULL)
         logger.SetMinLevel(settings.logging_level);

      m_elog.Init(logger, magic, settings.enterprise_logging);
      if(session != NULL)
         m_elog.SetSessionId(session.CurrentSessionId());

      m_failsafe.Init(logger, GetPointer(m_elog), settings.enable_fail_safe);
      m_security.Init(logger, GetPointer(m_elog), exec, registry, ownership,
                      magic, symbol, settings.enable_security_guard);
      m_live.Init(logger, GetPointer(m_elog), ownership, registry, session,
                  symbol, magic, settings.enable_live_validation);

      m_ready = true;
      m_elog.Emit(GM_LOG_SUCCESS, "Production",
                  StringFormat("RC-1 Hardening ready | mode=%d perf=%s recovery=%s",
                               (int)settings.runtime_mode,
                               settings.performance_mode ? "ON" : "OFF",
                               settings.recovery_mode ? "ON" : "OFF"));
      return true;
     }

   void Shutdown(void)
     {
      if(m_registry != NULL)
         m_registry.Flush();
      m_ready = false;
     }

   CGmFailSafeEngine *FailSafe(void) { return GetPointer(m_failsafe); }
   CGmSecurityGuard *Security(void) { return GetPointer(m_security); }
   CGmEnterpriseLogContext *ELog(void) { return GetPointer(m_elog); }
   SGmProductionSettings Settings(void) const { return m_settings; }
   bool PerformanceMode(void) const { return m_settings.performance_mode; }

   bool CanPlaceNewOrders(void)
     {
      if(!m_ready)
         return true;
      m_failsafe.Process();
      if(!m_failsafe.CanPlaceNewOrders())
         return false;
      if(!m_security.ValidateMagic())
         return false;
      return true;
     }

   bool CanPlacePending(const string level_tag)
     {
      if(!CanPlaceNewOrders())
         return false;
      return m_security.CanPlacePending(level_tag);
     }

   string BlockReason(void) const
     {
      if(!m_failsafe.CanPlaceNewOrders())
         return m_failsafe.Reason();
      return m_security.LastReason();
     }

   void Process(void)
     {
      if(!m_ready)
         return;

      m_failsafe.Process();
      if(m_session != NULL)
         m_elog.SetSessionId(m_session.CurrentSessionId());

      // Periodic registry flush (performance: deferred Saves)
      if(m_registry != NULL &&
         TimeCurrent() - m_last_flush >= GM_PROD_REGISTRY_FLUSH_SEC)
        {
         m_registry.Flush();
         m_last_flush = TimeCurrent();
        }

      // Live validation cadence (not every tick)
      const int live_every = m_settings.performance_mode ? 30 : 10;
      if(m_settings.enable_live_validation &&
         TimeCurrent() - m_last_live_check >= live_every)
        {
         m_security.ValidateRegistryIntegrity();
         m_live.Run();
         m_last_live_check = TimeCurrent();
        }
     }

   void WriteRcReport(const string extra = "")
     {
      if(m_files == NULL)
         return;
      string body = "";
      body += "====================================================\r\n";
      body += "THE GOLD MIND AI PROFESSIONAL — RC-1 REPORT\r\n";
      body += "====================================================\r\n";
      body += GmVersionBanner() + "\r\n";
      body += GmOwnershipBanner() + "\r\n";
      body += StringFormat("ReleaseCandidate=%s | Build=%d\r\n", GM_RC_LABEL, GM_VERSION_BUILD);
      body += StringFormat("RuntimeMode=%d | PerformanceMode=%s | RecoveryMode=%s\r\n",
                           (int)m_settings.runtime_mode,
                           m_settings.performance_mode ? "ON" : "OFF",
                           m_settings.recovery_mode ? "ON" : "OFF");
      body += StringFormat("FailSafe=%s | Security=%s | LiveValidation=%s\r\n",
                           m_settings.enable_fail_safe ? "ON" : "OFF",
                           m_settings.enable_security_guard ? "ON" : "OFF",
                           m_settings.enable_live_validation ? "ON" : "OFF");
      body += StringFormat("FailSafeState=%d | Reason=%s\r\n",
                           (int)m_failsafe.State(), m_failsafe.Reason());
      body += StringFormat("LiveWarnings=%d\r\n", m_live.WarningCount());
      if(StringLen(extra) > 0)
         body += extra + "\r\n";
      body += "Strategy math: UNCHANGED\r\n";
      body += "====================================================\r\n";
      m_files.WriteText(StringFormat("%sRC1_Report.txt", GM_PROD_REPORT_PREFIX), body);
     }
  };

#endif // GM_CPRODUCTION_HARDENING_MQH
//+------------------------------------------------------------------+
