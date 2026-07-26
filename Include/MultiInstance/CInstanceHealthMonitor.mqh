//+------------------------------------------------------------------+
//|                                     CInstanceHealthMonitor.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CINSTANCE_HEALTH_MONITOR_MQH
#define GM_CINSTANCE_HEALTH_MONITOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmInstanceRecord.mqh"
#include "../Logging/CLogger.mqh"

/// @file CInstanceHealthMonitor.mqh
/// @brief Local instance health score (READ-ONLY probes).

class CGmInstanceHealthMonitor
  {
private:
   CGmLogger *m_logger;
   double     m_last_score;

public:
                     CGmInstanceHealthMonitor(void) : m_logger(NULL), m_last_score(0.0) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_last_score = 0.0;
     }

   double LastScore(void) const { return m_last_score; }

   /// @brief Compute 0..100 health from local runtime flags.
   double Evaluate(SGmInstanceRecord &rec)
     {
      double score = 0.0;
      if(rec.status == GM_INST_RUNNING)
         score += 20.0;
      if(rec.chart_active)
         score += 10.0;
      if(rec.trading_enabled)
         score += 15.0;
      if(rec.internet_ok)
         score += 10.0;
      if(rec.broker_connected)
         score += 15.0;
      if(rec.dashboard_status == "OK" || rec.dashboard_status == "RUNNING")
         score += 10.0;
      if(rec.analytics_status == "OK")
         score += 10.0;
      if(rec.recovery_status == "READY" || rec.recovery_status == "OK" ||
         rec.recovery_status == "N/A")
         score += 10.0;

      rec.health_score = MathMin(100.0, score);
      m_last_score = rec.health_score;

      if(m_logger != NULL)
         m_logger.Debug(StringFormat("Health Updates | score=%.0f | %s",
                                     m_last_score, rec.instance_id),
                        "InstanceHealth");
      return m_last_score;
     }
  };

#endif // GM_CINSTANCE_HEALTH_MONITOR_MQH
//+------------------------------------------------------------------+
