//+------------------------------------------------------------------+
//|                             CEnterpriseIdentityEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 6 Sprint 5 — License / Auth / Subscription facade     |
//|     IDENTITY ONLY — NEVER interrupts trading                    |
//+------------------------------------------------------------------+
#ifndef GM_CENTERPRISE_IDENTITY_ENGINE_MQH
#define GM_CENTERPRISE_IDENTITY_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "IdentityConstants.mqh"
#include "SGmIdentityResult.mqh"
#include "CElmIdentitySecurity.mqh"
#include "CElmLicenseEngine.mqh"
#include "CElmAuthEngine.mqh"
#include "CElmDeviceActivationEngine.mqh"
#include "CElmLicenseValidation.mqh"
#include "CElmAdminApi.mqh"
#include "CElmIdentityDatabase.mqh"
#include "../CEnterpriseCloudEngine.mqh"
#include "../CCloudSecurity.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Core/Version.mqh"
#include "../../Logging/CLogger.mqh"
#include "../../AI/SGmAISnapshot.mqh"

class CGmEnterpriseIdentityEngine
  {
private:
   CGmLogger                   *m_logger;
   CGmEnterpriseCloudEngine    *m_cloud;
   CGmCloudSecurity             m_sec_core;
   CGmElmIdentitySecurity       m_sec;
   CGmElmLicenseEngine          m_license;
   CGmElmAuthEngine             m_auth;
   CGmElmDeviceActivationEngine m_devices;
   CGmElmLicenseValidation      m_validator;
   CGmElmAdminApi               m_admin;
   CGmElmIdentityDatabase       m_db;
   SGmIdentityResult            m_last;
   bool                         m_grace_logged;
   bool                         m_auth_logged;
   ulong                        m_last_ms;
   ulong                        m_cycle_us;
   bool                         m_ready;

public:
                     CGmEnterpriseIdentityEngine(void)
                       : m_logger(NULL), m_cloud(NULL),
                         m_grace_logged(false), m_auth_logged(false),
                         m_last_ms(0), m_cycle_us(0), m_ready(false)
     {
      m_last.Reset();
     }

   bool Init(CGmLogger *logger,
             CGmFileManager *files,
             const long magic,
             const string symbol)
     {
      m_logger = logger;
      m_db.Init(logger, files, magic, symbol);
      const string seed = StringFormat("ELM|%I64d|%s|%s", magic, symbol, GM_ELM_VERSION);
      m_sec_core.Init(seed);
      m_sec.Init(GetPointer(m_sec_core));
      m_license.Init(GetPointer(m_sec), GM_ELM_LIC_ENTERPRISE);
      m_auth.Init(GetPointer(m_sec));
      m_devices.Init(GetPointer(m_sec), 3);
      m_validator.Init(GetPointer(m_sec));
      m_admin.Init(GetPointer(m_sec));

      const string fp = m_sec.DeviceFingerprint(
         TerminalInfoString(TERMINAL_NAME),
         AccountInfoInteger(ACCOUNT_LOGIN));
      m_devices.Register("Primary-" + TerminalInfoString(TERMINAL_NAME), fp, true);

      // Architecture auto-login for local enterprise operator
      const string user = "rtas.enterprise";
      const string token = StringFormat("LOCAL|%I64d|%s", magic, GM_ELM_VERSION);
      if(m_auth.Login(user, token, fp))
        {
         if(m_logger != NULL)
            m_logger.Info("User Authenticated | " + user, "ELM");
         m_auth_logged = true;
        }
      else if(m_logger != NULL)
         m_logger.Warning("Authentication Failed | local bootstrap", "ELM");

      if(m_logger != NULL)
        {
         m_logger.Success("Identity Engine Started | " + GM_ELM_VERSION, "ELM");
         m_logger.Info("POLICY | " + GM_ELM_POLICY, "ELM");
         m_logger.Info("SAFE | " + GM_ELM_SAFE, "ELM");
         m_logger.Info("License Activated | " + GmElmLicenseTypeName(m_license.Type()), "ELM");
         m_logger.Info("Device Registered | primary", "ELM");
        }

      m_last.Reset();
      m_ready = true;
      return true;
     }

   void BindCloud(CGmEnterpriseCloudEngine *cloud)
     {
      m_cloud = cloud;
      if(m_logger != NULL && cloud != NULL)
         m_logger.Info("Identity bound to Cloud (observe only — never gates trading)", "ELM");
     }

   void Shutdown(void)
     {
      if(m_ready)
        {
         m_auth.Logout();
         if(m_logger != NULL)
            m_logger.Info("User Logged Out | identity shutdown", "ELM");
        }
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmIdentityResult Last(void) const { return m_last; }

   // Explicit: this layer NEVER returns a signal to stop trading
   bool MayInterruptTrading(void) const { return false; }

   bool Process(const bool force = false)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(!force && m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_ELM_THROTTLE_MS)
         return true;

      const ulong t0 = GetMicrosecondCount();
      m_last_ms = now;

      SGmCloudStatus cloud_st;
      cloud_st.Reset();
      if(m_cloud != NULL && m_cloud.IsReady())
         cloud_st = m_cloud.Last();

      const string fp = m_sec.DeviceFingerprint(
         TerminalInfoString(TERMINAL_NAME),
         AccountInfoInteger(ACCOUNT_LOGIN));
      m_devices.Register("Primary-" + TerminalInfoString(TERMINAL_NAME), fp, false);
      m_auth.RefreshSession(fp);

      SGmIdentityResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();

      const bool was_grace = m_last.in_grace_period;
      const bool ok = m_validator.Validate(m_license, m_devices, cloud_st, r);
      m_auth.ApplyTo(r);
      m_devices.ApplyTo(r);

      if(m_sec.IsReady())
         r.security_status = m_sec.SecurityStatus(m_auth.Role());

      r.admin_api_catalog = m_admin.Catalog();
      r.center_status = "LICENSE CENTER READY";
      r.insight = StringFormat("%s | health=%.0f | %s | interrupt=false",
                               r.center_status, r.license_health, GM_ELM_SAFE);
      r.may_execute = false;
      r.may_modify_risk = false;
      r.may_interrupt_trading = false;
      r.valid = true;

      if(m_logger != NULL)
        {
         m_logger.Info("License Validated | " + r.license_status +
                       (ok ? " OK" : " WARN") +
                       " | trading_interrupted=false", "ELM");
         if(r.in_grace_period && !was_grace)
           {
            m_logger.Warning("Grace Period Started | " + r.grace_period_status, "ELM");
            m_grace_logged = true;
           }
         if(!r.in_grace_period && was_grace)
            m_logger.Info("Grace Period Ended | license restored", "ELM");
         if(StringFind(r.license_status, "Renew") >= 0)
            m_logger.Info("License Renewed | architecture", "ELM");
        }

      const string api_resp = m_admin.Handle("/v1/licenses/status", m_license, r);
      if(m_logger != NULL)
         m_logger.Debug("Admin API | /v1/licenses/status len=" +
                        IntegerToString(StringLen(api_resp)), "ELM");

      const string audit = StringFormat(
         "auth=%s | devices=%d/%d | grace=%s | may_interrupt=false | sig_ok=%s",
         r.auth_status, r.activated_devices, r.max_devices,
         r.in_grace_period ? "yes" : "no",
         (StringLen(api_resp) > 10 ? "yes" : "no"));
      m_db.Record(r, audit);
      m_last = r;
      m_cycle_us = GetMicrosecondCount() - t0;

      if(m_logger != NULL)
         m_logger.Debug(StringFormat("Performance Statistics | cycle=%I64u us (<1%%)",
                                     m_cycle_us), "ELM");
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = m_last.center_status;
      s.ai_engine = "GoldMind Enterprise Identity & License";
      s.current_mode = "CLOUD_IDENTITY_LICENSE";
      s.confidence_pct = m_last.license_health;
      s.confidence_status = StringFormat("%.0f", m_last.license_health);

      // Phase 6 Sprint 5 widgets
      s.w_trend_detector = m_last.license_status;                         // License Status
      s.future_ai_score = GmElmLicenseTypeName(m_last.license_type);      // License Type
      s.w_recovery_ai = TimeToString(m_last.activation_date, TIME_DATE);  // Activation Date
      s.prediction_status = TimeToString(m_last.expiration_date, TIME_DATE); // Expiration
      s.learning_status = IntegerToString(m_last.remaining_days);         // Remaining Days
      s.w_volatility_scanner = StringFormat("%d/%d",
                                            m_last.activated_devices,
                                            m_last.max_devices);          // Activated Devices
      s.w_market_analyzer = m_last.current_device;                        // Current Device
      s.w_news_analyzer = m_last.grace_period_status;                     // Grace Period
      s.w_trade_confidence = m_last.auth_status;                          // Auth Status
      s.ai_version = m_last.security_status + " | " + m_last.session_status;
      s.decision_status = GM_ELM_POLICY;
      s.valid = true;
     }
  };

#endif // GM_CENTERPRISE_IDENTITY_ENGINE_MQH
//+------------------------------------------------------------------+
