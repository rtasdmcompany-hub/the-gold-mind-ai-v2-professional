//+------------------------------------------------------------------+
//|                                  CPerformanceGauges.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CPERFORMANCE_GAUGES_MQH
#define GM_CPERFORMANCE_GAUGES_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "EnumsDashboard.mqh"

/// @file CPerformanceGauges.mqh
/// @brief Text/bar gauges for risk, DD, WR, PF, RF, speed, connection, health.

class CGmPerformanceGauges
  {
public:
   /// @brief Clamp 0..100 and render a compact bar.
   static string Bar(const double pct0_100, const int width = 10)
     {
      double p = pct0_100;
      if(p < 0.0) p = 0.0;
      if(p > 100.0) p = 100.0;
      const int filled = (int)MathRound(p / 100.0 * width);
      string s = "[";
      for(int i = 0; i < width; i++)
         s += (i < filled) ? "#" : "-";
      s += StringFormat("] %.0f%%", p);
      return s;
     }

   static double RiskGauge(const double current_risk_pct, const double max_ref = 10.0)
     {
      if(max_ref <= 0.0)
         return 0.0;
      return MathMin(100.0, current_risk_pct / max_ref * 100.0);
     }

   static double DrawdownGauge(const double dd_pct, const double warn = 10.0)
     {
      if(warn <= 0.0)
         return 0.0;
      return MathMin(100.0, dd_pct / warn * 100.0);
     }

   static double WinRateGauge(const double wr) { return MathMax(0.0, MathMin(100.0, wr)); }

   static double ProfitFactorGauge(const double pf)
     {
      // Map 0..3 PF onto 0..100 (3+ = full)
      return MathMin(100.0, MathMax(0.0, pf / 3.0 * 100.0));
     }

   static double RecoveryFactorGauge(const double rf)
     {
      return MathMin(100.0, MathMax(0.0, rf / 3.0 * 100.0));
     }

   static double ExecutionSpeedGauge(const ulong collect_us)
     {
      // Faster = higher gauge. 0us=100, 250000us=0
      if(collect_us == 0)
         return 100.0;
      const double score = 100.0 - ((double)collect_us / 250000.0 * 100.0);
      return MathMax(0.0, MathMin(100.0, score));
     }

   static double ConnectionGauge(const bool connected, const bool trade_allowed)
     {
      if(!connected)
         return 0.0;
      if(!trade_allowed)
         return 50.0;
      return 100.0;
     }

   static double SystemHealthGauge(const string health)
     {
      string h = health;
      StringToUpper(h);
      if(StringFind(h, "OK") >= 0)
         return 100.0;
      if(StringFind(h, "WARN") >= 0)
         return 60.0;
      if(StringFind(h, "SLOW") >= 0)
         return 40.0;
      return 25.0;
     }

   static ENUM_GM_NOTIFY_SEVERITY SeverityFromGauge(const double pct, const bool invert = false)
     {
      double p = invert ? (100.0 - pct) : pct;
      if(p >= 70.0)
         return GM_SEV_OK;
      if(p >= 40.0)
         return GM_SEV_WARN;
      return GM_SEV_ERROR;
     }
  };

#endif // GM_CPERFORMANCE_GAUGES_MQH
//+------------------------------------------------------------------+
