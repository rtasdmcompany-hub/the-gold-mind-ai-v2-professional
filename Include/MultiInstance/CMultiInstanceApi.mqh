//+------------------------------------------------------------------+
//|                                         CMultiInstanceApi.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CMULTI_INSTANCE_API_MQH
#define GM_CMULTI_INSTANCE_API_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "MultiInstanceConstants.mqh"
#include "SGmGlobalMonitorSnapshot.mqh"
#include "../Logging/CLogger.mqh"

/// @file CMultiInstanceApi.mqh
/// @brief Future central/cloud/mobile/web/AI supervisor stubs — no live export.

class CGmMultiInstanceApi
  {
private:
   CGmLogger *m_logger;
   bool       m_ready;

public:
                     CGmMultiInstanceApi(void) : m_logger(NULL), m_ready(false) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Success("Multi-Instance API ready | Central/Desktop/Cloud/Mobile/Web/AI/Remote stubs",
                          "MultiInstanceApi");
     }

   bool IsReady(void) const { return m_ready; }

   string TargetName(const ENUM_GM_MI_API_TARGET t) const
     {
      switch(t)
        {
         case GM_MI_API_DESKTOP:       return "DesktopControlCenter";
         case GM_MI_API_CLOUD:         return "CloudMonitoring";
         case GM_MI_API_MOBILE:        return "MobileApp";
         case GM_MI_API_WEB:           return "WebPortal";
         case GM_MI_API_AI_SUPERVISOR: return "AISupervisor";
         case GM_MI_API_REMOTE:        return "RemoteMonitoring";
         default:                      return "CentralDashboard";
        }
     }

   string BuildJson(const SGmGlobalMonitorSnapshot &s) const
     {
      return StringFormat(
                "{\"instances\":%d,\"symbols\":%d,\"open\":%d,\"pending\":%d,"
                "\"fp\":%.2f,\"fl\":%.2f,\"equity\":%.2f,\"risk\":%.2f,\"dd\":%.2f,"
                "\"ghealth\":%.1f,\"local\":\"%s\",\"chart\":%I64d}",
                s.total_instances, s.active_symbols, s.total_open_trades,
                s.total_pending_orders, s.overall_floating_profit, s.overall_floating_loss,
                s.overall_equity, s.overall_risk_pct, s.overall_drawdown_pct,
                s.global_health, s.local_instance_id, s.local_chart_id);
     }

   bool Prepare(const ENUM_GM_MI_API_TARGET target,
                const SGmGlobalMonitorSnapshot &s,
                string &out_payload) const
     {
      out_payload = "";
      if(!m_ready || !s.valid)
         return false;
      out_payload = BuildJson(s);
      return (StringLen(out_payload) > 0);
     }

   /// @brief Future publish — always false until a later sprint enables transport.
   bool Publish(const ENUM_GM_MI_API_TARGET target, const SGmGlobalMonitorSnapshot &s)
     {
      if(!m_ready)
         return false;
      string payload = "";
      Prepare(target, s, payload);
      if(m_logger != NULL)
         m_logger.Debug(StringFormat("API stub | target=%s | bytes=%d (not sent)",
                                     TargetName(target), StringLen(payload)),
                        "MultiInstanceApi");
      return false;
     }
  };

#endif // GM_CMULTI_INSTANCE_API_MQH
//+------------------------------------------------------------------+
