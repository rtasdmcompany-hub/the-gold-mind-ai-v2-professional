//+------------------------------------------------------------------+
//|                         CEnterpriseCommandCenterEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 7 Sprint 9 — Command Center / Ops Room / Executive    |
//|     MONITORING ONLY — NEVER interferes with trading             |
//+------------------------------------------------------------------+
#ifndef GM_CENTERPRISE_COMMAND_CENTER_ENGINE_MQH
#define GM_CENTERPRISE_COMMAND_CENTER_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CommandCenterConstants.mqh"
#include "SGmCommandCenterResult.mqh"
#include "CEocEnterpriseCommandCenter.mqh"
#include "CEocLiveOperationsRoom.mqh"
#include "CEocRealtimePerformanceWall.mqh"
#include "CEocGlobalAlertCenter.mqh"
#include "CEocExecutiveOverview.mqh"
#include "CEocSecurityLayer.mqh"
#include "CEocTaskQueue.mqh"
#include "CEocExportCenter.mqh"
#include "CEocOperationsDatabase.mqh"
#include "../PortfolioAnalytics/CEnterprisePortfolioAnalyticsEngine.mqh"
#include "../MultiAccountCenter/CEnterpriseMultiAccountCenterEngine.mqh"
#include "../AIDecisionCenter/CEnterpriseAIDecisionCenterEngine.mqh"
#include "../Cloud/Identity/CEnterpriseIdentityEngine.mqh"
#include "../Cloud/Infrastructure/CEnterpriseInfrastructureEngine.mqh"
#include "../Cloud/ApiGateway/CEnterpriseApiGatewayEngine.mqh"
#include "../Cloud/Backup/CEnterpriseBackupEngine.mqh"
#include "../Cloud/Notifications/CEnterpriseNotificationEngine.mqh"
#include "../Cloud/CEnterpriseCloudEngine.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"
#include "../AI/SGmAISnapshot.mqh"

