//+------------------------------------------------------------------+
//|                                       CSmartWarningEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     Informational warnings ONLY — never blocks Core Trading     |
//+------------------------------------------------------------------+
#ifndef GM_CSMART_WARNING_ENGINE_MQH
#define GM_CSMART_WARNING_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmAssistantResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../News/SGmNewsAnalysisResult.mqh"
#include "../Confidence/SGmConfidenceAnalysisResult.mqh"
#include "../Volatility/VolatilityAIConstants.mqh"

/// @brief Generates professional advisory warnings (non-blocking).
class CGmSmartWarningEngine
  {
private:
   void Add(SGmAssistantResult &r,
            const ENUM_GM_WARN_TYPE type,
            const string msg,
            const double severity)
     {
      if(r.warning_count >= GM_ASSIST_WARN_MAX)
         return;
      SGmAssistWarning w;
      w.Reset();
      w.type = type;
      w.message = msg;
      w.severity = GmAssistClamp(severity);
      w.active = true;
      r.warnings[r.warning_count++] = w;
     }

public:
   void Analyze(const SGmTrendAnalysisResult &trend,
                const SGmVolatilityAnalysisResult &vol,
                const SGmNewsAnalysisResult &news,
                const SGmConfidenceAnalysisResult &conf,
                SGmAssistantResult &r)
     {
      r.warning_count = 0;
      for(int i = 0; i < GM_ASSIST_WARN_MAX; i++)
         r.warnings[i].Reset();

      if(vol.valid && (vol.energy == GM_ENERGY_EXTREME || vol.energy_score >= 85.0 ||
                       vol.atr_expansion))
         Add(r, GM_WARN_HIGH_VOLATILITY,
             "High Volatility / ATR expansion observed",
             MathMax(vol.energy_score, 70.0));

      if(r.spread_points >= GM_ASSIST_SPREAD_WARN_PTS)
         Add(r, GM_WARN_ABNORMAL_SPREAD,
             StringFormat("Abnormal Spread | %.0f points", r.spread_points),
             GmAssistClamp(50.0 + r.spread_points * 0.5));

      if(trend.valid && trend.strength_score < 35.0)
         Add(r, GM_WARN_WEAK_TREND,
             StringFormat("Weak Trend | strength=%.0f", trend.strength_score),
             100.0 - trend.strength_score);

      if(r.current_dd_pct >= GM_ASSIST_DD_EXTREME_PCT ||
         r.daily_dd_pct >= GM_ASSIST_DD_EXTREME_PCT)
         Add(r, GM_WARN_EXTREME_DRAWDOWN,
             StringFormat("Extreme Drawdown | cur=%.1f%% day=%.1f%%",
                          r.current_dd_pct, r.daily_dd_pct),
             MathMin(100.0, r.current_dd_pct * 8.0));
      else if(r.current_dd_pct >= GM_ASSIST_DD_WARN_PCT)
         Add(r, GM_WARN_EXTREME_DRAWDOWN,
             StringFormat("Elevated Drawdown | cur=%.1f%%", r.current_dd_pct),
             r.current_dd_pct * 6.0);

      if(!r.terminal_connected)
         Add(r, GM_WARN_CONNECTION, "Connection Instability | terminal offline", 90.0);

      if(r.terminal_ping_ms >= GM_ASSIST_PING_WARN_MS)
         Add(r, GM_WARN_BROKER_DELAY,
             StringFormat("Broker Delay | ping=%d ms", r.terminal_ping_ms),
             GmAssistClamp((double)r.terminal_ping_ms / 3.0));

      // Soft gap heuristic: large candle vs ATR
      if(vol.valid && vol.atr14 > 0.0 && vol.avg_candle_range > vol.atr14 * 2.5)
         Add(r, GM_WARN_MARKET_GAP,
             "Market Gap / oversized candle vs ATR-14",
             75.0);

      if(news.valid && news.news_risk_score >= 65.0)
         Add(r, GM_WARN_NEWS_VOLATILITY,
             StringFormat("News Volatility | risk=%.0f", news.news_risk_score),
             news.news_risk_score);

      if(conf.valid && conf.overall_confidence < GM_ASSIST_CONF_LOW)
         Add(r, GM_WARN_LOW_CONFIDENCE,
             StringFormat("Low Confidence | %.0f%%", conf.overall_confidence),
             100.0 - conf.overall_confidence);

      if(r.recovery_active)
         Add(r, GM_WARN_RECOVERY_ACTIVE,
             "Recovery Activity Observed | " + r.recovery_status,
             55.0);

      if(r.margin_usage_pct >= GM_ASSIST_MARGIN_WARN_PCT)
         Add(r, GM_WARN_MARGIN_PRESSURE,
             StringFormat("Margin Pressure | usage=%.0f%%", r.margin_usage_pct),
             r.margin_usage_pct);

      if(r.system_health_score > 0.0 && r.system_health_score < 55.0)
         Add(r, GM_WARN_SYSTEM_HEALTH,
             StringFormat("System Health Soft Flag | %.0f", r.system_health_score),
             100.0 - r.system_health_score);

      if(r.warning_count <= 0)
        {
         r.warning_center = "None";
        }
      else
        {
         r.warning_center = "";
         const int show = MathMin(r.warning_count, 3);
         for(int i = 0; i < show; i++)
           {
            if(i > 0)
               r.warning_center += " | ";
            r.warning_center += GmWarnTypeName(r.warnings[i].type);
           }
         if(r.warning_count > 3)
            r.warning_center += StringFormat(" (+%d)", r.warning_count - 3);
        }
     }
  };

#endif // GM_CSMART_WARNING_ENGINE_MQH
//+------------------------------------------------------------------+
