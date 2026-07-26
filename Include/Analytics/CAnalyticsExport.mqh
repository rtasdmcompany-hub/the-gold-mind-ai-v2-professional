//+------------------------------------------------------------------+
//|                                      CAnalyticsExport.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CANALYTICS_EXPORT_MQH
#define GM_CANALYTICS_EXPORT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "AnalyticsConstants.mqh"
#include "SGmAnalyticsSnapshot.mqh"
#include "../Logging/CLogger.mqh"

/// @file CAnalyticsExport.mqh
/// @brief Export infrastructure only — CSV/JSON/DB/Cloud/Mobile/Web stubs.
/// @warning Sprint 3 does NOT perform live export.

class CGmAnalyticsExport
  {
private:
   CGmLogger *m_logger;
   bool       m_ready;

public:
                     CGmAnalyticsExport(void) : m_logger(NULL), m_ready(false) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Analytics Export infrastructure ready (stubs; no export yet)",
                       "AnalyticsExport");
     }

   bool IsReady(void) const { return m_ready; }

   /// @brief Build CSV payload string (not written to disk in Sprint 3).
   string BuildCsv(const SGmAnalyticsSnapshot &s) const
     {
      return StringFormat(
                "timestamp,magic,symbol,total_trades,net_profit,win_rate,profit_factor,recovery_factor,dd\r\n"
                "%s,%I64d,%s,%d,%.2f,%.2f,%.2f,%.2f,%.2f\r\n",
                TimeToString(s.stamped_at, TIME_DATE | TIME_SECONDS),
                s.magic, s.symbol, s.total_trades, s.total_net_profit,
                s.overall_win_rate, s.profit_factor, s.recovery_factor, s.current_dd_pct);
     }

   /// @brief Build JSON payload string (not uploaded in Sprint 3).
   string BuildJson(const SGmAnalyticsSnapshot &s) const
     {
      return StringFormat(
                "{\"ts\":%I64d,\"magic\":%I64d,\"symbol\":\"%s\",\"total\":%d,"
                "\"net\":%.2f,\"wr\":%.2f,\"pf\":%.2f,\"rf\":%.2f,\"dd\":%.2f,"
                "\"equity\":%.2f,\"balance\":%.2f}",
                (long)s.stamped_at, s.magic, s.symbol, s.total_trades,
                s.total_net_profit, s.overall_win_rate, s.profit_factor,
                s.recovery_factor, s.current_dd_pct, s.equity, s.balance);
     }

   /// @brief Future targets — returns false until a later sprint enables export.
   bool Export(const ENUM_GM_EXPORT_TARGET target, const SGmAnalyticsSnapshot &s)
     {
      if(!m_ready)
         return false;
      // Infrastructure only — intentionally no file/network side effects
      if(m_logger != NULL)
         m_logger.Debug(StringFormat("Export stub | target=%d | bytes~%d (not sent)",
                                     (int)target,
                                     StringLen(BuildJson(s))),
                        "AnalyticsExport");
      return false;
     }

   bool PrepareCsv(const SGmAnalyticsSnapshot &s, string &out) const
     {
      out = BuildCsv(s);
      return (StringLen(out) > 0);
     }

   bool PrepareJson(const SGmAnalyticsSnapshot &s, string &out) const
     {
      out = BuildJson(s);
      return (StringLen(out) > 0);
     }

   bool PrepareDatabase(const SGmAnalyticsSnapshot &s, string &out) const
     {
      out = BuildJson(s); // placeholder row payload
      return true;
     }

   bool PrepareCloudApi(const SGmAnalyticsSnapshot &s, string &out) const
     {
      out = BuildJson(s);
      return true;
     }

   bool PrepareMobile(const SGmAnalyticsSnapshot &s, string &out) const
     {
      out = BuildJson(s);
      return true;
     }

   bool PrepareWeb(const SGmAnalyticsSnapshot &s, string &out) const
     {
      out = BuildJson(s);
      return true;
     }
  };

#endif // GM_CANALYTICS_EXPORT_MQH
//+------------------------------------------------------------------+