class CGmEnterpriseCommandCenterEngine
  {
private:
   CGmLogger                             *m_logger;
   CGmEnterprisePortfolioAnalyticsEngine *m_epa;
   CGmEnterpriseMultiAccountCenterEngine *m_mac;
   CGmEnterpriseAIDecisionCenterEngine   *m_adc;
   CGmEnterpriseIdentityEngine           *m_identity;
   CGmEnterpriseInfrastructureEngine     *m_infra;
   CGmEnterpriseApiGatewayEngine         *m_api;
   CGmEnterpriseBackupEngine             *m_backup;
   CGmEnterpriseNotificationEngine       *m_notify;
   CGmEnterpriseCloudEngine              *m_cloud;

   CGmEocEnterpriseCommandCenter          m_command;
   CGmEocLiveOperationsRoom               m_ops;
   CGmEocRealtimePerformanceWall          m_perf;
   CGmEocGlobalAlertCenter                m_alerts;
   CGmEocExecutiveOverview                m_exec;
   CGmEocSecurityLayer                    m_security;
   CGmEocTaskQueue                        m_queue;
   CGmEocExportCenter                     m_export;
   CGmEocOperationsDatabase               m_db;

   SGmCommandCenterResult                 m_last;
   int                                    m_open_ai_trades;
   int                                    m_pending_orders;
   bool                                   m_trading_ready;
   bool                                   m_ai_ready;
   ulong                                  m_last_ms;
   bool                                   m_ready;
   bool                                   m_exported;

   double ScoreOr(const bool ready, const double v, const double fallback) const
     {
      return ready ? v : fallback;
     }

public:
                     CGmEnterpriseCommandCenterEngine(void)
                       : m_logger(NULL), m_epa(NULL), m_mac(NULL), m_adc(NULL),
                         m_identity(NULL), m_infra(NULL), m_api(NULL), m_backup(NULL),
                         m_notify(NULL), m_cloud(NULL),
                         m_open_ai_trades(0), m_pending_orders(0),
                         m_trading_ready(true), m_ai_ready(false),
                         m_last_ms(0), m_ready(false), m_exported(false)
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
      m_command.Init(logger);
      m_ops.Init(logger);
      m_perf.Init(logger);
      m_alerts.Init(logger);
      m_exec.Init(logger);
      m_security.Init(logger);
      m_queue.Reset();
      m_export.Init(logger, files, m_db.Prefix());
      m_last.Reset();
      m_ready = true;
      m_exported = false;
      if(m_logger != NULL)
        {
         m_logger.Success("Command Center Started | " + GM_EOC_VERSION, "EOC");
         m_logger.Info("POLICY | " + GM_EOC_POLICY, "EOC");
         m_logger.Info("SAFE | " + GM_EOC_SAFE, "EOC");
        }
      return true;
     }

   void BindPortfolio(CGmEnterprisePortfolioAnalyticsEngine *epa) { m_epa = epa; }
   void BindMultiAccount(CGmEnterpriseMultiAccountCenterEngine *mac) { m_mac = mac; }
   void BindAIDecision(CGmEnterpriseAIDecisionCenterEngine *adc) { m_adc = adc; }
   void BindIdentity(CGmEnterpriseIdentityEngine *identity) { m_identity = identity; }
   void BindInfrastructure(CGmEnterpriseInfrastructureEngine *infra) { m_infra = infra; }
   void BindApi(CGmEnterpriseApiGatewayEngine *api) { m_api = api; }
   void BindBackup(CGmEnterpriseBackupEngine *backup) { m_backup = backup; }
   void BindNotify(CGmEnterpriseNotificationEngine *notify) { m_notify = notify; }
   void BindCloud(CGmEnterpriseCloudEngine *cloud) { m_cloud = cloud; }

   void SetLiveOps(const int open_ai_trades, const int pending_orders,
                   const bool trading_ready, const bool ai_ready)
     {
      m_open_ai_trades = (open_ai_trades < 0 ? 0 : open_ai_trades);
      m_pending_orders = (pending_orders < 0 ? 0 : pending_orders);
      m_trading_ready = trading_ready;
      m_ai_ready = ai_ready;
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmCommandCenterResult Last(void) const { return m_last; }
   bool MayInterruptTrading(void) const { return false; }
   bool MayRemoteCommand(void) const { return false; }

   bool Process(const bool force = false)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(!force && m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_EOC_THROTTLE_MS)
         return true;
      m_last_ms = now;

      if(!force && m_queue.PreferCache((ulong)GM_EOC_THROTTLE_MS) && m_last.valid)
        {
         m_last.queue_status = GM_EOC_Q_CACHED;
         m_last.open_ai_trades = m_open_ai_trades;
         m_last.pending_orders = m_pending_orders;
         return true;
        }

      m_queue.MarkRunning();

      double cloud_score = 70.0;
      double infra_score = 70.0;
      double license_health = 75.0;
      double api_health = 70.0;
      double backup_score = 70.0;
      double notify_ok = 80.0;
      double mac_health = 70.0;
      double adc_conf = 70.0;
      int licensed = 1;
      int connected = TerminalInfoInteger(TERMINAL_CONNECTED) ? 1 : 0;
      string sync_status = "Local";

      if(m_cloud != NULL && m_cloud.IsReady() && m_cloud.Last().valid)
        {
         // cloud overall via status presence
         cloud_score = 75.0;
         sync_status = "Cloud Sync Observe";
        }
      if(m_infra != NULL && m_infra.IsReady() && m_infra.Last().valid)
         infra_score = m_infra.Last().enterprise_score;
      if(m_identity != NULL && m_identity.IsReady() && m_identity.Last().valid)
         license_health = m_identity.Last().license_health;
      if(m_api != NULL && m_api.IsReady() && m_api.Last().valid)
         api_health = m_api.Last().api_health;
      if(m_backup != NULL && m_backup.IsReady() && m_backup.Last().valid)
         backup_score = m_backup.Last().business_continuity;
      if(m_notify != NULL && m_notify.IsReady() && m_notify.Last().valid)
         notify_ok = (m_notify.Last().critical_count == 0 ? 90.0 : 55.0);
      if(m_mac != NULL && m_mac.IsReady() && m_mac.Last().valid)
        {
         mac_health = m_mac.Last().enterprise_health;
         licensed = m_mac.Last().accounts_licensed;
         connected = MathMax(connected, m_mac.Last().connected_count);
        }
      if(m_adc != NULL && m_adc.IsReady() && m_adc.Last().valid)
         adc_conf = m_adc.Last().decision_confidence;

      SGmPortfolioAnalyticsResult epa;
      epa.Reset();
      if(m_epa != NULL && m_epa.IsReady() && m_epa.Last().valid)
         epa = m_epa.Last();

      SGmCommandCenterResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();

      m_command.Build(cloud_score, infra_score, license_health, api_health, backup_score,
                      notify_ok, mac_health, adc_conf, m_trading_ready, m_ai_ready, r);
      m_ops.Build(m_open_ai_trades, m_pending_orders, licensed, connected,
                  mac_health, sync_status, r);
      m_perf.Build(cloud_score, api_health, r);
      m_alerts.Evaluate(license_health, infra_score, r.overall_performance,
                        (bool)TerminalInfoInteger(TERMINAL_CONNECTED), r);
      m_exec.Generate(epa, r);
      m_security.ApplyToResult(r);

      r.may_execute = false;
      r.may_modify_risk = false;
      r.may_interrupt_trading = false;
      r.may_remote_command = false;
      r.center_status = "ENTERPRISE COMMAND CENTER — MONITOR-ONLY";
      r.insight = StringFormat(
         "Enterprise=%.0f Perf=%.0f Avail=%.0f | Open=%d Pending=%d Alerts=%d | RemoteCmd=DENIED",
         r.enterprise_health, r.overall_performance, r.system_availability,
         r.open_ai_trades, r.pending_orders, r.alert_count);
      r.valid = true;

      if(!m_exported || force)
        {
         m_export.Export(r);
         m_exported = true;
         m_queue.MarkExported();
        }
      else
         m_queue.MarkCached();

      r.export_status = m_export.Status();
      r.queue_status = m_queue.Status();

      m_last = r;
      m_db.Persist(r);
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = "Enterprise Command Center";
      s.ai_engine = "GoldMind Live Operations & Executive Monitor";
      s.current_mode = "EOC_MONITOR_ONLY";
      s.confidence_pct = m_last.enterprise_health;
      s.confidence_status = StringFormat("%.0f", m_last.system_availability);

      s.w_trend_detector = StringFormat("Ops Open=%d", m_last.open_ai_trades);
      s.future_ai_score = StringFormat("Infra %.0f", m_last.infrastructure_health);
      s.w_recovery_ai = StringFormat("AI Open=%d Pend=%d", m_last.open_ai_trades, m_last.pending_orders);
      s.prediction_status = m_last.ai_engine_status;
      s.learning_status = m_last.cloud_status;
      s.w_volatility_scanner = StringFormat("%.0f", m_last.enterprise_health);
      s.w_market_analyzer = StringFormat("C=%d W=%d", m_last.critical_alerts, m_last.warning_alerts);
      s.w_news_analyzer = StringFormat("Avail %.0f%%", m_last.system_availability);
      s.w_trade_confidence = StringFormat("Perf %.0f", m_last.overall_performance);
      s.ai_version = StringFormat("EH=%.0f Perf=%.0f",
                                  m_last.enterprise_health, m_last.overall_performance);
      s.decision_status = "MONITOR-ONLY — NO REMOTE COMMANDS — CORE AUTHORITY";
      s.valid = true;
     }
  };

#endif // GM_CENTERPRISE_COMMAND_CENTER_ENGINE_MQH
//+------------------------------------------------------------------+
