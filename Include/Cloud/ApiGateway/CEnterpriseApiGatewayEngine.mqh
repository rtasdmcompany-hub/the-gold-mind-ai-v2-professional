//+------------------------------------------------------------------+
//|                            CEnterpriseApiGatewayEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 6 Sprint 8 — API Gateway / Integration facade         |
//|     READ-ONLY — NEVER executes trades                           |
//+------------------------------------------------------------------+
#ifndef GM_CENTERPRISE_API_GATEWAY_ENGINE_MQH
#define GM_CENTERPRISE_API_GATEWAY_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ApiGatewayConstants.mqh"
#include "SGmApiGatewayResult.mqh"
#include "CEapApiSecurity.mqh"
#include "CEapAuthEngine.mqh"
#include "CEapDataServices.mqh"
#include "CEapIntegrationHub.mqh"
#include "CEapDeveloperPlatform.mqh"
#include "CEapApiGateway.mqh"
#include "CEapApiDatabase.mqh"
#include "../CEnterpriseCloudEngine.mqh"
#include "../RemoteMonitor/CEnterpriseRemoteMonitorEngine.mqh"
#include "../Notifications/CEnterpriseNotificationEngine.mqh"
#include "../Identity/CEnterpriseIdentityEngine.mqh"
#include "../Backup/CEnterpriseBackupEngine.mqh"
#include "../Audit/CEnterpriseAuditEngine.mqh"
#include "../CCloudSecurity.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"
#include "../../AI/SGmAISnapshot.mqh"

