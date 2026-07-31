//+------------------------------------------------------------------+
//|                               CEnterpriseCloudEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 6 Sprint 1 — Cloud facade (background only)           |
//+------------------------------------------------------------------+
#ifndef GM_CENTERPRISE_CLOUD_ENGINE_MQH
#define GM_CENTERPRISE_CLOUD_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CloudConstants.mqh"
#include "SGmCloudStatus.mqh"
#include "CCloudSecurity.mqh"
#include "CDeviceIdentityEngine.mqh"
#include "CLicenseSessionEngine.mqh"
#include "CRemoteSyncEngine.mqh"
#include "CCloudOfflineMode.mqh"
#include "CCloudDatabase.mqh"
#include "../Core/Version.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"
#include "../AI/SGmAISnapshot.mqh"

class CGmEnterpriseCloudEngine
  {
private:
   CGmLogger               *m_logger;
   CGmCloudSecurity         m_sec;
   CGmDeviceIdentityEngine  m_device;
   CGmLicenseSessionEngine  m_license;
   CGmRemoteSyncEngine      m_sync;
   CGmCloudOfflineMode      m_offline;
   CGmCloudDatabase         m_db;
   SGmCloudStatus           m_last;
   string                   m_endpoint;
   ulong                    m_last_ms;
   ulong                    m_last_hb_ms;
   bool                     m_ready;
   bool                     m_was_offline;

   bool TerminalHasNetwork(void) const
     {
      // Soft probe — never blocks trading. Prefer offline-safe default.
      if(!TerminalInfoInteger(TERMINAL_CONNECTED))
         return false;
      // Sprint 1: no remote HTTP yet — treat as "discoverable local cloud stub"
      return true;
     }

   void DiscoverServer(void)
     {
      // Architecture discovery stub (no live payment/cloud API in Sprint 1)
      m_endpoint = "https://cloud.rtas.group/goldmind/v1 (reserved)";
     }

public:
                     CGmEnterpriseCloudEngine(void)
                       : m_logger(NULL), m_endpoint(""), m_last_ms(0),
                         m_last_hb_ms(0), m_ready(false), m_was_offline(true)
     {
      m_last.Reset();
     }

   bool Init(CGmLogger *logger,
             CGmFileManager *files,
             const long magic,
             const string symbol)
     {
      m_logger = logger;
      m_last.Reset();
      m_db.Init(logger, files, magic, symbol);

      const string seed = StringFormat("%I64d|%s|%s|%s",
                                       magic, symbol, GM_VERSION_STRING, GM_PRODUCT_CODE);
      if(!m_sec.Init(seed))
         return false;
      if(!m_device.Init(GetPointer(m_sec), magic, symbol))
         return false;
      if(!m_license.Init(GetPointer(m_sec), GetPointer(m_device)))
         return false;
      m_sync.Init(GetPointer(m_sec));
      m_offline.Enable(); // start offline-safe
      DiscoverServer();
      m_db.RecordDevice(m_device.EncryptedRecord());

      m_ready = true;
      if(m_logger != NULL)
        {
         m_logger.Success("Enterprise Cloud Core Started | " + GM_CLOUD_VERSION, "CLOUD");
         m_logger.Info("POLICY | " + GM_CLOUD_POLICY, "CLOUD");
         m_logger.Info("OFFLINE SAFE | " + GM_CLOUD_OFFLINE_SAFE, "CLOUD");
         m_logger.Info("Device Identity | " + m_device.Summary(), "CLOUD");
         m_logger.Info("License Session Started | " + m_license.StatusText(), "CLOUD");
         m_logger.Info("Offline Mode Enabled | trading unaffected", "CLOUD");
        }
      Process(true);
      return true;
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmCloudStatus Last(void) const { return m_last; }

   bool Process(const bool force = false)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(!force && m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_CLOUD_THROTTLE_MS)
         return true;
      m_last_ms = now;

      SGmCloudStatus s;
      s.Reset();
      s.stamped_at = TimeCurrent();
      s.may_execute = false;
      s.may_modify_risk = false;
      s.cloud_version = GM_CLOUD_VERSION;
      s.ea_version = StringFormat("%s build %d", GM_VERSION_STRING, GM_VERSION_BUILD);
      s.device_id_hash = m_device.CompositeHash();
      s.session_token_hash = m_license.TokenHash();
      s.license_tier = m_license.Tier();
      s.license_status = m_license.StatusText();
      s.server_endpoint = m_endpoint;
      s.sync_queue_depth = m_sync.QueueDepth();
      s.last_sync_at = m_sync.LastSyncAt();

      const bool net = TerminalHasNetwork();
      if(!net)
        {
         if(!m_offline.IsOffline())
           {
            m_offline.Enable();
            if(m_logger != NULL)
              {
               m_logger.Warning("Cloud Disconnected | entering offline mode", "CLOUD");
               m_logger.Info("Offline Mode Enabled | " + GM_CLOUD_OFFLINE_SAFE, "CLOUD");
              }
           }
         s.cloud_status = GM_CLOUD_STATUS_OFFLINE;
         s.offline_mode = true;
         s.server_connection = "Disconnected";
         s.heartbeat_ok = false;
         s.latency_ms = 0;
         s.center_status = "CLOUD OFFLINE — TRADING CONTINUES";
        }
      else
        {
         // Soft "online" local session — no remote authority over trading
         if(m_offline.IsOffline())
           {
            if(m_offline.ShouldRetry(now) || force)
              {
               m_offline.Disable();
               m_license.RefreshArchitectureSession();
               if(m_logger != NULL)
                 {
                  m_logger.Success("Cloud Connected | architecture session", "CLOUD");
                  m_logger.Info("Offline Mode Disabled", "CLOUD");
                 }
              }
           }

         if(m_offline.IsOffline())
           {
            s.cloud_status = GM_CLOUD_STATUS_OFFLINE;
            s.offline_mode = true;
            s.server_connection = "Retry Pending";
            s.center_status = "CLOUD OFFLINE — TRADING CONTINUES";
           }
         else
           {
            s.cloud_status = GM_CLOUD_STATUS_ONLINE;
            s.offline_mode = false;
            s.server_connection = "Connected";
            s.center_status = "CLOUD ONLINE — NO TRADING AUTHORITY";

            // Heartbeat (local stamp only in Sprint 1)
            if(m_last_hb_ms == 0 || (now - m_last_hb_ms) >= (ulong)GM_CLOUD_HEARTBEAT_MS || force)
              {
               m_last_hb_ms = now;
               s.heartbeat_ok = true;
               s.last_heartbeat_at = TimeCurrent();
               s.latency_ms = 1 + (int)(GetTickCount() % 12); // stub latency
               if(m_logger != NULL)
                 {
                  m_logger.Info("Heartbeat Sent", "CLOUD");
                  m_logger.Info(StringFormat("Heartbeat Received | latency~%dms", s.latency_ms), "CLOUD");
                 }
              }
            else
              {
               s.heartbeat_ok = m_last.heartbeat_ok;
               s.last_heartbeat_at = m_last.last_heartbeat_at;
               s.latency_ms = m_last.latency_ms;
              }

            // Drain at most 1 sync item per cycle (CPU budget)
            if(m_sync.ProcessOne(true))
              {
               s.last_sync_at = m_sync.LastSyncAt();
               s.sync_queue_depth = m_sync.QueueDepth();
               if(m_logger != NULL)
                  m_logger.Info("Synchronization Completed | " + m_sync.QueueSummary(), "CLOUD");
              }
            else
              {
               s.sync_queue_depth = m_sync.QueueDepth();
               s.last_sync_at = m_sync.LastSyncAt();
              }
           }
        }

      if(m_was_offline && !s.offline_mode && m_logger != NULL)
         m_logger.Info("Cloud recovery silent | trading uninterrupted", "CLOUD");
      m_was_offline = s.offline_mode;

      s.insight = StringFormat("%s | Lic=%s | SyncQ=%d | %s",
                               s.center_status, s.license_status,
                               s.sync_queue_depth, GM_CLOUD_POLICY);
      s.valid = true;
      m_last = s;
      m_db.Record(s, m_license.StatusText() + " | token=" + m_license.TokenHash());
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = m_last.center_status;
      s.ai_engine = "GoldMind Enterprise Cloud";
      s.current_mode = "CLOUD_FOUNDATION";
      s.confidence_pct = m_last.offline_mode ? 40.0 : 85.0;
      s.confidence_status = m_last.offline_mode ? "OFFLINE" : "ONLINE";

      // Phase 6 Sprint 1 cloud widgets (last-wins via PushSnapshot)
      s.w_trend_detector = GmCloudStatusName(m_last.cloud_status);              // Cloud Status
      s.future_ai_score = m_last.license_status;                                 // License Status
      s.w_recovery_ai = (m_last.last_sync_at > 0)
                        ? TimeToString(m_last.last_sync_at, TIME_MINUTES | TIME_SECONDS)
                        : "Never";                                               // Last Sync
      s.prediction_status = m_last.server_connection;                            // Server Connection
      s.learning_status = m_last.offline_mode ? "YES" : "NO";                    // Offline Mode
      s.w_volatility_scanner = StringFormat("%d ms", m_last.latency_ms);         // Latency
      s.w_market_analyzer = m_last.ea_version;                                   // Version
      s.w_news_analyzer = IntegerToString(m_last.sync_queue_depth);              // Sync Queue
      s.w_trade_confidence = m_last.heartbeat_ok ? "OK" : "—";                   // Heartbeat
      s.ai_version = m_last.insight;                                             // Summary
      s.decision_status = GM_CLOUD_POLICY;
      s.valid = true;
     }
  };

#endif // GM_CENTERPRISE_CLOUD_ENGINE_MQH
//+------------------------------------------------------------------+
