//+------------------------------------------------------------------+
//|                                       IPhase2Interfaces.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_IPHASE2_INTERFACES_MQH
#define GM_IPHASE2_INTERFACES_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file IPhase2Interfaces.mqh
/// @brief Clean Phase 2 extension contracts — AI must layer on Core, not replace it.
/// @warning Implementations belong to Phase 2+. Phase 1 ships stubs only.

/// Advisory-only market analysis (never places orders).
interface IGmAIMarketAnalysis
  {
   bool Analyze(void);
   double Confidence(void);
   string LastInsight(void);
  };

/// Scores candidate levels / setups (advisory).
interface IGmAITradeScoring
  {
   bool ScoreLevel(const string level_tag, double &score_out);
   bool ScoreTrade(const ulong trade_id, double &score_out);
  };

/// Decision advisory — Core may ignore; AI never overrides Magic ownership.
interface IGmAIDecisionEngine
  {
   bool ShouldAllowNewPending(const string level_tag);
   bool ShouldAllowManagement(const ulong ticket);
   string LastDecisionReason(void);
  };

/// Capital protection AI (advisory layer above Sprint 6 protection).
interface IGmCapitalProtectionAI
  {
   bool EvaluateRisk(void);
   bool RecommendPauseEntries(void);
  };

/// Future hedge engine (not implemented in Phase 1).
interface IGmHedgeEngine
  {
   bool EvaluateHedgeNeed(void);
   bool IsHedgeActive(void);
  };

/// Analytics / dashboard data provider (read-only).
interface IGmAnalyticsEngine
  {
   bool Collect(void);
   string SnapshotJson(void);
  };

/// Cloud sync (future).
interface IGmCloudSync
  {
   bool SyncOut(void);
   bool SyncIn(void);
  };

//--- Phase 3 reserved extension points (implement in new modules only)

interface IGmAINewsAnalyzer
  {
   bool AnalyzeNews(void);
   double ImpactScore(void);
   string LastHeadline(void);
  };

interface IGmAIConfidenceMeter
  {
   double Confidence(void);
   string ConfidenceBand(void);
  };

interface IGmAIPredictionEngine
  {
   bool Predict(void);
   double BiasScore(void);
   string PredictionSummary(void);
  };

interface IGmAIRecoveryEngine
  {
   bool EvaluateRecovery(void);
   bool RecommendRecoveryAction(void);
  };

interface IGmRestApi
  {
   bool PublishObservation(const string json_payload);
   bool PollAdvice(string &out_json);
  };

interface IGmCloudAI
  {
   bool Connect(void);
   bool Infer(const string payload, string &out_response);
  };

interface IGmGPTIntegration
  {
   bool Ask(const string prompt, string &out_answer);
  };

interface IGmPythonBridge
  {
   bool CallService(const string service, const string payload, string &out_response);
  };

#endif // GM_IPHASE2_INTERFACES_MQH
//+------------------------------------------------------------------+