class CGmEnterpriseApiGatewayEngine
  {
private:
   CGmLogger                        *m_logger;
   CGmEnterpriseCloudEngine         *m_cloud;
   CGmEnterpriseRemoteMonitorEngine *m_remote;
   CGmEnterpriseNotificationEngine  *m_notify;
   CGmEnterpriseIdentityEngine      *m_identity;
   CGmEnterpriseBackupEngine        *m_backup;
   CGmEnterpriseAuditEngine         *m_audit;
   CGmCloudSecurity                  m_sec_core;
   CGmEapApiSecurity                 m_sec;
   CGmEapAuthEngine                  m_auth;
   CGmEapDataServices                m_data;
   CGmEapIntegrationHub              m_hub;
   CGmEapDeveloperPlatform           m_dev;
   CGmEapApiGateway                  m_gateway;
   CGmEapApiDatabase                 m_db;
   SGmApiGatewayResult               m_last;
   string                            m_local_key;
   ulong                             m_last_ms;
   ulong                             m_cycle_us;
   bool                              m_ready;

public:
                     CGmEnterpriseApiGatewayEngine(void)
                       : m_logger(NULL), m_cloud(NULL), m_remote(NULL),
                         m_notify(NULL), m_identity(NULL), m_backup(NULL),
                         m_audit(NULL), m_local_key(""),
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
      const string seed = StringFormat("EAP|%I64d|%s|%s", magic, symbol, GM_EAP_VERSION);
      m_sec_core.Init(seed);
      m_sec.Init(GetPointer(m_sec_core));
      m_auth.Init(GetPointer(m_sec));
      m_data.Init(GetPointer(m_sec));
      m_hub.Init();
      m_dev.Init(files, m_db.Prefix());
      m_gateway.Init(GetPointer(m_auth), GetPointer(m_data), GetPointer(m_hub));

      m_local_key = StringFormat("local-key-%I64d", magic);
      m_auth.RegisterClient("gm-local-dashboard", GM_EAP_ROLE_APP, m_local_key);
      m_auth.RegisterClient("gm-mobile-companion", GM_EAP_ROLE_APP, m_local_key + "-mobile");
      m_auth.RegisterClient("gm-bi-connector", GM_EAP_ROLE_INTEGRATOR, m_local_key + "-bi");

      m_last.Reset();
      m_ready = true;
      if(m_logger != NULL)
        {
         m_logger.Success("API Gateway Started | " + GM_EAP_VERSION, "EAP");
         m_logger.Info("POLICY | " + GM_EAP_POLICY, "EAP");
         m_logger.Info("SAFE | " + GM_EAP_SAFE, "EAP");
         m_logger.Info("API Started | version=" + GM_EAP_API_VERSION, "EAP");
         m_logger.Info("Client Connected | gm-local-dashboard", "EAP");
        }
      return true;
     }

   void BindCloud(CGmEnterpriseCloudEngine *c) { m_cloud = c; }
   void BindRemote(CGmEnterpriseRemoteMonitorEngine *r) { m_remote = r; }
   void BindNotify(CGmEnterpriseNotificationEngine *n) { m_notify = n; }
   void BindIdentity(CGmEnterpriseIdentityEngine *i) { m_identity = i; }
   void BindBackup(CGmEnterpriseBackupEngine *b) { m_backup = b; }
   void BindAudit(CGmEnterpriseAuditEngine *a) { m_audit = a; }

   void Shutdown(void)
     {
      if(m_ready)
        {
         m_auth.Disconnect("gm-local-dashboard");
         if(m_logger != NULL)
           {
            m_logger.Info("Client Disconnected | gm-local-dashboard", "EAP");
            m_logger.Info("API Stopped", "EAP");
           }
        }
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmApiGatewayResult Last(void) const { return m_last; }
   bool MayInterruptTrading(void) const { return false; }

   bool Process(const bool force = false)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(!force && m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_EAP_THROTTLE_MS)
         return true;

      const ulong t0 = GetMicrosecondCount();
      m_last_ms = now;

      SGmCloudStatus cloud_st;
      cloud_st.Reset();
      if(m_cloud != NULL && m_cloud.IsReady())
         cloud_st = m_cloud.Last();

      SGmRemoteMonitorResult rm_st;
      rm_st.Reset();
      if(m_remote != NULL && m_remote.IsReady())
         rm_st = m_remote.Last();

      SGmNotificationCenterResult ntf_st;
      ntf_st.Reset();
      if(m_notify != NULL && m_notify.IsReady())
         ntf_st = m_notify.Last();

      SGmIdentityResult id_st;
      id_st.Reset();
      if(m_identity != NULL && m_identity.IsReady())
         id_st = m_identity.Last();

      SGmBackupResult bdr_st;
      bdr_st.Reset();
      if(m_backup != NULL && m_backup.IsReady())
         bdr_st = m_backup.Last();

      SGmAuditResult aud_st;
      aud_st.Reset();
      if(m_audit != NULL && m_audit.IsReady())
         aud_st = m_audit.Last();

      SGmApiGatewayResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();

      // Rotate read-only endpoints
      string endpoints[5];
      endpoints[0] = "/" + GM_EAP_API_VERSION + "/health";
      endpoints[1] = "/" + GM_EAP_API_VERSION + "/cloud/status";
      endpoints[2] = "/" + GM_EAP_API_VERSION + "/license";
      endpoints[3] = "/" + GM_EAP_API_VERSION + "/audit/reports";
      endpoints[4] = "/" + GM_EAP_API_VERSION + "/dashboard/stats";
      const string ep = endpoints[m_data.Served() % 5];

      const bool ok = m_gateway.ProcessOne("gm-local-dashboard", m_local_key, ep,
                                           cloud_st, rm_st, ntf_st, id_st, bdr_st, aud_st, r);
      if(m_logger != NULL)
        {
         if(ok)
           {
            m_logger.Info("Authentication Successful | gm-local-dashboard", "EAP");
            m_logger.Info("API Request Completed | " + ep, "EAP");
            m_logger.Info("Webhook Delivered | " + m_hub.WebhookStatus(), "EAP");
           }
         else
           {
            if(m_auth.RateHits() > 0)
               m_logger.Warning("Rate Limit Triggered | " + m_auth.StatusSummary(), "EAP");
            else
               m_logger.Warning("Authentication Failed | " + r.auth_status, "EAP");
           }
        }

      m_gateway.ApplyHealth(r);
      r.developer_status = m_dev.Status();
      r.center_status = "API MANAGEMENT CENTER READY";
      r.insight = StringFormat("%s | Health=%.0f | %s",
                               r.center_status, r.api_health, GM_EAP_SAFE);
      r.may_execute = false;
      r.may_modify_risk = false;
      r.may_interrupt_trading = false;
      r.valid = true;

      const string keys_enc = m_sec.EncryptKey("clients-registered");
      const string audit = m_sec.TlsReadyBanner() + " | may_execute=false | " +
                           m_auth.ClientList();
      m_db.Record(r, m_auth.ClientList(), keys_enc, audit);
      m_last = r;
      m_cycle_us = GetMicrosecondCount() - t0;

      if(m_logger != NULL)
         m_logger.Debug(StringFormat("Performance Statistics | cycle=%I64u us (<1%%)",
                                     m_cycle_us), "EAP");
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = m_last.center_status;
      s.ai_engine = "GoldMind Enterprise API Gateway";
      s.current_mode = "CLOUD_API_GATEWAY";
      s.confidence_pct = m_last.api_health;
      s.confidence_status = StringFormat("%.0f", m_last.api_health);

      // Phase 6 Sprint 8 widgets
      s.w_trend_detector = m_last.api_status;                             // API Status
      s.future_ai_score = StringFormat("%.0f", m_last.api_health);        // API Health
      s.w_recovery_ai = IntegerToString(m_last.connected_clients);        // Connected Clients
      s.prediction_status = IntegerToString(m_last.request_count);        // API Requests
      s.learning_status = m_last.auth_status;                             // Auth Status
      s.w_volatility_scanner = m_last.rate_limit_status;                  // Rate Limits
      s.w_market_analyzer = m_last.webhook_status;                        // Webhook Status
      s.w_news_analyzer = m_last.api_version;                             // API Version
      s.w_trade_confidence = StringFormat("%.0f", m_last.integration_health); // Integration Health
      s.ai_version = m_last.developer_status;
      s.decision_status = GM_EAP_POLICY;
      s.valid = true;
     }
  };

#endif // GM_CENTERPRISE_API_GATEWAY_ENGINE_MQH
//+------------------------------------------------------------------+
