//+------------------------------------------------------------------+
//|                                         CInstanceManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CINSTANCE_MANAGER_MQH
#define GM_CINSTANCE_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmInstanceRecord.mqh"
#include "CChartManager.mqh"
#include "CInstanceHealthMonitor.mqh"
#include "../Core/CFileManager.mqh"
#include "../Core/Version.mqh"
#include "../Logging/CLogger.mqh"

/// @file CInstanceManager.mqh
/// @brief Registers the local EA instance and publishes heartbeats (FILE_COMMON).
/// @warning Never synchronizes trading actions — monitoring heartbeat only.

class CGmInstanceManager
  {
private:
   CGmLogger                *m_logger;
   CGmFileManager           *m_files;
   CGmChartManager           m_chart;
   CGmInstanceHealthMonitor  m_health;
   SGmInstanceRecord         m_local;
   string                    m_hb_file;
   bool                      m_ready;

   string BuildInstanceId(const long chart_id, const long magic, const string symbol,
                          const datetime start) const
     {
      return StringFormat("GM-%I64d-%I64d-%s-%I64d", chart_id, magic, symbol, (long)start);
     }

   string HeartbeatFileName(void) const
     {
      return StringFormat("%s%I64d_%I64d.hb",
                          GM_INSTANCE_HB_PREFIX, m_local.magic, m_local.chart_id);
     }

public:
                     CGmInstanceManager(void)
                       : m_logger(NULL), m_files(NULL), m_hb_file(""), m_ready(false)
     {
      m_local.Reset();
     }

   bool Init(CGmLogger *logger,
             CGmFileManager *files,
             const string symbol,
             const ENUM_TIMEFRAMES tf,
             const long magic,
             const ulong session_id)
     {
      m_logger = logger;
      m_files = files;
      m_chart.Init(logger, symbol, tf);
      m_health.Init(logger);
      m_local.Reset();
      m_local.start_time = TimeCurrent();
      m_local.magic = magic;
      m_local.session_id = session_id;
      m_local.status = GM_INST_RUNNING;
      m_local.used = true;
      m_chart.ApplyToRecord(m_local);
      m_local.instance_id = BuildInstanceId(m_local.chart_id, magic, symbol, m_local.start_time);
      m_hb_file = HeartbeatFileName();
      m_ready = true;

      if(m_logger != NULL)
         m_logger.Success(StringFormat("Instance Started | id=%s | chart=%I64d | %s | magic=%I64d",
                                       m_local.instance_id, m_local.chart_id,
                                       symbol, magic),
                          "InstanceManager");
      PublishHeartbeat();
      return true;
     }

   void Shutdown(void)
     {
      if(!m_ready)
         return;
      m_local.status = GM_INST_CLOSED;
      m_local.heartbeat_at = TimeCurrent();
      PublishHeartbeat();
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Instance Closed | id=%s", m_local.instance_id),
                       "InstanceManager");
      m_chart.Shutdown();
      // Remove heartbeat so peers drop us quickly
      if(m_files != NULL && m_files.Exists(m_hb_file))
         m_files.WriteText(m_hb_file, "");
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmInstanceRecord Local(void) const { return m_local; }
   string InstanceId(void) const { return m_local.instance_id; }
   long ChartId(void) const { return m_local.chart_id; }
   string HeartbeatFile(void) const { return m_hb_file; }
   CGmChartManager *Chart(void) { return GetPointer(m_chart); }

   void UpdateRuntime(const ulong session_id,
                      const int open_trades,
                      const int pending_orders,
                      const double floating_profit,
                      const double floating_loss,
                      const double equity,
                      const double risk_pct,
                      const double drawdown_pct,
                      const string dashboard_status,
                      const string trading_status,
                      const string analytics_status,
                      const string recovery_status,
                      const bool trading_enabled,
                      const bool internet_ok,
                      const bool broker_connected)
     {
      if(!m_ready)
         return;
      m_chart.ApplyToRecord(m_local);
      m_local.session_id = session_id;
      m_local.open_trades = open_trades;
      m_local.pending_orders = pending_orders;
      m_local.floating_profit = floating_profit;
      m_local.floating_loss = floating_loss;
      m_local.equity = equity;
      m_local.risk_pct = risk_pct;
      m_local.drawdown_pct = drawdown_pct;
      m_local.dashboard_status = dashboard_status;
      m_local.trading_status = trading_status;
      m_local.analytics_status = analytics_status;
      m_local.recovery_status = recovery_status;
      m_local.trading_enabled = trading_enabled;
      m_local.internet_ok = internet_ok;
      m_local.broker_connected = broker_connected;
      m_local.memory_kb = (ulong)TerminalInfoInteger(TERMINAL_MEMORY_USED);
      m_local.cpu_est = 0.0;
      m_local.status = GM_INST_RUNNING;
      m_local.heartbeat_at = TimeCurrent();
      m_health.Evaluate(m_local);
     }

   bool PublishHeartbeat(void)
     {
      if(!m_ready || m_files == NULL)
         return false;
      m_local.heartbeat_at = TimeCurrent();
      const string body = "#GM_INSTANCE_HEARTBEAT\r\n" + m_local.Serialize() + "\r\n";
      return m_files.WriteText(m_hb_file, body);
     }
  };

#endif // GM_CINSTANCE_MANAGER_MQH
//+------------------------------------------------------------------+
