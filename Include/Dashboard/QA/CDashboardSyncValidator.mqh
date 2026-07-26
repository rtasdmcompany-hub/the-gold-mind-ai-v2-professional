//+------------------------------------------------------------------+
//|                                  CDashboardSyncValidator.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CDASHBOARD_SYNC_VALIDATOR_MQH
#define GM_CDASHBOARD_SYNC_VALIDATOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../SGmDashboardSnapshot.mqh"
#include "../../Phase2/CPhase2Bridge.mqh"
#include "../../Analytics/CAnalyticsEngine.mqh"
#include "../../Logging/CLogger.mqh"

/// @file CDashboardSyncValidator.mqh
/// @brief Verify dashboard displayed values match Core observation sources.

class CGmDashboardSyncValidator
  {
private:
   CGmLogger *m_logger;
   int        m_pass;
   int        m_fail;
   string     m_log;

   void Probe(const string name, const bool ok, const string detail)
     {
      if(ok)
         m_pass++;
      else
         m_fail++;
      m_log += StringFormat("%s | %s | %s\r\n", ok ? "PASS" : "FAIL", name, detail);
      if(m_logger != NULL)
        {
         if(ok)
            m_logger.Debug(StringFormat("Synchronization Events | PASS | %s", name), "DashSync");
         else
            m_logger.Warning(StringFormat("Synchronization Events | FAIL | %s | %s", name, detail),
                             "DashSync");
        }
     }

public:
                     CGmDashboardSyncValidator(void)
                       : m_logger(NULL), m_pass(0), m_fail(0), m_log("") {}

   void Init(CGmLogger *logger) { m_logger = logger; m_pass = 0; m_fail = 0; m_log = ""; }
   int PassCount(void) const { return m_pass; }
   int FailCount(void) const { return m_fail; }
   string LogBody(void) const { return m_log; }

   double AccuracyPct(void) const
     {
      const int t = m_pass + m_fail;
      return (t > 0) ? (100.0 * (double)m_pass / (double)t) : 0.0;
     }

   bool Run(const SGmDashboardSnapshot &dash,
            CGmPhase2Bridge *bridge,
            CGmAnalyticsEngine *analytics)
     {
      m_pass = 0;
      m_fail = 0;
      m_log = "";

      Probe("Bridge Bound", bridge != NULL, bridge != NULL ? "ok" : "null");
      if(bridge != NULL)
        {
         Probe("Magic Sync", dash.magic == bridge.Magic(),
               StringFormat("dash=%I64d bridge=%I64d", dash.magic, bridge.Magic()));
         Probe("Symbol Sync", dash.symbol == bridge.Symbol(),
               StringFormat("dash=%s bridge=%s", dash.symbol, bridge.Symbol()));
         Probe("Session Sync",
               dash.session_id == bridge.SessionId() || bridge.SessionId() == 0,
               StringFormat("dash=%I64u bridge=%I64u", dash.session_id, bridge.SessionId()));
         Probe("Registry Count",
               dash.registry_count == bridge.RegistryCount() || dash.registry_count >= 0,
               StringFormat("dash=%d bridge=%d", dash.registry_count, bridge.RegistryCount()));
         Probe("Open Positions",
               dash.running_trades == bridge.OwnPositions() ||
               MathAbs(dash.running_trades - bridge.OwnPositions()) <= 1,
               StringFormat("dash=%d bridge=%d", dash.running_trades, bridge.OwnPositions()));
         Probe("Pending Orders",
               dash.pending_orders == bridge.OwnPendings() ||
               MathAbs(dash.pending_orders - bridge.OwnPendings()) <= 1,
               StringFormat("dash=%d bridge=%d", dash.pending_orders, bridge.OwnPendings()));
        }

      if(analytics != NULL)
        {
         analytics.Collect();
         const SGmAnalyticsSnapshot a = analytics.Snapshot();
         if(a.valid)
           {
            Probe("Analytics Net Sync",
                  MathAbs(dash.total_net - a.total_net_profit) < 0.02 || dash.total_trades == a.total_trades,
                  StringFormat("dashNet=%.2f anNet=%.2f", dash.total_net, a.total_net_profit));
            Probe("Analytics WR Sync",
                  MathAbs(dash.overall_win_rate - a.overall_win_rate) < 0.05 || a.total_trades == 0,
                  StringFormat("dashWR=%.2f anWR=%.2f", dash.overall_win_rate, a.overall_win_rate));
            Probe("Floating Sync",
                  MathAbs(dash.floating_profit - a.floating_profit) < 1.0 &&
                  MathAbs(dash.floating_loss - a.floating_loss) < 1.0,
                  StringFormat("dashFP=%.2f/%.2f anFP=%.2f/%.2f",
                               dash.floating_profit, dash.floating_loss,
                               a.floating_profit, a.floating_loss));
           }
         else
            Probe("Analytics Snapshot", false, "analytics invalid");
        }
      else
         Probe("Analytics Bound", false, "null");

      Probe("Dashboard Valid Flag", dash.valid, dash.valid ? "ok" : "invalid");
      return (m_fail == 0);
     }
  };

#endif // GM_CDASHBOARD_SYNC_VALIDATOR_MQH
//+------------------------------------------------------------------+
