//+------------------------------------------------------------------+
//|                              CRealtimeDecisionMonitor.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CREALTIME_DECISION_MONITOR_MQH
#define GM_CREALTIME_DECISION_MONITOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmExecutionSupervisorResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../OrderFlow/SGmOrderFlowResult.mqh"
#include "../NewsIntelligence/SGmNewsIntelligenceResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"

class CGmRealtimeDecisionMonitor
  {
public:
   void Analyze(const SGmTrendAnalysisResult &trend,
                const SGmVolatilityAnalysisResult &vol,
                const SGmOrderFlowResult &of,
                const SGmNewsIntelligenceResult &ni,
                const SGmAssistantResult &sup,
                SGmExecutionSupervisorResult &r)
     {
      double trend_c = (trend.valid) ? trend.confidence : 50.0;
      double vol_c = (vol.valid) ? vol.confidence : 50.0;
      double energy = (of.valid) ? of.energy_stability : 50.0;
      double liq = (of.valid) ? of.session_liquidity : ((sup.valid) ? sup.liquidity_score : 50.0);
      double news = (ni.valid) ? (100.0 - ni.news_impact_score * 0.35) : ((sup.valid) ? (100.0 - MathMin(80.0, sup.news_environment)) : 60.0);
      double spread_pen = GmEsClamp(100.0 - r.spread_points * 1.5);

      r.decision_stability_score = GmEsClamp(
         0.30 * trend_c + 0.20 * energy + 0.20 * vol_c + 0.15 * liq + 0.15 * spread_pen);

      double env = (sup.valid) ? sup.environment_score : 55.0;
      r.environment_stability_score = GmEsClamp(
         0.35 * env + 0.20 * vol_c + 0.20 * liq + 0.15 * news + 0.10 * energy);

      string sess = (of.valid) ? GmOfSessionName(of.active_session) : "Session—";
      string trend_s = (trend.valid) ? StringFormat("TrendConf=%.0f", trend_c) : "Trend—";
      string vol_s = (vol.valid) ? StringFormat("VolConf=%.0f", vol_c) : "Vol—";
      string news_s = (ni.valid) ? StringFormat("NewsImpact=%.0f", ni.news_impact_score) : "News—";

      r.market_evolution_timeline = StringFormat(
         "%s | %s | %s | %s | Energy=%.0f Liq=%.0f Spread=%.1f",
         sess, trend_s, vol_s, news_s,
         (of.valid) ? of.energy_score : 0.0, liq, r.spread_points);

      r.decision_report = StringFormat("DecisionStability=%.0f | EnvStability=%.0f | %s",
                                       r.decision_stability_score,
                                       r.environment_stability_score,
                                       r.market_evolution_timeline);
      r.environment_report = r.decision_report;
     }
  };

#endif // GM_CREALTIME_DECISION_MONITOR_MQH
//+------------------------------------------------------------------+
